require_relative 'base'

class ZgenomInstaller < Installer
  def installed?
    Dir.exist?(File.expand_path('~/.zgenom'))
  end

  def install
    dest = File.expand_path('~/.zgenom')
    system("git clone https://github.com/jandamm/zgenom.git #{dest}") unless installed?
    zshrc = File.expand_path('~/.zshrc')
    lines = File.exist?(zshrc) ? File.readlines(zshrc) : []
    unless lines.any? { |l| l =~ /^# load zgenom/ }
      File.open(zshrc, 'a') do |f|
        f.puts '# load zgenom'
        f.puts "[[ ! -f #{dest}/zgenom.zsh ]] || source \"#{dest}/zgenom.zsh\""
      end
    end
  end
end
