# frozen_string_literal: true

require "singleton"
require "components/base"
require "components/configuration"
require "mixins/installable"
require "mixins/loggable"

module Component
  class PythonComponent < BaseComponent

    prepend Installable

    # Fixed Python version to use
    PYTHON_VERSION = "3.12.8"

    CONFIG = Components::Configuration.instance

    # Check if Python is available via mise
    def available?
      system("mise", "which", "python", out: File::NULL, err: File::NULL)
    end

    # Return the currently installed Python version
    def version
      # mise current python output format: "python 3.12.8"
      output, status = Open3.capture2("mise", "current", "python")
      return nil unless status.success?

      # Extract only the version number (e.g. "3.12.8")
      output.strip.split.last
    rescue Errno::ENOENT
      nil
    end

    # Check if Python is installed via mise
    def installed?
      available? && !version.nil?
    end

    # Return the target version (this component uses a fixed version, so latest_version = PYTHON_VERSION)
    def latest_version
      PYTHON_VERSION
    end

    # Install Python if it is not installed
    def install
      if installed?
        logger.info("Python #{version} is already installed via mise.")
        return
      end
      install!
    end

    # Install Python via mise
    def install!
      logger.info("Installing Python #{PYTHON_VERSION} via mise...")

      runCmd("mise", "use", "--global", "python@#{PYTHON_VERSION}")

      logger.info("Python #{PYTHON_VERSION} installed successfully via mise.")
    end

  end
end
