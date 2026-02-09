# frozen_string_literal: true

require "singleton"
require "components/installable_component"
require "components/configuration"
require "mixins/loggable"

module Component
  class NodeComponent < InstallableComponent

    # Fixed Node.js version to use (LTS Krypton)
    NODE_VERSION = "24.13.0"

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

    # Returns the latest version (uses fixed version).
    #
    # @return [String] NODE_VERSION
    def latest_version
      NODE_VERSION
    end

    protected

    # Installs Node.js via mise.
    #
    # @return [void]
    def perform_install
      logger.info("Installing Node.js #{NODE_VERSION} via mise...")

      runCmd("mise", "use", "--global", "node@#{NODE_VERSION}")

      logger.info("Node.js #{NODE_VERSION} installed successfully via mise.")
    end

  end
end
