# frozen_string_literal: true

require "singleton"
require "components/installable_component"
require "components/configuration"
require "mixins/loggable"

module Component
  class NodeComponent < InstallableComponent

    # Returns the current Node.js version.
    #
    # @return [String, nil] Version string (e.g., "24.13.0") or nil
    def version
      output, status = Open3.capture2("mise", "current", "node")
      return nil unless status.success?

      output.strip.split.last
    rescue Errno::ENOENT
      nil
    end

    # Checks if Node.js is installed.
    #
    # @return [Boolean] true if installed, false otherwise
    def installed?
      !version.nil?
    end

    # Returns the desired version from config.
    #
    # @return [String] config version
    def latest_version
      config.version
    end

    protected

    # Installs Node.js via mise.
    #
    # @return [void]
    def perform_install
      ver = config.version
      logger.info("Installing Node.js #{ver} via mise...")

      runCmd("mise", "use", "--global", "node@#{ver}")

      logger.info("Node.js #{ver} installed successfully via mise.")
    end

  end
end
