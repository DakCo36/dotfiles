# Configurable Mixin
#
# Provides easy access to TOML configuration for components.
# Components automatically get their configuration based on display_name.

require "components/configuration"

module Configurable

  # Returns the component's configuration from TOML
  # @return [Hash] component configuration
  def component_config
    @component_config ||= Components::Configuration.instance.component_config(config_key)
  end

  # The key used to look up this component's config in TOML
  # Defaults to display_name, can be overridden
  def config_key
    display_name
  end

  # Returns the configured version for this component
  # @return [String, nil] version string or nil
  def config_version
    component_config["version"]
  end

  # Checks if this component is enabled in configuration
  # @return [Boolean] true if component is defined in manifest and enabled, false otherwise
  def config_enabled?
    return false if component_config.empty?

    component_config.fetch("enabled", true)
  end

  # Returns the configured source type (github, git, system, mise)
  # @return [String, nil] source type
  def config_source
    component_config["source"]
  end

end
