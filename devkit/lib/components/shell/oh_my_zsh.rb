require "fileutils"
require "components/installable_component"
require "components/configuration"
require "components/prerequisites/curl"
require "components/shell/zsh_binary"

module Component
  # Component for installing oh-my-zsh using curl
  class OhMyZshComponent < InstallableComponent

    DOWNLOAD_URL = "https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
    PLUGINS = ["git", "ruby", "python", "systemd", "docker", "pip", "command-not-found", "docker-compose"]

    depends_on Component::CurlComponent
    depends_on Component::ZshBinaryComponent

    # Checks if oh-my-zsh is installed.
    #
    # @return [Boolean] true if directory exists
    def installed?
      Dir.exist?(target_dir_path)
    end

    # Returns the current oh-my-zsh version (git commit hash).
    #
    # @return [String, nil] 7-digit commit hash or nil
    def version
      return nil unless available?

      Dir.chdir(target_dir_path) do
        output, status = Open3.capture2("git", "rev-parse", "--short=7", "HEAD")
        output.strip if status.success?
      end
    rescue StandardError => e
      logger.warn("Failed to get oh-my-zsh version: #{e.message}")
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
      logger.warn("Failed to get latest oh-my-zsh version: #{e.message}")
      nil
    end


    protected

    def pre_install
      logger.debug("Remove existing oh-my-zsh directory(#{target_dir_path}) if it exists")
      FileUtils.rm_rf(target_dir_path) if Dir.exist?(target_dir_path)
    end

    def perform_install
      logger.info("Installing oh-my-zsh")
      curl.download(DOWNLOAD_URL, tmp_script_path)
      File.chmod(0o755, tmp_script_path) if File.exist?(tmp_script_path)
      runCmd("sh", "-c", tmp_script_path, showStdout: true)
    rescue StandardError => e
      logger.error("Failed to install oh-my-zsh: #{e}")
      raise e
    ensure
      logger.debug("Cleaning up temporary files")
      FileUtils.rm_f(tmp_script_path) if File.exist?(tmp_script_path)
    end

    def post_install
      setPlugins
    end

    private

    # @return [String]
    def target_dir_path
      File.join(config.home, ".oh-my-zsh")
    end

    # @return [String]
    def tmp_script_path
      File.join(config.tmp, "install-oh-my-zsh.sh")
    end

    # @return [String]
    def zshrc_path
      File.join(config.home, ".zshrc")
    end

    def setPlugins
      unless File.exist?(zshrc_path)
        logger.error(".zshrc file not found")
        raise ".zshrc file not found"
      end

      zshrc_content = File.read(zshrc_path)

      plugins_string = "plugins=("
      PLUGINS.each do |plugin|
        plugins_string += "#{plugin} "
      end
      plugins_string = plugins_string[0..-2]
      plugins_string += ")"

      if zshrc_content.gsub!(/^[^#]*plugins=\([^)]*\)/m, "#{plugins_string}")
        logger.info("Updated plugins in .zshrc")
      else
        logger.warn("plugins=() not found in .zshrc")
        zshrc_content << "\n# oh-my-zsh plugins configuration\n#{plugins_string}\n"
      end

      File.write(zshrc_path, zshrc_content)
    end

  end
end
