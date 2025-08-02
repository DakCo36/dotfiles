require 'fileutils'
require_relative '../base'
require_relative '../configuration'
require_relative '../../mixins/installable'
require_relative '../../mixins/loggable'
require_relative '../fetch/git'

module Component
  class Powerlevel10kComponent < BaseComponent
    include Installable
    include Loggable

    CONFIG = Components::Configuration.instance
    REPO_URL = 'https://github.com/romkatv/powerlevel10k.git'
    THEME_DIR = File.join(CONFIG.home, '.oh-my-zsh/custom/themes/powerlevel10k')
    ZSHRC = File.join(CONFIG.home, '.zshrc')

    def initialize
      @git = Component::GitComponent.new
      @ohmyzsh = Component::OhMyZshComponent.new
    end

    def exists?
      Dir.exist?(THEME_DIR)
    end

    def installed?
      self.exists?
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
      if not @ohmyzsh.installed?
        logger.error('Oh My Zsh is not installed. Please install Oh My Zsh first.')
        raise 'Oh My Zsh is not installed. Please install Oh My Zsh first.'
      end
      FileUtils.mkdir_p(THEME_DIR) unless Dir.exist?(THEME_DIR)
      logger.info('Installing Powerlevel10k theme')
      @git.clone(REPO_URL, THEME_DIR)
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
