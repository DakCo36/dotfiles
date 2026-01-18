require "fileutils"
require "components/base"
require "components/configuration"
require "mixins/installable"
require "components/tools/curl"
require "components/shell/zsh_binary"

module Component
  # Component for installing oh-my-zsh using curl
  class OhMyZshComponent < BaseComponent

    prepend Installable

    CONFIG = Components::Configuration.instance
    DOWNLOAD_URL = "https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh"

    TARGET_DIR_PATH = File.join(CONFIG.home, ".oh-my-zsh")
    TMP_SCRIPT_PATH = File.join(CONFIG.tmp, "install-oh-my-zsh.sh")

    ZSHRC = File.join(CONFIG.home, ".zshrc")
    PLUGINS = ["git", "ruby", "python", "systemd", "docker", "pip", "command-not-found", "docker-compose"]

    depends_on Component::CurlComponent
    depends_on Component::ZshBinaryComponent

    def available?
      Dir.exist?(TARGET_DIR_PATH)
    end

    def installed?
      available?
    end

    def version
      return nil unless available?

      Dir.chdir(TARGET_DIR_PATH) do
        output, status = Open3.capture2("git", "rev-parse", "--short=7", "HEAD")
        output.strip if status.success?
      end
    rescue StandardError => e
      logger.warn("Failed to get oh-my-zsh version: #{e.message}")
      nil
    end

    def latest_version
      return nil unless available?

      Dir.chdir(TARGET_DIR_PATH) do
        Open3.capture2("git", "fetch", "--quiet", "origin")
        output, status = Open3.capture2("git", "rev-parse", "--short=7", "origin/master")
        output.strip if status.success?
      end
    rescue StandardError => e
      logger.warn("Failed to get latest oh-my-zsh version: #{e.message}")
      nil
    end

    def install
      if installed?
        logger.info("oh-my-zsh already installed.")
        return
      end
      install!
    end

    def install!
      logger.debug("Remove existing oh-my-zsh directory(#{TARGET_DIR_PATH}) if it exists")
      FileUtils.rm_rf(TARGET_DIR_PATH) if Dir.exist?(TARGET_DIR_PATH)
      logger.info("Installing oh-my-zsh")
      curl.download(DOWNLOAD_URL, TMP_SCRIPT_PATH)
      File.chmod(0o755, TMP_SCRIPT_PATH) if File.exist?(TMP_SCRIPT_PATH)
      runCmd("sh", "-c", TMP_SCRIPT_PATH, showStdout: true)
      configure
    rescue StandardError => e
      logger.error("Failed to install oh-my-zsh: #{e}")
      raise e
    ensure
      logger.debug("Cleaning up temporary files")
      FileUtils.rm_f(TMP_SCRIPT_PATH) if File.exist?(TMP_SCRIPT_PATH)
    end

    private

    def configure
      setPlugins
    end

    def setPlugins
      unless File.exist?(ZSHRC)
        logger.error(".zshrc file not found")
        raise ".zshrc file not found"
      end

      zshrc_content = File.read(ZSHRC)

      plugins_string = "plugins=("
      PLUGINS.each do |plugin|
        plugins_string += "#{plugin} "
      end
      plugins_string = plugins_string[0..-2] # Remove last space
      plugins_string += ")"

      if zshrc_content.gsub!(/^[^#]*plugins=\([^)]*\)/m, "#{plugins_string}")
        logger.info("Updated plugins in .zshrc")
      else
        logger.warn("plugins=() not found in .zshrc")
        zshrc_content << "\n# oh-my-zsh plugins configuration\n#{plugins_string}\n"
      end

      File.write(ZSHRC, zshrc_content)
    end

  end
end
