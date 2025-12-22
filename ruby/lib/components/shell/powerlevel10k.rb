require 'fileutils'
require 'components/base'
require 'components/configuration'
require 'mixins/installable'
require 'components/fetch/git'
require 'components/shell/oh_my_zsh'

module Component
  class Powerlevel10kComponent < BaseComponent
    prepend Installable

    CONFIG = Components::Configuration.instance
    REPO_URL = 'https://github.com/romkatv/powerlevel10k.git'
    TARGET_DIR_PATH = File.join(CONFIG.home, '.oh-my-zsh/custom/themes/powerlevel10k')
    ZSHRC = File.join(CONFIG.home, '.zshrc')
    CONFIG_DIR = File.join(DATA_ROOT, 'p10k')

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
      FileUtils.rm_rf(TARGET_DIR_PATH) if Dir.exist?(TARGET_DIR_PATH)
      FileUtils.mkdir_p(TARGET_DIR_PATH) unless Dir.exist?(TARGET_DIR_PATH)
      logger.info('Installing Powerlevel10k theme')
      git.clone(REPO_URL, TARGET_DIR_PATH)
      configure
    rescue => e
      logger.error("Failed to install Powerlevel10k: #{e}")
      raise e
    end

    private
    def configure
      setTheme()
      setConfig()
    end

    private 
    def setTheme
      # Set zsh theme to powerlevel10k
      if (!File.exist?(ZSHRC))
        logger.error(".zshrc file not found")
        raise ".zshrc file not found"
      end

      zshrc_content = File.read(ZSHRC)
      if zshrc_content.gsub!(/^ZSH_THEME=.*$/, 'ZSH_THEME="powerlevel10k/powerlevel10k"')
        logger.info("Updated ZSH_THEME to powerlevel10k")
      else
        logger.warn("ZSH_THEME not found in .zshrc, adding at the end")
        zshrc_content << "\nZSH_THEME=\"powerlevel10k/powerlevel10k\"\n"
      end

      if zshrc_content.match?(/source.*\.p10k\.zsh/)
        logger.info("source .p10k.zsh already exists in .zshrc, skipping")
      else
        logger.info("Adding source .p10k.zsh to .zshrc")
        zshrc_content << "\n[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh\n"
      end

      File.open(ZSHRC, 'w') do |file|
        file.write(zshrc_content)
      end
    end

    private 
    def setConfig
      # TODO: Make it configurable if want to support multiple configurations
      sourceFile = File.join(CONFIG_DIR, 'simple.zsh')
      destFile = File.join(CONFIG.home, '.p10k.zsh')

      if (!File.exist?(sourceFile)) 
        logger.error("Config file #{sourceFile} not found")
        raise "Config file #{sourceFile} not found"
      end

      if (File.exist?(destFile))
        logger.info("Backup #{destFile} to #{destFile}.backup_#{Time.now.strftime('%Y%m%d%H%M%S')}")
        FileUtils.cp(destFile, "#{destFile}.backup_#{Time.now.strftime('%Y%m%d%H%M%S')}")
      end

      logger.info("Copying #{sourceFile} to #{destFile}")
      FileUtils.cp(sourceFile, destFile)
    end

    def rollback
      raise NotImplementedError, 'Rollback not implemented for Powerlevel10kComponent'
    end
  end
end
