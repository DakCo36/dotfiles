require 'fileutils'
require_relative '../base'
require_relative '../configuration'
require_relative '../../mixins/installable'
require_relative '../../mixins/loggable'
require_relative '../fetch/curl'

module Component
  class ZshComponent < BaseComponent
    include Installable
    include Loggable

    CONFIG = Components::Configuration.instance
    VERSION="5.9"
    DOWNLOAD_URL = "https://sourceforge.net/projects/zsh/files/zsh/#{VERSION}/zsh-#{VERSION}.tar.xz/download"

    def initialize
      @curl = Component::CurlComponent.new
    end
    
    def installed?
      system('command', '-v', 'zsh', out: File::NULL, err: File::NULL)
      $?.success?
    end

    def version
      system('zsh', '--version', out: File::NULL, err: File::NULL)
      if not $?.success?
        return nil
      end
      output = `zsh --version 2>&1`
      output.split(' ')[1] # example zsh 5.8 (x86_64-pc-linux-musl)
    end

    def install
      if installed?
        logger.info("Zsh is already installed.")
      end

      logger.info("Installing zsh version #{VERSION}")

      download
    end

    def rollback
      FileUtils.rm_f(File.expand_path('~/.local/bin/zsh'))
    end

    private
    def download
      destination = CONFIG.tmp + '/' + "zsh-#{VERSION}.tar.xz"
      logger.info("Downloading zsh zip file to #{destination}")
      @curl.download(DOWNLOAD_URL, destination)
    end
  end
end
