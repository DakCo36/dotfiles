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
      @curl.download(DOWNLOAD_URL, FILEPATH)
      logger.info("Unzip #{FILEPATH} to #{DIRPATH}")
      runCmd('tar', '-xf', FILEPATH, '-C', File.dirname(FILEPATH))
      configureAndInstall()
    end

    def rollback
      FileUtils.rm_f(File.expand_path('~/.local/bin/zsh'))
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
