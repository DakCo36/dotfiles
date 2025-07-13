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
    DIRNAME = "zsh-#{VERSION}"
    FILENAME = "zsh-#{VERSION}.tar.xz"
    FILEPATH = CONFIG.tmp + File::SEPARATOR + FILENAME
    DIRPATH = CONFIG.tmp + File::SEPARATOR + DIRNAME
    DOWNLOAD_URL = "https://sourceforge.net/projects/zsh/files/zsh/#{VERSION}/#{FILENAME}/download"
    def initialize
      @curl = Component::CurlComponent.new
    end

    def exists?
      runCmd('command', '-v', 'zsh')
    end

    def installed?
      runCmd('command', '-v', 'zsh')
    end

    def version
      out = runCmdWithOutput('zsh', '--version')
      out.split(' ')[1] # example zsh 5.8 (x86_64-pc-linux-musl)
    end

    def install
      if installed?
        logger.info("Zsh is already installed.")
        return
      end

      logger.info("Installing zsh version #{VERSION}")
      @curl.download(DOWNLOAD_URL, FILEPATH)
      logger.info("Unzip #{FILEPATH} to #{DIRPATH}")
      runCmd('tar', '-xf', FILEPATH, '-C', File.dirname(FILEPATH))
      configureAndInstall()
    end

    def rollback
      raise "Not implemented"
    end

    private
    def configureAndInstall
      logger.info("Configuring zsh")
      withDir(DIRPATH) do
        runCmd('./configure', '--prefix', CONFIG.local, showStdout: true)
        runCmd('make', '-j', '4')
        runCmd('make', 'install')
      end
    end
  end
end
