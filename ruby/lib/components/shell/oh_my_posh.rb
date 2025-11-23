require 'fileutils'
require 'components/base'
require 'components/configuration'
require 'mixins/installable'
require 'components/fetch/curl'

module Component
  class OhMyPoshComponent < BaseComponent
    prepend Installable

    CONFIG = Components::Configuration.instance

    DOWNLOAD_URL = 'https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64'
    TMP_BINARY_PATH = File.join(CONFIG.tmp, 'oh-my-posh')
    BINARY_PATH = File.join(CONFIG.bin, 'oh-my-posh')

    THEMES_DIR = File.join(CONFIG.home, '.poshthemes')
    DEFAULT_THEME_SOURCE = File.join(DATA_ROOT, 'oh_my_posh', 'default.omp.json')
    DEFAULT_THEME_PATH = File.join(THEMES_DIR, 'default.omp.json')

    depends_on Component::CurlComponent

    def available?
      File.exist?(BINARY_PATH) && File.executable?(BINARY_PATH)
    end

    def installed?
      available? && File.exist?(DEFAULT_THEME_PATH)
    end

    def install
      if installed?
        logger.info('Oh My Posh already installed.')
        return
      end

      install!
    end

    def install!
      logger.info('Installing Oh My Posh for Linux shells')
      FileUtils.mkdir_p(CONFIG.bin) unless Dir.exist?(CONFIG.bin)

      download_binary
      install_theme
    rescue => e
      logger.error("Failed to install Oh My Posh: #{e}")
      raise e
    ensure
      cleanup_tmp_binary
    end

    private

    def download_binary
      curl.download(DOWNLOAD_URL, TMP_BINARY_PATH)
      FileUtils.mv(TMP_BINARY_PATH, BINARY_PATH)
      FileUtils.chmod(0o755, BINARY_PATH)
    end

    def install_theme
      unless File.exist?(DEFAULT_THEME_SOURCE)
        raise "Default theme not found at #{DEFAULT_THEME_SOURCE}"
      end

      FileUtils.mkdir_p(THEMES_DIR) unless Dir.exist?(THEMES_DIR)
      FileUtils.cp(DEFAULT_THEME_SOURCE, DEFAULT_THEME_PATH)
    end

    def cleanup_tmp_binary
      FileUtils.rm_f(TMP_BINARY_PATH) if File.exist?(TMP_BINARY_PATH)
    end
  end
end
