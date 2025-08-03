require 'fileutils'
require 'components/base'
require 'components/configuration'
require 'mixins/installable'
require 'components/fetch/git'
require 'components/shell/oh_my_zsh'

module Component
  class Powerlevel10kComponent < BaseComponent
    include Installable

    CONFIG = Components::Configuration.instance
    REPO_URL = 'https://github.com/romkatv/powerlevel10k.git'
    TARGET_DIR_PATH = File.join(CONFIG.home, '.oh-my-zsh/custom/themes/powerlevel10k')
    ZSHRC = File.join(CONFIG.home, '.zshrc')

    depends_on Component::GitComponent
    depends_on Component::OhMyZshComponent

    def available?
      Dir.exist?(TARGET_DIR_PATH)
    end

    def installed?
      available?
      # TODO: Check if the theme is properly configured in .zshrc
    end

    def install
      if installed?
        logger.info('Powerlevel10k already installed.')
        return
      end

      install!
    end

    def install!
      logger.debug("Check oh-my-zsh installation, #{File.join(CONFIG.home, '.oh-my-zsh')}")
      if not oh_my_zsh.installed?
        logger.error('Oh My Zsh is not installed. Please install Oh My Zsh first.')
        raise 'Oh My Zsh is not installed. Please install Oh My Zsh first.'
      end
      FileUtils.mkdir_p(TARGET_DIR_PATH) unless Dir.exist?(TARGET_DIR_PATH)
      logger.info('Installing Powerlevel10k theme')
      git.clone(REPO_URL, TARGET_DIR_PATH)
      # TODO: COPY .zshrc & .p10k.zsh files in here or not
    rescue => e
      logger.error("Failed to install Powerlevel10k: #{e}")
      raise e
    end

    def rollback
      raise NotImplementedError, 'Rollback not implemented for Powerlevel10kComponent'
    end
  end
end
