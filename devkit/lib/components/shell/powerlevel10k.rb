require "fileutils"
require "components/installable_component"
require "components/configuration"
require "components/tools/git"
require "components/shell/oh_my_zsh"

module Component
  class Powerlevel10kComponent < InstallableComponent

    REPO_URL = "https://github.com/romkatv/powerlevel10k.git"
    CONFIG_DIR = File.join(RESOURCES_ROOT, "p10k")

    # Instant prompt block to be added at the top of .zshrc
    INSTANT_PROMPT_BLOCK = <<~ZSH
      # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
      # Initialization code that may require console input (password prompts, [y/n]
      # confirmations, etc.) must go above this block; everything else may go below.
      if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
          source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
      fi
    ZSH

    depends_on Component::GitComponent
    depends_on Component::OhMyZshComponent

    # Checks if powerlevel10k is installed.
    #
    # @return [Boolean] true if directory exists, false otherwise
    def available?
      Dir.exist?(target_dir_path)
    end

    # Checks if powerlevel10k is installed.
    #
    # @return [Boolean] true if installed, false otherwise
    def installed?
      available?
      # TODO: Check if the theme is properly configured in .zshrc
    end

    # Returns the current powerlevel10k version (git commit hash).
    #
    # @return [String, nil] 7-digit commit hash or nil
    def version
      return nil unless available?

      Dir.chdir(target_dir_path) do
        output, status = Open3.capture2("git", "rev-parse", "--short=7", "HEAD")
        output.strip if status.success?
      end
    rescue StandardError => e
      logger.warn("Failed to get powerlevel10k version: #{e.message}")
      nil
    end

    # Returns the latest version (remote origin/master) commit hash.
    #
    # @return [String, nil] 7-digit commit hash or nil
    def latest_version
      return nil unless available?

      Dir.chdir(target_dir_path) do
        Open3.capture2("git", "fetch", "--quiet", "origin")
        output, status = Open3.capture2("git", "rev-parse", "--short=7", "origin/master")
        output.strip if status.success?
      end
    rescue StandardError => e
      logger.warn("Failed to get latest powerlevel10k version: #{e.message}")
      nil
    end

    # Installs powerlevel10k (skips if already installed).
    #
    # @return [void]
    def install
      if installed?
        logger.info("Powerlevel10k already installed.")
        return
      end

      install!
    end

    # Force installs powerlevel10k.
    #
    # @return [void]
    def install!
      FileUtils.rm_rf(target_dir_path) if Dir.exist?(target_dir_path)
      FileUtils.mkdir_p(target_dir_path) unless Dir.exist?(target_dir_path)
      logger.info("Installing Powerlevel10k theme")
      git.clone(REPO_URL, target_dir_path)
      configure
    rescue StandardError => e
      logger.error("Failed to install Powerlevel10k: #{e}")
      raise e
    end

    private

    # @return [String]
    def target_dir_path
      File.join(config.home, ".oh-my-zsh/custom/themes/powerlevel10k")
    end

    # @return [String]
    def zshrc_path
      File.join(config.home, ".zshrc")
    end

    def configure
      setInstantPrompt
      setTheme
      setConfig
    end

    def setInstantPrompt
      unless File.exist?(zshrc_path)
        logger.error(".zshrc file not found")
        raise ".zshrc file not found"
      end

      zshrc_content = File.read(zshrc_path)

      if zshrc_content.match?(/# Enable Powerlevel10k instant prompt/)
        logger.info("Instant prompt already exists in .zshrc, skipping")
        return
      end

      logger.info("Adding instant prompt to the top of .zshrc")
      new_content = INSTANT_PROMPT_BLOCK + "\n" + zshrc_content

      File.write(zshrc_path, new_content)
    end

    def setTheme
      unless File.exist?(zshrc_path)
        logger.error(".zshrc file not found")
        raise ".zshrc file not found"
      end

      zshrc_content = File.read(zshrc_path)
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

      File.write(zshrc_path, zshrc_content)
    end

    def setConfig
      # TODO: Make it configurable if want to support multiple configurations
      sourceFile = File.join(CONFIG_DIR, "simple.zsh")
      destFile = File.join(config.home, ".p10k.zsh")

      unless File.exist?(sourceFile)
        logger.error("Config file #{sourceFile} not found")
        raise "Config file #{sourceFile} not found"
      end

      if File.exist?(destFile)
        logger.info("Backup #{destFile} to #{destFile}.backup_#{Time.now.strftime("%Y%m%d%H%M%S")}")
        FileUtils.cp(destFile, "#{destFile}.backup_#{Time.now.strftime("%Y%m%d%H%M%S")}")
      end

      logger.info("Copying #{sourceFile} to #{destFile}")
      FileUtils.cp(sourceFile, destFile)
    end

    def rollback
      raise NotImplementedError, "Rollback not implemented for Powerlevel10kComponent"
    end

  end
end
