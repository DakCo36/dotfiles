#!/usr/bin/env ruby
# CLI 인터페이스 - install, update, check 명령어 지원
#
# 사용법:
#   ruby bin/cli.rb install [--yes] [component...]  # 컴포넌트 설치
#   ruby bin/cli.rb update [--yes] [component...]   # 설치된 컴포넌트 업데이트
#   ruby bin/cli.rb check                           # 업데이트 가능 목록 표시
#   ruby bin/cli.rb help                            # 도움말 표시

require_relative "bin_helper"
require "optparse"
require "mixins/loggable"

require "components/shell/zsh_binary"
require "components/shell/oh_my_zsh"
require "components/shell/powerlevel10k"
require "components/shell/zgenom"
require "components/utils/bat"
require "components/utils/fastfetch"
require "components/utils/fd"
require "components/utils/ripgrep"
require "components/utils/fzf"

require "cli/registry"
require "cli/dependency_resolver"

module CLI
  class Runner

    include Loggable

    def initialize
      @registry = Registry.instance
      @auto_yes = false
      @dry_run = false
    end

    def run(args)
      command = args.shift || "help"

      case command
      when "install"
        install_command(args)
      when "update"
        update_command(args)
      when "check"
        check_command(args)
      when "help", "-h", "--help"
        help_command
      else
        logger.error("알 수 없는 명령어: #{command}")
        help_command
        exit 1
      end
    end

    private

    def install_command(args)
      parse_options!(args)

      requested_components = if args.empty?
                               @registry.not_installed
                             else
                               @registry.find_all(args).reject(&:installed?)
                             end

      if requested_components.empty?
        logger.info("설치할 컴포넌트가 없습니다. 모든 컴포넌트가 이미 설치되어 있습니다.")
        return
      end

      resolver = DependencyResolver.new
      begin
        install_plan = resolver.resolve(requested_components)
      rescue DependencyResolver::CircularDependencyError => e
        logger.error("의존성 오류: #{e.message}")
        return
      end

      if install_plan.empty?
        logger.info("설치할 컴포넌트가 없습니다. 모든 컴포넌트가 이미 설치되어 있습니다.")
        return
      end

      show_install_plan(install_plan, requested_components)

      if @dry_run
        logger.info("(dry-run 모드: 실제 설치는 수행되지 않았습니다)")
        return
      end

      unless @auto_yes
        print "계속 하시겠습니까? [Y/n] "
        response = $stdin.gets&.strip&.downcase
        unless response.nil? || response.empty? || response == "y" || response == "yes"
          logger.info("설치가 취소되었습니다.")
          return
        end
      end

      install_plan.each do |component|
        logger.info(">>> #{component.display_name} 설치 중...")
        begin
          component.install
          logger.info(">>> #{component.display_name} 설치 완료")
        rescue StandardError => e
          logger.error(">>> #{component.display_name} 설치 실패: #{e.message}")
          logger.error("설치가 중단되었습니다.")
          return
        end
      end

      logger.info("설치가 완료되었습니다.")
    end

    # Show the install plan to the user
    #
    # @param install_plan [Array<Component::BaseComponent>] an array of components to install (in order)
    # @param requested [Array<Component::BaseComponent>] an array of components requested by the user
    def show_install_plan(install_plan, requested)
      requested_classes = requested.map(&:class)

      logger.info("설치 계획:")
      install_plan.each_with_index do |component, idx|
        deps = component.dependencies.keys
        dep_info = deps.empty? ? "(의존성 없음)" : "(← #{deps.join(", ")})"

        marker = requested_classes.include?(component.class) ? "" : "[의존성] "

        latest = begin
          component.latest_version
        rescue StandardError
          nil
        end
        version_info = latest ? " v#{latest}" : ""

        logger.info("  #{idx + 1}. #{marker}#{component.display_name}#{version_info} #{dep_info}")
      end
    end

    def update_command(args)
      parse_options!(args)

      components = if args.empty?
                     @registry.upgradable
                   else
                     @registry.find_all(args).select { |c| c.respond_to?(:upgradable?) && c.upgradable? }
                   end

      if components.empty?
        logger.info("업데이트할 컴포넌트가 없습니다.")

        installed = @registry.installed
        if installed.any?
          logger.info("현재 설치된 컴포넌트:")
          installed.each do |component|
            current = begin
              component.version
            rescue StandardError
              nil
            end
            logger.info("  #{component.display_name} (#{current || "unknown"})")
          end
        end
        return
      end

      logger.info("다음 컴포넌트가 업데이트됩니다:")
      components.each do |component|
        current = begin
          component.version
        rescue StandardError
          nil
        end
        latest = begin
          component.latest_version
        rescue StandardError
          nil
        end
        logger.info("  #{component.display_name} (#{current || "?"} -> #{latest || "?"})")
      end

      unless @auto_yes
        print "계속 하시겠습니까? [Y/n] "
        response = $stdin.gets&.strip&.downcase
        unless response.nil? || response.empty? || response == "y" || response == "yes"
          logger.info("업데이트가 취소되었습니다.")
          return
        end
      end

      components.each do |component|
        logger.info(">>> #{component.display_name} 업데이트 중...")
        begin
          component.update
          logger.info(">>> #{component.display_name} 업데이트 완료")
        rescue StandardError => e
          logger.error(">>> #{component.display_name} 업데이트 실패: #{e.message}")
        end
      end

      logger.info("업데이트가 완료되었습니다.")
    end

    def check_command(_args)
      logger.info("컴포넌트 상태 확인 중...")

      all_components = @registry.all
      installed_components = []
      not_installed_components = []
      upgradable_components = []

      all_components.each do |component|
        if component.installed?
          installed_components << component
          upgradable_components << component if component.respond_to?(:upgradable?) && component.upgradable?
        else
          not_installed_components << component
        end
      end

      if upgradable_components.any?
        logger.info("업데이트 가능한 컴포넌트:")
        upgradable_components.each do |component|
          current = begin
            component.version
          rescue StandardError
            nil
          end
          latest = begin
            component.latest_version
          rescue StandardError
            nil
          end
          logger.info("  #{component.display_name} (#{current || "?"} -> #{latest || "?"})")
        end
      end

      up_to_date = installed_components - upgradable_components
      if up_to_date.any?
        logger.info("최신 상태인 컴포넌트:")
        up_to_date.each do |component|
          current = begin
            component.version
          rescue StandardError
            nil
          end
          logger.info("  #{component.display_name} (#{current || "installed"})")
        end
      end

      if not_installed_components.any?
        logger.info("미설치 컴포넌트:")
        not_installed_components.each do |component|
          latest = begin
            component.latest_version
          rescue StandardError
            nil
          end
          version_info = latest ? " (latest: #{latest})" : ""
          logger.info("  #{component.display_name}#{version_info}")
        end
      end

      logger.info("전체: #{all_components.size}개, 설치됨: #{installed_components.size}개, " \
                  "업데이트 가능: #{upgradable_components.size}개, 미설치: #{not_installed_components.size}개")
    end

    def help_command
      puts option_parser
    end

    def option_parser
      @option_parser ||= OptionParser.new do |opts|
        opts.banner = "dotfiles CLI - 컴포넌트 설치 및 관리 도구\n\n" \
                      "사용법: ruby bin/cli.rb <command> [options] [components...]\n\n" \
                      "명령어:\n  " \
                      "install   컴포넌트를 설치합니다\n  " \
                      "update    설치된 컴포넌트를 업데이트합니다\n  " \
                      "check     컴포넌트 상태를 확인합니다\n  " \
                      "help      이 도움말을 표시합니다\n\n" \
                      "옵션:"

        opts.on("-y", "--yes", "확인 없이 바로 실행합니다") do
          @auto_yes = true
        end

        opts.on("-n", "--dry-run", "설치하지 않고 계획만 표시합니다") do
          @dry_run = true
        end

        opts.on("-h", "--help", "도움말을 표시합니다") do
          puts opts
          exit
        end

        opts.separator ""
        opts.separator "예시:"
        opts.separator "  ruby bin/cli.rb install              # 모든 미설치 컴포넌트 설치"
        opts.separator "  ruby bin/cli.rb install --yes        # 확인 없이 설치"
        opts.separator "  ruby bin/cli.rb install --dry-run    # 설치 계획만 확인"
        opts.separator "  ruby bin/cli.rb install bat fzf      # bat, fzf만 설치"
        opts.separator "  ruby bin/cli.rb update               # 설치된 컴포넌트 업데이트"
        opts.separator "  ruby bin/cli.rb check                # 상태 확인"
        opts.separator ""
        opts.separator "사용 가능한 컴포넌트:"
        opts.separator "  #{@registry.component_names.join(", ")}"
      end
    end

    def parse_options!(args)
      option_parser.parse!(args)
    rescue OptionParser::InvalidOption => e
      logger.error("오류: #{e.message}")
      puts option_parser
      exit 1
    end

  end
end

CLI::Runner.new.run(ARGV) if __FILE__ == $0
