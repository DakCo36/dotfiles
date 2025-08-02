require 'fileutils'
require_relative '../base'
require_relative '../configuration'
require_relative '../../mixins/installable'
require_relative '../../mixins/loggable'
require_relative '../fetch/curl'

module Component
  # Component for installing oh-my-zsh using curl
  class OhMyZshComponent < BaseComponent
    include Installable
    include Loggable

    CONFIG = Components::Configuration.instance
    DOWNLOAD_URL = 'https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh'
    DIRPATH = File.join(CONFIG.home, '.oh-my-zsh')
    SCRIPT_PATH = File.join(CONFIG.tmp, 'install-oh-my-zsh.sh')

    def initialize
      @curl = Component::CurlComponent.new
    end

    def exists?
      installed?
    end

    def installed?
      Dir.exist?(DIRPATH)
    end

    def install
      if installed?
        logger.info('oh-my-zsh already installed.')
        return
      end
      install!
    end

    def install!
      FileUtils.rm_rf(DIRPATH) if Dir.exist?(DIRPATH)
      logger.info('Installing oh-my-zsh')
      @curl.download(DOWNLOAD_URL, SCRIPT_PATH)
      runCmd('sh', SCRIPT_PATH, showStdout: true)
    rescue => e
      logger.error("Failed to install oh-my-zsh: #{e}")
      raise e
    ensure
      FileUtils.rm_f(SCRIPT_PATH) if File.exist?(SCRIPT_PATH)
    end

    def rollback
      FileUtils.rm_rf(DIRPATH)
    end
  end
end
