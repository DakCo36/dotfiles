require 'fileutils'
require 'components/base'
require 'components/configuration'
require 'mixins/installable'
require 'components/fetch/curl'
require 'components/shell/zsh_binary'

module Component
  # Component for installing oh-my-zsh using curl
  class OhMyZshComponent < BaseComponent
    prepend Installable

    CONFIG = Components::Configuration.instance
    DOWNLOAD_URL = 'https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh'
    
    TARGET_DIR_PATH = File.join(CONFIG.home, '.oh-my-zsh')
    TMP_SCRIPT_PATH = File.join(CONFIG.tmp, 'install-oh-my-zsh.sh')

    ZSHRC = File.join(CONFIG.home, '.zshrc')
    PLUGINS = ['git', 'ruby', 'python', 'systemd', 'docker', 'pip', 'command-not-found', 'docker-compose']

    depends_on Component::CurlComponent
    depends_on Component::ZshBinaryComponent

    def available?
      Dir.exist?(TARGET_DIR_PATH)
    end

    def installed?
      available?
    end

    def install
      if installed?
        logger.info('oh-my-zsh already installed.')
        return
      end
      install!
    end

    def install!
      logger.debug("Remove existing oh-my-zsh directory(#{TARGET_DIR_PATH}) if it exists")
      FileUtils.rm_rf(TARGET_DIR_PATH) if Dir.exist?(TARGET_DIR_PATH)
      logger.info('Installing oh-my-zsh')
      curl.download(DOWNLOAD_URL, TMP_SCRIPT_PATH)
      File.chmod(0755, TMP_SCRIPT_PATH) if File.exist?(TMP_SCRIPT_PATH)
      runCmd('sh', '-c', TMP_SCRIPT_PATH, showStdout: true)
      configure
    rescue => e
      logger.error("Failed to install oh-my-zsh: #{e}")
      raise e
    ensure
      logger.debug('Cleaning up temporary files')
      FileUtils.rm_f(TMP_SCRIPT_PATH) if File.exist?(TMP_SCRIPT_PATH)
    end

    private
    def configure
      setPlugins
    end

    private
    def setPlugins
      if !File.exist?(ZSHRC)
        logger.error(".zshrc file not found")
        raise ".zshrc file not found"
      end

      zshrc_content = File.read(ZSHRC)
      
      plugins_string = "plugins=("
      PLUGINS.each do |plugin|
        plugins_string += " #{plugin}"
      end
      plugins_string += ")"

      if zshrc_content.gsub!(/^[^#]*plugins=\([^)]*\)/m, "#{plugins_string}")
        logger.info("Updated plugins in .zshrc")
      else
        logger.warn("plugins=() not found in .zshrc")
        zshrc_content << "\n# oh-my-zsh plugins configuration\n#{plugins_string}\n"
      end

      File.open(ZSHRC, 'w') do |file|
        file.write(zshrc_content)
      end
    end

  end
end
