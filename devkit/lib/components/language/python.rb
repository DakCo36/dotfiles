# frozen_string_literal: true

require "singleton"
require "components/installable_component"
require "components/configuration"
require "mixins/loggable"

module Component
  class PythonComponent < InstallableComponent

    # Fixed Python version to use
    PYTHON_VERSION = "3.12.8"

    # Checks if Python is available via mise.
    #
    # @return [Boolean] true if available, false otherwise
    def available?
      system("mise", "which", "python", out: File::NULL, err: File::NULL)
    end

    # Returns the current Python version.
    #
    # @return [String, nil] Version string (e.g., "3.12.8") or nil
    def version
      output, status = Open3.capture2("mise", "current", "python")
      return nil unless status.success?

      output.strip.split.last
    rescue Errno::ENOENT
      nil
    end

    # Checks if Python is installed.
    #
    # @return [Boolean] true if installed, false otherwise
    def installed?
      available? && !version.nil?
    end

    # Returns the latest version (uses fixed version).
    #
    # @return [String] PYTHON_VERSION
    def latest_version
      PYTHON_VERSION
    end

    # Installs Python (skips if already installed).
    #
    # @return [void]
    def install
      if installed?
        logger.info("Python #{version} is already installed via mise.")
        return
      end
      install!
    end

    # Force installs Python via mise.
    #
    # @return [void]
    def install!
      logger.info("Installing Python #{PYTHON_VERSION} via mise...")

      runCmd("mise", "use", "--global", "python@#{PYTHON_VERSION}")

      logger.info("Python #{PYTHON_VERSION} installed successfully via mise.")
    end

  end
end
