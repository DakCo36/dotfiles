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

    # zgenom이 설치되어 있는지 확인합니다.
    #
    # @return [Boolean] 디렉토리와 zgenom.zsh 파일이 존재하면 true
    def available?
      Dir.exist?(target_dir_path) && File.exist?(File.join(target_dir_path, "zgenom.zsh"))
    end

    # zgenom 설치 여부를 확인합니다.
    #
    # @return [Boolean] 설치되어 있으면 true, 아니면 false
    def installed?
      available?
      # TODO : Check if zgenom is properly configured in .zshrc
    end

    # 현재 설치된 zgenom 버전 (git commit hash)을 반환합니다.
    #
    # @return [String, nil] 7자리 commit hash 또는 nil
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

    # 최신 버전 (remote origin/main)의 commit hash를 반환합니다.
    #
    # @return [String, nil] 7자리 commit hash 또는 nil
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

    # zgenom을 설치합니다 (이미 설치되어 있으면 스킵).
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

    # zgenom을 강제로 설치합니다.
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
