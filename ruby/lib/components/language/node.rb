# frozen_string_literal: true

require "singleton"
require "components/base"
require "components/configuration"
require "mixins/installable"
require "mixins/loggable"

module Component
  class NodeComponent < BaseComponent

    prepend Installable

    # Fixed Node.js version to use (LTS Krypton)
    NODE_VERSION = "24.13.0"

    CONFIG = Components::Configuration.instance

    # Check if Node.js is available via mise
    #
    # @return [Boolean] true if node is available
    def available?
      system("mise", "which", "node", out: File::NULL, err: File::NULL)
    end

    # Return the currently installed Node.js version
    #
    # @return [String, nil] version string (e.g. "24.13.0") or nil if not installed
    def version
      output, status = Open3.capture2("mise", "current", "node")
      return nil unless status.success?

      output.strip.split.last
    rescue Errno::ENOENT
      nil
    end

    # Check if Node.js is installed via mise
    #
    # @return [Boolean] true if installed
    def installed?
      available? && !version.nil?
    end

    # Return the target version (this component uses a fixed version)
    #
    # @return [String] the target Node.js version
    def latest_version
      NODE_VERSION
    end

    # Install Node.js if it is not installed
    def install
      if installed?
        logger.info("Node.js #{version} is already installed via mise.")
        return
      end
      install!
    end

    # Install Node.js via mise
    def install!
      logger.info("Installing Node.js #{NODE_VERSION} via mise...")

      runCmd("mise", "use", "--global", "node@#{NODE_VERSION}")

      logger.info("Node.js #{NODE_VERSION} installed successfully via mise.")
    end

  end
end
