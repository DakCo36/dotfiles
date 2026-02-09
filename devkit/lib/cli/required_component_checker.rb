require "components/prerequisites/curl"
require "components/prerequisites/git"
require "components/prerequisites/tar"

module CLI
  class MissingToolError < StandardError; end

  class RequiredComponentChecker

    REQUIRED_COMPONENTS = [
      Component::CurlComponent,
      Component::GitComponent,
      Component::TarComponent,
    ].freeze

    def self.check!
      missing = REQUIRED_COMPONENTS.filter_map do |component_class|
        component = component_class.instance
        component.display_name unless component.available?
      end

      return if missing.empty?

      raise MissingToolError, "Missing required components: #{missing.join(', ')}"
    end

  end
end
