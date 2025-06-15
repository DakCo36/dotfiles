require 'fileutils'
require_relative 'base'

class OhMyZshInstaller < Installer
  def installed?
    Dir.exist?(File.expand_path('~/.oh-my-zsh'))
  end

  def install
    system(%(sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"))
  end

  def rollback
    FileUtils.rm_rf(File.expand_path('~/.oh-my-zsh'))
  end
end
