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
    TARGET_PATH = File.join(CONFIG.local, 'bin')

    BASHRC_PATH = File.join(CONFIG.home, '.bashrc')
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
      available?
      # TODO: Check zsh is installed with correct version
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
        runCmd('./configure', '--prefix', CONFIG.local, showStdout: true)
        runCmd('make', '-j', '4')
        runCmd('make', 'install')
      end
      logger.info("Zsh installed successfully.")
    end

    def setPath
      logger.info("Setting PATH to include #{TARGET_PATH}")
      # Set current environment's PATH
      paths = ENV['PATH'].to_s.split(':').reject do |path|
        path.empty? || path == TARGET_PATH
      end
      paths.unshift(TARGET_PATH)
      ENV['PATH'] = paths.join(':')
      logger.debug("Current PATH: #{ENV['PATH']}")

      # Set PATH on bashrc
      time = Time.now.strftime('%Y%m%d%H%M%S')
      logger.debug("Backup existing .bashrc file to .bashrc.bak_#{time}")
      FileUtils.cp(BASHRC_PATH, "#{BASHRC_PATH}.bak_#{time}") if File.exist?(BASHRC_PATH)

      zsh_path_line = "export PATH=\"#{TARGET_PATH}:$PATH\""
      FileUtils.touch(BASHRC_PATH) unless File.exist?(BASHRC_PATH)
      bashrc_content = File.read(BASHRC_PATH)

      if bashrc_content =~ /export\s+PATH=.*(\$HOME|\~)\/\.local\/bin/
        logger.info("PATH already set in .bashrc, skipping")
      else
        logger.info("Adding PATH to .bashrc")
        File.open(BASHRC_PATH, 'a') do |file|
          file.puts(zsh_path_line)
        end
      end
    end
  end
end
