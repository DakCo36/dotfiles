require "commands/utils/registry"
require "commands/utils/required_component_checker"
require "mixins/loggable"

module Commands
  class UpdateCommand

    include Loggable

    def initialize(auto_yes: false, dry_run: false)
      @registry = Commands::Registry.instance
      @auto_yes = auto_yes
      @dry_run = dry_run
    end

    def execute(component_names)
      Commands::RequiredComponentChecker.check!

      components = resolve_targets(component_names)

      if components.empty?
        logger.info("업데이트할 컴포넌트가 없습니다.")
        show_installed_status
        return
      end

      show_update_plan(components)

      if @dry_run
        logger.info("(dry-run 모드: 실제 업데이트는 수행되지 않았습니다)")
        return
      end

      return unless confirm?("계속 하시겠습니까? [Y/n] ")

      run_update(components)
    rescue Commands::MissingToolError => e
      logger.error(e.message)
      exit 1
    end

    private

    def resolve_targets(names)
      if names.empty?
        @registry.upgradable
      else
        @registry.find_all(names).select { |c| c.respond_to?(:upgradable?) && c.upgradable? }
      end
    end

    def show_installed_status
      installed = @registry.installed
      return unless installed.any?

      logger.info("현재 설치된 컴포넌트:")
      installed.each do |component|
        current = safe_version(component)
        logger.info("  #{component.display_name} (#{current || "unknown"})")
      end
    end

    def show_update_plan(components)
      logger.info("다음 컴포넌트가 업데이트됩니다:")
      components.each do |component|
        current = safe_version(component)
        latest = safe_latest_version(component)
        logger.info("  #{component.display_name} (#{current || "?"} -> #{latest || "?"})")
      end
    end

    def run_update(components)
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

    def confirm?(prompt)
      return true if @auto_yes

      print prompt
      response = $stdin.gets&.strip&.downcase
      return true if response.nil? || response.empty? || response == "y" || response == "yes"

      logger.info("업데이트가 취소되었습니다.")
      false
    end

    def safe_version(component)
      component.version
    rescue StandardError
      nil
    end

    def safe_latest_version(component)
      component.latest_version
    rescue StandardError
      nil
    end

  end
end
