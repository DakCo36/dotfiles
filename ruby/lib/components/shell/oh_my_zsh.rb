require 'fileutils'
require 'components/base'
require 'components/configuration'
require 'mixins/installable'
require 'components/fetch/curl'
require 'components/shell/zsh_binary'

module Component
  # Component for installing oh-my-zsh using curl
  class OhMyZshComponent < BaseComponent
    prepend Installable

    CONFIG = Components::Configuration.instance
    DOWNLOAD_URL = 'https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh'
    
    TARGET_DIR_PATH = File.join(CONFIG.home, '.oh-my-zsh')
    TMP_SCRIPT_PATH = File.join(CONFIG.tmp, 'install-oh-my-zsh.sh')

    depends_on Component::CurlComponent
    depends_on Component::ZshBinaryComponent

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
      logger.debug("Remove existing oh-my-zsh directory(#{TARGET_DIR_PATH}) if it exists")
      FileUtils.rm_rf(TARGET_DIR_PATH) if Dir.exist?(TARGET_DIR_PATH)
      logger.info('Installing oh-my-zsh')
      curl.download(DOWNLOAD_URL, TMP_SCRIPT_PATH)
      File.chmod(0755, TMP_SCRIPT_PATH) if File.exist?(TMP_SCRIPT_PATH)
      runCmd('sh', '-c', TMP_SCRIPT_PATH, showStdout: true)
    rescue => e
      logger.error("Failed to install oh-my-zsh: #{e}")
      raise e
    ensure
      logger.debug('Cleaning up temporary files')
      FileUtils.rm_f(TMP_SCRIPT_PATH) if File.exist?(TMP_SCRIPT_PATH)
    end
  end
end
