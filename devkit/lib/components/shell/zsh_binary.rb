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

      addSourceBashrcInBashProfile
      addLocalBinPathInBashrc
    end

    def addLocalBinPathInBashrc
      time = Time.now.strftime("%Y%m%d%H%M%S")
      logger.debug("Backup existing .bashrc file to .bashrc.bak_#{time}")
      FileUtils.cp(config.bashrc, "#{config.bashrc}.bak_#{time}") if File.exist?(config.bashrc)

      contracted_bin_path = config.contract_path(config.bin)
      zsh_path_line = "export PATH=\"#{contracted_bin_path}:$PATH\""
      FileUtils.touch(config.bashrc) unless File.exist?(config.bashrc)
      bashrc_content = File.read(config.bashrc)

      escaped_config_bin = Regexp.escape(config.bin)
      if bashrc_content =~ %r{export\s+PATH=.*?(#{escaped_config_bin}|(\$HOME|~)/\.local/bin)}
        logger.info("PATH already set in .bashrc, skipping")
      else
        logger.info("Adding PATH to .bashrc")
        File.open(config.bashrc, "a") do |file|
          file.puts(zsh_path_line)
        end
      end
    end

    def addSourceBashrcInBashProfile
      logger.debug("Setting up .bash_profile to source .bashrc on last")
      time = Time.now.strftime("%Y%m%d%H%M%S")
      FileUtils.touch(config.bash_profile) unless File.exist?(config.bash_profile)
      FileUtils.cp(config.bash_profile, "#{config.bash_profile}.bak_#{time}") if File.exist?(config.bash_profile)
      bash_profile_content = File.read(config.bash_profile)

      bash_profile_content.gsub!(
        %r{if\s+\[\s*-f\s+~?/\.bashrc\s*\];\s*then\s*\n?\s*(\.|source)\s+~?/\.bashrc\s*\n?fi\n?}, ""
      )
      bash_profile_content.gsub!(%r{^\s*(\.|source)\s+~?/?\.bashrc\s*\n?}, "")

      File.open(config.bash_profile, "w") do |file|
        file.puts(bash_profile_content)
      end
      File.open(config.bash_profile, "a") do |file|
        file.puts("if [ -f ~/.bashrc ]; then")
        file.puts("  . ~/.bashrc")
        file.puts("fi")
      end
    end

  end
end
