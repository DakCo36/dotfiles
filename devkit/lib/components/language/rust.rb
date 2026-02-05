# frozen_string_literal: true

require "singleton"
require "components/installable_component"
require "components/configuration"
require "components/shell/zsh_binary"
require "mixins/loggable"

module Component
  class RustComponent < InstallableComponent

    # Depends on zsh for .zprofile (cargo bin PATH)
    depends_on ZshBinaryComponent

    # Default Rust version to use if not specified in config
    DEFAULT_VERSION = "1.93.0"

    # Checks if Rust is available via mise.
    #
    # @return [Boolean] true if available, false otherwise
    def available?
      system("mise", "which", "rustc", out: File::NULL, err: File::NULL)
    end

    # Returns the current Rust version.
    #
    # @return [String, nil] Version string (e.g., "1.93.0") or nil
    def version
      output, status = Open3.capture2("mise", "current", "rust")
      return nil unless status.success?

      output.strip.split.last
    rescue Errno::ENOENT
      nil
    end

    # Checks if Rust is installed.
    #
    # @return [Boolean] true if installed, false otherwise
    def installed?
      available? && !version.nil?
    end

    # Returns the target version from config or default.
    #
    # @return [String] target version
    def target_version
      config.version || DEFAULT_VERSION
    end

    # Returns the latest version (uses target version).
    #
    # @return [String] target version
    def latest_version
      target_version
    end

    # Installs Rust (skips if already installed).
    #
    # @return [void]
    def install
      if installed?
        logger.info("Rust #{version} is already installed via mise.")
        return
      end
      install!
    end

    # Force installs Rust via mise.
    #
    # @return [void]
    def install!
      ver = target_version
      logger.info("Installing Rust #{ver} via mise...")

      runCmd("mise", "use", "--global", "rust@#{ver}")
      setup_cargo_path

      logger.info("Rust #{ver} installed successfully via mise.")
    end

    private

    # Adds ~/.cargo/bin to PATH in .zprofile if not already present.
    def setup_cargo_path
      cargo_bin = "$HOME/.cargo/bin"
      path_export = "export PATH=\"#{cargo_bin}:$PATH\""

      zprofile_content = File.exist?(config.zprofile) ? File.read(config.zprofile) : ""

      if zprofile_content.include?(".cargo/bin")
        logger.info("cargo bin already in .zprofile PATH")
        return
      end

      logger.info("Adding cargo bin to .zprofile PATH")
      File.open(config.zprofile, "a") do |file|
        file.puts("")
        file.puts("# Rust/Cargo")
        file.puts(path_export)
      end
    end

  end
end
