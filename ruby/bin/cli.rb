#!/usr/bin/env ruby
# CLI 인터페이스 - install, update, check 명령어 지원
#
# 사용법:
#   ruby bin/cli.rb install [--yes] [component...]  # 컴포넌트 설치
#   ruby bin/cli.rb update [--yes] [component...]   # 설치된 컴포넌트 업데이트
#   ruby bin/cli.rb check                           # 업데이트 가능 목록 표시
#   ruby bin/cli.rb help                            # 도움말 표시

require_relative 'bin_helper'
require 'optparse'
require 'mixins/loggable'

require 'components/shell/zsh_binary'
require 'components/shell/oh_my_zsh'
require 'components/shell/powerlevel10k'
require 'components/shell/zgenom'
require 'components/utils/bat'
require 'components/utils/fastfetch'
require 'components/utils/fd'
require 'components/utils/ripgrep'
require 'components/utils/fzf'

require 'cli/registry'

module CLI
  class Runner
    include Loggable

    def initialize
      @registry = Registry.instance
      @auto_yes = false
    end

    def run(args)
      command = args.shift || 'help'

      case command
      when 'install'
        install_command(args)
      when 'update'
        update_command(args)
      when 'check'
        check_command(args)
      when 'help', '-h', '--help'
        help_command
      else
        puts "알 수 없는 명령어: #{command}"
        puts
        help_command
        exit 1
      end
    end

    private
    def install_command(args)
      parse_options!(args)

      components = if args.empty?
                     @registry.not_installed
                   else
                     @registry.find_all(args).reject(&:installed?)
                   end

      if components.empty?
        puts "설치할 컴포넌트가 없습니다. 모든 컴포넌트가 이미 설치되어 있습니다."
        return
      end

      puts "다음 컴포넌트가 새로 설치됩니다:"
      components.each do |component|
        latest = component.latest_version rescue nil
        version_info = latest ? " (latest: #{latest})" : ""
        puts "  #{component.display_name}#{version_info}"
      end
      puts

      unless @auto_yes
        print "계속 하시겠습니까? [Y/n] "
        response = $stdin.gets&.strip&.downcase
        unless response.nil? || response.empty? || response == 'y' || response == 'yes'
          puts "설치가 취소되었습니다."
          return
        end
      end

      puts
      components.each do |component|
        puts ">>> #{component.display_name} 설치 중..."
        begin
          component.install
          puts ">>> #{component.display_name} 설치 완료"
        rescue => e
          puts ">>> #{component.display_name} 설치 실패: #{e.message}"
          logger.error("Failed to install #{component.display_name}: #{e.message}")
        end
        puts
      end

      puts "설치가 완료되었습니다."
    end

    def update_command(args)
      parse_options!(args)

      components = if args.empty?
                     @registry.upgradable
                   else
                     @registry.find_all(args).select { |c| c.respond_to?(:upgradable?) && c.upgradable? }
                   end

      if components.empty?
        puts "업데이트할 컴포넌트가 없습니다."
        
        installed = @registry.installed
        if installed.any?
          puts "\n현재 설치된 컴포넌트:"
          installed.each do |component|
            current = component.version rescue nil
            puts "  #{component.display_name} (#{current || 'unknown'})"
          end
        end
        return
      end

      puts "다음 컴포넌트가 업데이트됩니다:"
      components.each do |component|
        current = component.version rescue nil
        latest = component.latest_version rescue nil
        puts "  #{component.display_name} (#{current || '?'} -> #{latest || '?'})"
      end
      puts

      unless @auto_yes
        print "계속 하시겠습니까? [Y/n] "
        response = $stdin.gets&.strip&.downcase
        unless response.nil? || response.empty? || response == 'y' || response == 'yes'
          puts "업데이트가 취소되었습니다."
          return
        end
      end

      puts
      components.each do |component|
        puts ">>> #{component.display_name} 업데이트 중..."
        begin
          component.update
          puts ">>> #{component.display_name} 업데이트 완료"
        rescue => e
          puts ">>> #{component.display_name} 업데이트 실패: #{e.message}"
          logger.error("Failed to update #{component.display_name}: #{e.message}")
        end
        puts
      end

      puts "업데이트가 완료되었습니다."
    end

    def check_command(_args)
      puts "컴포넌트 상태 확인 중...\n\n"

      all_components = @registry.all
      installed_components = []
      not_installed_components = []
      upgradable_components = []

      all_components.each do |component|
        if component.installed?
          installed_components << component
          if component.respond_to?(:upgradable?) && component.upgradable?
            upgradable_components << component
          end
        else
          not_installed_components << component
        end
      end

      if upgradable_components.any?
        puts "업데이트 가능한 컴포넌트:"
        upgradable_components.each do |component|
          current = component.version rescue nil
          latest = component.latest_version rescue nil
          puts "  #{component.display_name} (#{current || '?'} -> #{latest || '?'})"
        end
        puts
      end

      up_to_date = installed_components - upgradable_components
      if up_to_date.any?
        puts "최신 상태인 컴포넌트:"
        up_to_date.each do |component|
          current = component.version rescue nil
          puts "  #{component.display_name} (#{current || 'installed'})"
        end
        puts
      end

      if not_installed_components.any?
        puts "미설치 컴포넌트:"
        not_installed_components.each do |component|
          latest = component.latest_version rescue nil
          version_info = latest ? " (latest: #{latest})" : ""
          puts "  #{component.display_name}#{version_info}"
        end
        puts
      end

      puts "---"
      puts "전체: #{all_components.size}개, 설치됨: #{installed_components.size}개, " \
           "업데이트 가능: #{upgradable_components.size}개, 미설치: #{not_installed_components.size}개"
    end

    def help_command
      puts option_parser
    end

    def option_parser
      @option_parser ||= OptionParser.new do |opts|
        opts.banner = "dotfiles CLI - 컴포넌트 설치 및 관리 도구\n\n" \
                      "사용법: ruby bin/cli.rb <command> [options] [components...]\n\n" \
                      "명령어:\n" \
                      "  install   컴포넌트를 설치합니다\n" \
                      "  update    설치된 컴포넌트를 업데이트합니다\n" \
                      "  check     컴포넌트 상태를 확인합니다\n" \
                      "  help      이 도움말을 표시합니다\n\n" \
                      "옵션:"

        opts.on("-y", "--yes", "확인 없이 바로 실행합니다") do
          @auto_yes = true
        end

        opts.on("-h", "--help", "도움말을 표시합니다") do
          puts opts
          exit
        end

        opts.separator ""
        opts.separator "예시:"
        opts.separator "  ruby bin/cli.rb install              # 모든 미설치 컴포넌트 설치"
        opts.separator "  ruby bin/cli.rb install --yes        # 확인 없이 설치"
        opts.separator "  ruby bin/cli.rb install bat fzf      # bat, fzf만 설치"
        opts.separator "  ruby bin/cli.rb update               # 설치된 컴포넌트 업데이트"
        opts.separator "  ruby bin/cli.rb check                # 상태 확인"
        opts.separator ""
        opts.separator "사용 가능한 컴포넌트:"
        opts.separator "  #{@registry.component_names.join(', ')}"
      end
    end

    def parse_options!(args)
      option_parser.parse!(args)
    rescue OptionParser::InvalidOption => e
      puts "오류: #{e.message}"
      puts option_parser
      exit 1
    end
  end
end

if __FILE__ == $0
  CLI::Runner.new.run(ARGV)
end
