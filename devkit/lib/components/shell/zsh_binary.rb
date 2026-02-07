require "fileutils"
require "components/installable_component"
require "components/configuration"
require "components/tools/curl"

module Component
  class ZshBinaryComponent < InstallableComponent

    TARGET_VERSION = "5.9"
    DOWNLOAD_URL = "https://sourceforge.net/projects/zsh/files/zsh/#{TARGET_VERSION}/zsh-#{TARGET_VERSION}.tar.xz/download"

    depends_on Component::CurlComponent

    # Checks if zsh is available.
    #
    # @return [Boolean] true if available, false otherwise
    def available?
      runCmd("which", "zsh")
      logger.debug("Zsh is available")
      true
    rescue RuntimeError
      logger.debug("Zsh is not available")
      false
    end

    # Checks if zsh is installed locally.
    #
    # @return [Boolean] true if installed, false otherwise
    def installed?
      local_zsh_path = File.join(config.bin, "zsh")
      is_in_path = ENV["PATH"]
                   &.to_s
                   &.split(":")
                   &.any? { |path| path == config.bin }

      if is_in_path && File.exist?(local_zsh_path) && File.executable?(local_zsh_path)
        logger.info("Zsh is installed locally at #{local_zsh_path}")
        return true
      end

      logger.info("Zsh is not installed")
      false
    end

    # Returns the current zsh version.
    #
    # @return [String, nil] Version string (e.g., "5.9")
    def version
      out = runCmdWithOutput("zsh", "--version")
      out.split(" ")[1] # example zsh 5.8 (x86_64-pc-linux-musl)
    end

    # Returns the latest version.
    #
    # @return [String] TARGET_VERSION
    def latest_version
      TARGET_VERSION
    end

    # Installs zsh (skips if already installed).
    #
    # @return [void]
    def install
      if installed?
        logger.info("Zsh is already installed.")
        return
      end
      install!
    end

    # Force installs zsh.
    #
    # @return [void]
    def install!
      logger.info("Installing zsh version #{TARGET_VERSION}")
      curl.download(DOWNLOAD_URL, tmp_file_path)
      logger.info("Unzip #{tmp_file_path} to #{tmp_dir_path}")
      runCmd("tar", "-xf", tmp_file_path, "-C", File.dirname(tmp_file_path))
      configureAndMake
      setPath
    rescue StandardError
      logger.error("Failed to install zsh: #{$!}")
      raise "Failed to install zsh: #{$!}"
    end

    def rollback
      raise "Not implemented"
    end

    private

    # @return [String]
    def tmp_file_path
      File.join(config.tmp, "zsh-#{TARGET_VERSION}.tar.xz")
    end

    # @return [String]
    def tmp_dir_path
      File.join(config.tmp, "zsh-#{TARGET_VERSION}")
    end

    def configureAndMake
      logger.info("Configuring zsh")
      withDir(tmp_dir_path) do
        runCmd("./configure", "--prefix", config.local, "--with-tcsetpgrp", showStdout: true)
        runCmd("make", "-j", "4")
        runCmd("make", "install")
      end
      logger.info("Zsh installed successfully.")
    end

    def setPath
      logger.info("Setting PATH to include #{config.bin}")
      paths = ENV["PATH"].to_s.split(":").reject do |path|
        path.empty? || path == config.bin
      end
      paths.unshift(config.bin)
      ENV["PATH"] = paths.join(":")
      logger.debug("Current PATH: #{ENV.fetch("PATH", nil)}")

      ensure_zsh_config_files_exist
      addExecZshInBashProfile
      addExecZshInBashrc
    end

    # Creates .zprofile and .zshrc if they don't exist.
    def ensure_zsh_config_files_exist
      FileUtils.touch(config.zprofile)
      FileUtils.touch(config.zshrc)
      logger.info("Ensured .zprofile and .zshrc exist")
    end

    # Adds exec zsh to the given bash config file for auto-launching zsh.
    # Uses ZSH_VERSION check to prevent infinite loop.
    # @param file_path [String] path to the bash config file
    # @param label [String] human-readable name for logging
    def addExecZshToFile(file_path, label)
      zsh_path = config.contract_path(File.join(config.bin, "zsh"))

      FileUtils.touch(file_path) unless File.exist?(file_path)

      content = File.read(file_path)
      if content.include?("exec") && content.include?("zsh")
        logger.info("exec zsh already in #{label}, skipping")
        return
      end

      logger.info("Adding exec zsh to #{label}")
      File.open(file_path, "a") do |file|
        file.puts("")
        file.puts("# Auto-launch zsh")
        file.puts("if [ -x \"#{zsh_path}\" ] && [ -z \"$ZSH_VERSION\" ]; then")
        file.puts("  exec \"#{zsh_path}\" -l")
        file.puts("fi")
      end
    end

    # Adds exec zsh to .bash_profile (for login shells: SSH, su -, etc.)
    def addExecZshInBashProfile
      addExecZshToFile(config.bash_profile, "bash_profile")
    end

    # Adds exec zsh to .bashrc (for interactive non-login shells: terminal emulators)
    def addExecZshInBashrc
      addExecZshToFile(config.bashrc, "bashrc")
    end

  end
end
