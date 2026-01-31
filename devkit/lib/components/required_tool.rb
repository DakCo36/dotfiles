require "components/base"

module Component
  # Base class for required tools that must be pre-installed on the system.
  #
  # RequiredTool components (e.g., curl, git, tar) are foundational tools
  # that devkit depends on but does not manage. They:
  # - Do NOT have an install! method (not managed by devkit)
  # - Do NOT use Configurable mixin (not in devkit.toml)
  # - Only check availability via available? method
  #
  class RequiredTool < BaseComponent

    # Checks if the required tool is installed.
    #
    # For RequiredTool, this simply delegates to available? since
    # these tools are either present on the system or not.
    #
    # @return [Boolean] true if the tool is available
    def installed?
      available?
    end

  end
end
