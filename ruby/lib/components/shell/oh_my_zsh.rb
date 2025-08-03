require 'fileutils'
require_relative '../base'
require_relative '../configuration'
require_relative '../../mixins/installable'
require_relative '../fetch/curl'

module Component
  # Component for installing oh-my-zsh using curl
  class OhMyZshComponent < BaseComponent
    include Installable

    CONFIG = Components::Configuration.instance
    DOWNLOAD_URL = 'https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh'
    
    TARGET_DIR_PATH = File.join(CONFIG.home, '.oh-my-zsh')
    TMP_SCRIPT_PATH = File.join(CONFIG.tmp, 'install-oh-my-zsh.sh')

    depends_on Component::CurlComponent

    private_constant :DOWNLOAD_URL, :TARGET_DIR_PATH, :TMP_SCRIPT_PATH

    def available?
      Dir.exist?(TARGET_DIR_PATH)
    end

    def installed?
      available?
      # TODO: Check if oh-my-zsh is installed with correct version or configuration
    end

    def install
      if installed?
        logger.info('oh-my-zsh already installed.')
        return
      end
      install!
    end

    def install!
      FileUtils.rm_rf(TARGET_DIR_PATH) if Dir.exist?(TARGET_DIR_PATH)
      logger.info('Installing oh-my-zsh')
      curl.download(DOWNLOAD_URL, TARGET_DIR_PATH)
      runCmd('sh', TMP_SCRIPT_PATH, showStdout: true)
    rescue => e
      logger.error("Failed to install oh-my-zsh: #{e}")
      raise e
    ensure
      FileUtils.rm_f(TMP_SCRIPT_PATH) if File.exist?(TMP_SCRIPT_PATH)
    end
  end
end
