# frozen_string_literal: true

require "singleton"
require "components/installable_component"
require "components/configuration"
require "mixins/loggable"

module Component
  class GolangComponent < InstallableComponent
    
    # Fixed go version to use
    GO_VERSION = "1.26.0"

    # Return the current go version
    # 
    # @return [String, nil] Version string (e.g., "1.26.0") or nil if not installed
    def version
      output, status = Open3.capture2("mise", "current", "go")
      return nil unless status.success?

      output.strip.split.last
    rescue Errno::ENOENT
      nil
    end

    # Check if go is installed
    # 
    # @return [Boolean] true if installed, false otherwise
    def installed?
      !version.nil?
    end

    # Returns the latest version (uses fixed version)
    # 
    # @return [String] GO_VERSION
    def latest_version
      GO_VERSION
    end

    protected

    # Installs go via mise
    # 
    # @return [void]
    def perform_install
      logger.info("Installing go #{GO_VERSION} via mise...")

      runCmd("mise", "use", "--global", "go@#{GO_VERSION}")

      logger.info("go #{GO_VERSION} installed successfully via mise.")
    end

    def post_install
      install_gopls
    end

    def install_gopls
      logger.info("Installing gopls via go install...")
      runCmd("go", "install", "golang.org/x/tools/gopls@latest")
      logger.info("gopls installed successfully.")
    end
  end
end