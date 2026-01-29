require "fileutils"
require "components/base"
require "mixins/installable"
require "components/tools/git"
require "components/shell/zsh_binary"

module Component
  class ZgenomComponent < BaseComponent

    prepend Installable

    REPO_URL = "https://github.com/jandamm/zgenom.git"

    depends_on Component::GitComponent
    depends_on Component::ZshBinaryComponent

    # Checks if zgenom is installed.
    #
    # @return [Boolean] true if directory and zgenom.zsh file exist
    def available?
      Dir.exist?(target_dir_path) && File.exist?(File.join(target_dir_path, "zgenom.zsh"))
    end

    # Checks if zgenom is installed.
    #
    # @return [Boolean] true if installed, false otherwise
    def installed?
      available?
      # TODO : Check if zgenom is properly configured in .zshrc
    end

    # Returns the current zgenom version (git commit hash).
    #
    # @return [String, nil] 7-digit commit hash or nil
    def version
      return nil unless available?

      Dir.chdir(target_dir_path) do
        output, status = Open3.capture2("git", "rev-parse", "--short=7", "HEAD")
        output.strip if status.success?
      end
    rescue StandardError => e
      logger.warn("Failed to get zgenom version: #{e.message}")
      nil
    end

    # Returns the latest version (remote origin/main) commit hash.
    #
    # @return [String, nil] 7-digit commit hash or nil
    def latest_version
      return nil unless available?

      Dir.chdir(target_dir_path) do
        Open3.capture2("git", "fetch", "--quiet", "origin")
        output, status = Open3.capture2("git", "rev-parse", "--short=7", "origin/main")
        output.strip if status.success?
      end
    rescue StandardError => e
      logger.warn("Failed to get latest zgenom version: #{e.message}")
      nil
    end

    # Installs zgenom (skips if already installed).
    #
    # @return [void]
    def install
      if installed?
        logger.info("Zgenom already installed.")
        return
      end
      install!
      configure
    end

    # Force installs zgenom.
    #
    # @return [void]
    def install!
      FileUtils.rm_rf(target_dir_path) if Dir.exist?(target_dir_path)
      logger.info("Installing Zgenom...")
      FileUtils.mkdir_p(target_dir_path) unless Dir.exist?(target_dir_path)

      git.clone(REPO_URL, target_dir_path)
    rescue StandardError => e
      logger.error("Failed to install Zgenom: #{e}")
      raise e
    end

    def rollback
      raise NotImplementedError, "Rollback not implemented for ZgenomComponent"
    end

    private

    # @return [String]
    def target_dir_path
      File.join(config.home, ".zgenom")
    end

    # @return [String]
    def zshrc_path
      File.join(config.home, ".zshrc")
    end

    def configure
      disableOhMyZshPlugins
      setPlugins
    end

    def disableOhMyZshPlugins
      unless File.exist?(zshrc_path)
        logger.error(".zshrc file not found")
        raise ".zshrc file not found"
      end

      zshrc_content = File.read(zshrc_path)

      logger.info("Disabling oh-my-zsh plugins") if zshrc_content.gsub!(/^(\s*plugins=\([^)]*\))/m, '# \1')

      if zshrc_content.gsub!(%r{^(\s*source \$ZSH/oh-my-zsh.sh)}m, '# \1')
        logger.info("Disabling source oh-my-zsh script")
      end

      File.write(zshrc_path, zshrc_content)
    end

    def setPlugins
      unless File.exist?(zshrc_path)
        logger.error(".zshrc file not found")
        raise ".zshrc file not found"
      end

      zshrc_content = File.read(zshrc_path)

      # zgenom autoupdate
      zgenom_config = ""
      if zshrc_content.match?(/zgenom autoupdate/)
        logger.debug("zgenom update already exists in .zshrc, skipping")
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
          #{"  "}
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
            zgenom load Aloxaf/fzf-tab#{" "}
          #{"  "}
            # Save and compile .zshrc
            zgenom save
            zgenom compile "$HOME/.zshrc"
          fi
        CONFIG
      end

      zshrc_content << zgenom_config
      File.write(zshrc_path, zshrc_content)
    end

  end
end
