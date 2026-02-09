require "commands/utils/registry"
require "commands/utils/dependency_resolver"
require "commands/utils/required_component_checker"
require "mixins/loggable"

module Commands
  class InstallCommand

    include Loggable

    def initialize(auto_yes: false, dry_run: false, force: false)
      @registry = Commands::Registry.instance
      @auto_yes = auto_yes
      @dry_run = dry_run
      @force = force
    end

    def execute(component_names)
      Commands::RequiredComponentChecker.check!

      requested = resolve_requested(component_names)

      if requested.empty?
        logger.info("설치할 컴포넌트가 없습니다. 모든 컴포넌트가 이미 설치되어 있습니다.")
        return
      end

      resolver = Commands::DependencyResolver.new
      install_plan = resolver.resolve(requested, force: @force)

      if install_plan.empty?
        logger.info("설치할 컴포넌트가 없습니다. 모든 컴포넌트가 이미 설치되어 있습니다.")
        return
      end

      show_install_plan(install_plan, requested)

      if @dry_run
        logger.info("(dry-run 모드: 실제 설치는 수행되지 않았습니다)")
        return
      end

      return unless confirm?("계속 하시겠습니까? [Y/n] ")

      run_install(install_plan)
    rescue Commands::DependencyResolver::CircularDependencyError => e
      logger.error("의존성 오류: #{e.message}")
    rescue Commands::MissingToolError => e
      logger.error(e.message)
      exit 1
    end

    private

    def resolve_requested(names)
      if @force
        names.empty? ? @registry.all : @registry.find_all(names)
      elsif names.empty?
        @registry.not_installed
      else
        @registry.find_all(names).reject(&:installed?)
      end
    end

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

    def run_install(install_plan)
      install_plan.each do |component|
        action = @force ? "재설치" : "설치"
        logger.info(">>> #{component.display_name} #{action} 중...")
        begin
          @force ? component.install! : component.install
          logger.info(">>> #{component.display_name} #{action} 완료")
        rescue StandardError => e
          logger.error(">>> #{component.display_name} 설치 실패: #{e.message}")
          logger.error("설치가 중단되었습니다.")
          return
        end
      end

      logger.info("설치가 완료되었습니다.")
    end

    def confirm?(prompt)
      return true if @auto_yes

      print prompt
      response = $stdin.gets&.strip&.downcase
      return true if response.nil? || response.empty? || response == "y" || response == "yes"

      logger.info("설치가 취소되었습니다.")
      false
    end

  end
end
