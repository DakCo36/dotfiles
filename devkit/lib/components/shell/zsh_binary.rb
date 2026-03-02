require "fileutils"
require "components/installable_component"
require "components/configuration"
require "components/prerequisites/curl"

module Component
  class ZshBinaryComponent < InstallableComponent

    TARGET_VERSION = "5.9"
    DOWNLOAD_URL = "https://sourceforge.net/projects/zsh/files/zsh/#{TARGET_VERSION}/zsh-#{TARGET_VERSION}.tar.xz/download"

    depends_on Component::CurlComponent

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
      out.split(" ")[1]
    end

    # Returns the latest version.
    #
    # @return [String] TARGET_VERSION
    def latest_version
      TARGET_VERSION
    end


    protected

    # Force installs zsh.
    #
    # @return [void]
    def perform_install
      logger.info("Installing zsh version #{TARGET_VERSION}")
      curl.download(DOWNLOAD_URL, tmp_file_path)
      logger.info("Unzip #{tmp_file_path} to #{tmp_dir_path}")
      runCmd("tar", "-xf", tmp_file_path, "-C", File.dirname(tmp_file_path))
      configureAndMake
    rescue StandardError
      logger.error("Failed to install zsh: #{$!}")
      raise "Failed to install zsh: #{$!}"
    end

    def post_install
      setPath
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
        file.puts("# Auto-launch zsh (interactive terminal only)")
        file.puts("if [ -x \"#{zsh_path}\" ] && [ -z \"$ZSH_VERSION\" ] && [ -t 0 ] && [ -z \"$VSCODE_RESOLVING_ENVIRONMENT\" ]; then")
        # FIXME Add eat check (only vterm allow to exec zsh)
        # && { [ -z "$INSIDE_EMACS" ] || [ "$INSIDE_EMACS" = "vterm" ]}
        file.puts("  exec \"#{zsh_path}\" -l")
        file.puts("fi")
      end
    end

    def addExecZshInBashProfile
      addExecZshToFile(config.bash_profile, "bash_profile")
    end

    def addExecZshInBashrc
      addExecZshToFile(config.bashrc, "bashrc")
    end

  end
end
