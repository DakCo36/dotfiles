require 'fileutils'
require_relative 'base'

module Component
  class ZshComponent < BaseComponent
    include Installable
    
    def installed?
      File.exist?(File.expand_path('~/.local/bin/zsh'))
    end

    def install
      system(%(sh -c "$(curl -fsSL https://raw.githubusercontent.com/romkatv/zsh-bin/master/install)"))
    end

    def rollback
      FileUtils.rm_f(File.expand_path('~/.local/bin/zsh'))
    end
  end
end
