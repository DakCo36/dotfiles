require 'fileutils'
require 'components/base'
require 'components/configuration'
require 'mixins/installable'
require 'components/fetch/curl'

module Component
  class ZshBinaryComponent < BaseComponent
    prepend Installable

    CONFIG = Components::Configuration.instance
    TARGET_VERSION="5.9"
    TARGET_FILE_NAME = "zsh-#{TARGET_VERSION}.tar.xz"
    TARGET_DIR_NAME = "zsh-#{TARGET_VERSION}"

    TMP_FILE_PATH = File.join(CONFIG.tmp, TARGET_FILE_NAME)
    TMP_DIR_PATH = File.join(CONFIG.tmp, TARGET_DIR_NAME)

    DOWNLOAD_URL = "https://sourceforge.net/projects/zsh/files/zsh/#{TARGET_VERSION}/#{TARGET_FILE_NAME}/download"

    private_constant :TARGET_VERSION, :TARGET_FILE_NAME, :TARGET_DIR_NAME, :TMP_FILE_PATH, :TMP_DIR_PATH, :DOWNLOAD_URL

    depends_on Component::CurlComponent

    def available?
      runCmd('which', 'zsh')
      logger.debug("Zsh is available")
      true
    rescue RuntimeError
      logger.debug("Zsh is not available")
      false
    end

    def installed?
      # Check if zsh is installed locally first
      local_zsh_path = File.join(CONFIG.bin, 'zsh')
      is_in_path = ENV['PATH']
        &.to_s
        &.split(':')
        &.any? { |path| path == CONFIG.bin }

      if is_in_path && File.exist?(local_zsh_path) && File.executable?(local_zsh_path)
        logger.info("Zsh is installed locally at #{local_zsh_path}")
        return true
      end

      logger.info("Zsh is not installed")
      false
    end

    def version
      out = runCmdWithOutput('zsh', '--version')
      out.split(' ')[1] # example zsh 5.8 (x86_64-pc-linux-musl)
    end

    # Assume current default shell is bash
    def install
      if installed?
        logger.info("Zsh is already installed.")
        return
      end

      logger.info("Installing zsh version #{TARGET_VERSION}")
      curl.download(DOWNLOAD_URL, TMP_FILE_PATH)
      logger.info("Unzip #{TMP_FILE_PATH} to #{TMP_DIR_PATH}")
      runCmd('tar', '-xf', TMP_FILE_PATH, '-C', File.dirname(TMP_FILE_PATH))
      configureAndMake()
      setPath()
    rescue
      logger.error("Failed to install zsh: #{$!}")
      raise "Failed to install zsh: #{$!}"
    end

    def rollback
      raise "Not implemented"
    end

    private
    def configureAndMake
      logger.info("Configuring zsh")
      withDir(TMP_DIR_PATH) do
        runCmd('./configure', '--prefix', CONFIG.local, '--with-tcsetpgrp', showStdout: true)
        runCmd('make', '-j', '4')
        runCmd('make', 'install')
      end
      logger.info("Zsh installed successfully.")
    end

    private
    def setPath
      # Called explicitly in install method
      logger.info("Setting PATH to include #{CONFIG.bin}")
      # Set current environment's PATH
      paths = ENV['PATH'].to_s.split(':').reject do |path|
        path.empty? || path == CONFIG.bin
      end
      paths.unshift(CONFIG.bin)
      ENV['PATH'] = paths.join(':')
      logger.debug("Current PATH: #{ENV['PATH']}")

      # Sourcing bashrc in bash_profile
      addSourceBashrcInBashProfile

      # Set PATH on bashrc
      addLocalBinPathInBashrc
    end

    private
    def addLocalBinPathInBashrc
      time = Time.now.strftime('%Y%m%d%H%M%S')
      logger.debug("Backup existing .bashrc file to .bashrc.bak_#{time}")
      FileUtils.cp(CONFIG.bashrc, "#{CONFIG.bashrc}.bak_#{time}") if File.exist?(CONFIG.bashrc)

      contracted_bin_path = CONFIG.contract_path(CONFIG.bin)
      zsh_path_line = "export PATH=\"#{contracted_bin_path}:$PATH\""
      FileUtils.touch(CONFIG.bashrc) unless File.exist?(CONFIG.bashrc)
      bashrc_content = File.read(CONFIG.bashrc)

      escaped_config_bin = Regexp.escape(CONFIG.bin)
      if bashrc_content =~ /export\s+PATH=.*?(#{escaped_config_bin}|(\$HOME|\~)\/\.local\/bin)/
        logger.info("PATH already set in .bashrc, skipping")
      else
        logger.info("Adding PATH to .bashrc")
        File.open(CONFIG.bashrc, 'a') do |file|
          file.puts(zsh_path_line)
        end
      end
    end

    private
    def addSourceBashrcInBashProfile
      # Set bash_profile sourcing bashrc
      logger.debug("Setting up .bash_profile to source .bashrc on last")
      time = Time.now.strftime('%Y%m%d%H%M%S')
      FileUtils.touch(CONFIG.bash_profile) unless File.exist?(CONFIG.bash_profile)
      FileUtils.cp(CONFIG.bash_profile, "#{CONFIG.bash_profile}.bak_#{time}") if File.exist?(CONFIG.bash_profile)
      bash_profile_content = File.read(CONFIG.bash_profile)

      bash_profile_content.gsub!(/if\s+\[\s*-f\s+~?\/\.bashrc\s*\];\s*then\s*\n?\s*(\.|source)\s+~?\/\.bashrc\s*\n?fi\n?/, '')
      bash_profile_content.gsub!(/^\s*(\.|source)\s+~?\/?\.bashrc\s*\n?/, '')

      File.open(CONFIG.bash_profile, 'w') do |file|
        file.puts(bash_profile_content)
      end
      File.open(CONFIG.bash_profile, 'a') do |file|
        file.puts("if [ -f ~/.bashrc ]; then")
        file.puts("  . ~/.bashrc")
        file.puts("fi")
      end
    end
  end
end
