require_relative 'installers/zsh_binary_installer'
require_relative 'installers/oh_my_zsh_installer'
require_relative 'installers/powerlevel10k_installer'
require_relative 'installers/zgenom_installer'

installers = [
  ZshBinaryInstaller.new,
  OhMyZshInstaller.new,
  Powerlevel10kInstaller.new,
  ZgenomInstaller.new
]

installers.each do |installer|
  if installer.installed?
    puts "#{installer.class.name} already installed"
  else
    installer.install
  end
end
