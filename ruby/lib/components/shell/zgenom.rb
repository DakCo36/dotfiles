require 'fileutils'
require 'components/base'
require 'components/configuration'
require 'mixins/installable'
require 'components/fetch/git'
require 'components/shell/zsh_binary'

module Component
  class ZgenomComponent < BaseComponent
    prepend Installable

    CONFIG = Components::Configuration.instance
    REPO_URL = "https://github.com/jandamm/zgenom.git"
    TARGET_DIR_PATH = File.join(CONFIG.home, '.zgenom')

    depends_on Component::GitComponent
    depends_on Component::ZshBinaryComponent

    def available?
      Dir.exist?(TARGET_DIR_PATH)
    end

    def installed?
      available?
      # TODO : Check if zgenom is properly configured in .zshrc
    end

    def install
      if installed?
        logger.info('Zgenom already installed.')
        return
      end
      install!
    end

    def install!
      FileUtils.rm_rf(TARGET_DIR_PATH) if Dir.exist?(TARGET_DIR_PATH)
      logger.info('Installing Zgenom...')
      FileUtils.mkdir_p(TARGET_DIR_PATH) unless Dir.exist?(TARGET_DIR_PATH)

      git.clone(REPO_URL, TARGET_DIR_PATH)
    rescue => e
      logger.error("Failed to install Zgenom: #{e}")
      raise e
    end

    def rollback
      raise NotImplementedError, 'Rollback not implemented for ZgenomComponent'
    end
  end
end
