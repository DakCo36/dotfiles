require "fileutils"
require "components/base"
require "mixins/installable"
require "components/tools/curl"
require "components/shell/zsh_binary"

module Component
  # Component for installing oh-my-zsh using curl
  class OhMyZshComponent < BaseComponent

    prepend Installable

    DOWNLOAD_URL = "https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
    PLUGINS = ["git", "ruby", "python", "systemd", "docker", "pip", "command-not-found", "docker-compose"]

    depends_on Component::CurlComponent
    depends_on Component::ZshBinaryComponent

    # oh-my-zsh가 설치되어 있는지 확인합니다.
    #
    # @return [Boolean] 디렉토리가 존재하면 true, 아니면 false
    def available?
      Dir.exist?(target_dir_path)
    end

    # oh-my-zsh 설치 여부를 확인합니다.
    #
    # @return [Boolean] 설치되어 있으면 true, 아니면 false
    def installed?
      available?
    end

    # 현재 설치된 oh-my-zsh 버전 (git commit hash)을 반환합니다.
    #
    # @return [String, nil] 7자리 commit hash 또는 nil
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

    # 최신 버전 (remote origin/master)의 commit hash를 반환합니다.
    #
    # @return [String, nil] 7자리 commit hash 또는 nil
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

    # oh-my-zsh를 설치합니다 (이미 설치되어 있으면 스킵).
    #
    # @return [void]
    def install
      if installed?
        logger.info("oh-my-zsh already installed.")
        return
      end
      install!
    end

    # oh-my-zsh를 강제로 설치합니다.
    #
    # @return [void]
    def install!
      logger.debug("Remove existing oh-my-zsh directory(#{target_dir_path}) if it exists")
      FileUtils.rm_rf(target_dir_path) if Dir.exist?(target_dir_path)
      logger.info("Installing oh-my-zsh")
      curl.download(DOWNLOAD_URL, tmp_script_path)
      File.chmod(0o755, tmp_script_path) if File.exist?(tmp_script_path)
      runCmd("sh", "-c", tmp_script_path, showStdout: true)
      configure
    rescue StandardError => e
      logger.error("Failed to install oh-my-zsh: #{e}")
      raise e
    ensure
      logger.debug("Cleaning up temporary files")
      FileUtils.rm_f(tmp_script_path) if File.exist?(tmp_script_path)
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

    def configure
      setPlugins
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
      plugins_string = plugins_string[0..-2] # Remove last space
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
