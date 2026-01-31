# Configurable Mixin
#
# Provides easy access to TOML configuration for components.
# Components automatically get their configuration based on display_name.
#
# Usage:
#   config.version  # => "latest"
#   config.owner    # => "sharkdp"
#   config.enabled  # => true

require "components/configuration"

module Configurable

  # Returns the component's configuration as a Data object for dot notation access.
  # @return [Components::Configuration::ComponentConfig] config object with all TOML settings
  # @example
  #   config.version  # => "latest"
  #   config.owner    # => "junegunn"
  #   config.enabled  # => true
  def config
    @config ||= Components::Configuration.instance.component_config(config_key)
  end

  # Returns the raw component configuration hash from TOML
  # @return [Hash] component configuration
  def component_config
    @component_config ||= Components::Configuration.instance.manifest[config_key] || {}
  end

  # The key used to look up this component's config in TOML
  # Defaults to display_name, can be overridden
  # @return [String] config key
  def config_key
    display_name
  end

end
