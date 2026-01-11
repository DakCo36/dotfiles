require 'fileutils'
require 'components/base'
require 'components/configuration'
require 'mixins/installable'
require 'components/tools/git'
require 'components/shell/zsh_binary'

module Component
  class ZgenomComponent < BaseComponent
    prepend Installable

    CONFIG = Components::Configuration.instance
    REPO_URL = "https://github.com/jandamm/zgenom.git"
    TARGET_DIR_PATH = File.join(CONFIG.home, '.zgenom')

    ZSHRC = File.join(CONFIG.home, '.zshrc') # FIXME Get from ZshBinaryComponent

    depends_on Component::GitComponent
    depends_on Component::ZshBinaryComponent

    def available?
      Dir.exist?(TARGET_DIR_PATH) && File.exist?(File.join(TARGET_DIR_PATH, 'zgenom.zsh'))
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
      configure()
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

    private
    def configure
      disableOhMyZshPlugins
      setPlugins
    end

    private
    def disableOhMyZshPlugins
      if !File.exist?(ZSHRC)
        logger.error(".zshrc file not found")
        raise ".zshrc file not found"
      end

      zshrc_content = File.read(ZSHRC)

      # FIXME possibly distroy .zshrc
      # if zshrc_content.gsub!(/^(\s*plugins=\([^)]*\)\s*)$/, '# \1')
      if zshrc_content.gsub!(/^(\s*plugins=\([^)]*\))/m, '# \1')
        logger.info("Disabling oh-my-zsh plugins")
      end

      # FIXME possibly distroy .zshrc
      #   if zshrc_content.gsub!(/^(\s*source \$ZSH\/oh-my-zsh.sh)$/, '# \1')
      if zshrc_content.gsub!(/^(\s*source \$ZSH\/oh-my-zsh.sh)/m, '# \1')
        logger.info("Disabling source oh-my-zsh script")
      end

      File.open(ZSHRC, 'w') do |file|
        file.write(zshrc_content)
      end
    end

    private
    def setPlugins
      if !File.exist?(ZSHRC)
        logger.error(".zshrc file not found")
        raise ".zshrc file not found"
      end

      zshrc_content = File.read(ZSHRC)

      # zgenom autoupdate
      zgenom_config = ""
      if zshrc_content.match?(/zgenom autoupdate/)
        logger.debug("zgenom update already exists in .zshrc, skipping")
        # Assume already zgenom plugins are set-up
        return
      else
        logger.info("Adding zgenom autoupdate to .zshrc")
        zgenom_config = <<~CONFIG

          ### Zgenom ###
          source "${HOME}/.zgenom/zgenom.zsh" > /dev/null

          zgenom autoupdate

          if ! zgenom saved; then
            # load oh-my-zsh plugins
            zgenom oh-my-zsh
            zgenom oh-my-zsh plugins/git
            zgenom oh-my-zsh plugins/python
            zgenom oh-my-zsh plugins/systemd
            zgenom oh-my-zsh plugins/docker
            zgenom oh-my-zsh plugins/pip
            zgenom oh-my-zsh plugins/vi-mode
            zgenom oh-my-zsh plugins/command-not-found
            zgenom oh-my-zsh plugins/docker-compose
            zgenom oh-my-zsh plugins/kubectl
            
            # load zsh-users plugins
            zgenom load zsh-users/zsh-syntax-highlighting
            zgenom load zsh-users/zsh-history-substring-search
            zgenom load zsh-users/zsh-autosuggestions
            zgenom load zsh-users/zsh-completions

            # load zsh-autoswitch-virtualenv
            zgenom load MichaelAquilina/zsh-autoswitch-virtualenv

            # load nvm
            zgenom load lukechilds/zsh-nvm

            # load fzf-tab
            zgenom load Aloxaf/fzf-tab 
            
            # Save and compile .zshrc
            zgenom save
            zgenom compile "$HOME/.zshrc"
          fi
        CONFIG
      end

      zshrc_content << zgenom_config
      File.open(ZSHRC, 'w') do |file|
        file.write(zshrc_content)
      end
    end
  end
end
