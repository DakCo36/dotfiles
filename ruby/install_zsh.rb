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

action = ARGV[0] || 'install'

case action
when 'install'
  completed = []
  installers.each do |inst|
    begin
      if inst.installed?
        puts "#{inst.class.name} already installed"
      else
        inst.install
        completed << inst
      end
    rescue StandardError => e
      warn "Error installing #{inst.class.name}: #{e}"
      completed.reverse_each { |i| i.rollback }
      exit 1
    end
  end
when 'rollback'
  installers.reverse_each(&:rollback)
else
  puts "Unknown action: #{action}"
  puts "Usage: #{File.basename($0)} [install|rollback]"
end
