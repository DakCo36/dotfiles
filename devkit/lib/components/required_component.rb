require "components/base"

module Component
  # Base class for prerequisite components that must be pre-installed on the system.
  #
  # RequiredComponent prerequisites (e.g., curl, git, tar) are foundational tools
  # that devkit depends on but does not manage. They:
  # - Do NOT have an install! method (not managed by devkit)
  # - Do NOT use Configurable mixin (not in devkit.toml)
  # - Only check availability via available? method
  # - Are validated at CLI startup via RequiredComponentChecker
  #
  class RequiredComponent < BaseComponent
    def available?
      raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
    end
  end
end
