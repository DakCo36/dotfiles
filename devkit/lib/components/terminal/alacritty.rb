# frozen_string_literal: true

require "singleton"
require "components/installable_component"
require "components/configuration"
require "components/language/rust"
require "mixins/loggable"

module Component
  class AlacrittyComponent < InstallableComponent

    depends_on Component::RustComponent

    # Checks if Alacritty is available.
    #
    # @return [Boolean] true if available, false otherwise
    def available?
      system("alacritty", "--version", out: File::NULL, err: File::NULL)
    end

    # Returns the current Alacritty version.
    #
    # @return [String, nil] Version string (e.g., "0.16.1") or nil
    def version
      output, status = Open3.capture2("alacritty", "--version")
      return nil unless status.success?

      # example: alacritty 0.16.1 (a]b2c3d4)
      output.split[1]
    rescue Errno::ENOENT
      nil
    end

    # Checks if Alacritty is installed.
    #
    # @return [Boolean] true if installed, false otherwise
    def installed?
      available? && !version.nil?
    end

    # Returns the latest version (uses config version).
    #
    # @return [String] target version
    def latest_version
      config.version
    end

    # Installs Alacritty (skips if already installed or unsupported OS).
    #
    # @return [void]
    def install
      unless linux?
        logger.error("Alacritty installation is only supported on Linux. Skipping.")
        return
      end

      if installed?
        logger.info("Alacritty #{version} is already installed.")
        return
      end
      install!
    end

    # Force installs Alacritty via cargo.
    #
    # @return [void]
    def install!
      unless linux?
        logger.error("Alacritty installation is only supported on Linux. Skipping.")
        return
      end

      logger.info("Installing Alacritty via cargo...")
      runCmd("mise", "exec", "rust", "--", "cargo", "install", "alacritty", showStdout: true)
      logger.info("Alacritty installed successfully.")
    end

    def rollback
      raise "Not implemented"
    end

    private

    # Checks if running on Linux.
    #
    # @return [Boolean] true if Linux, false otherwise
    def linux?
      config.os.include?("linux")
    end

  end
end
