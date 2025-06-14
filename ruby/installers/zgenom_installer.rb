require 'fileutils'
require_relative 'base'

class ZgenomInstaller < Installer
  def installed?
    Dir.exist?(File.expand_path('~/.zgenom'))
  end

  def install
    dest = File.expand_path('~/.zgenom')
    system("git clone --depth 1 https://github.com/jandamm/zgenom.git #{dest}") unless installed?
    zshrc = File.expand_path('~/.zshrc')
    lines = File.exist?(zshrc) ? File.readlines(zshrc) : []
    unless lines.any? { |l| l =~ /^# load zgenom/ }
      File.open(zshrc, 'a') do |f|
        f.puts '# load zgenom'
        f.puts "[[ ! -f #{dest}/zgenom.zsh ]] || source \"#{dest}/zgenom.zsh\""
      end
    end
  end

  def rollback
    dest = File.expand_path('~/.zgenom')
    FileUtils.rm_rf(dest)

    zshrc = File.expand_path('~/.zshrc')
    if File.exist?(zshrc)
      lines = File.readlines(zshrc).reject do |l|
        l =~ /^# load zgenom/ || l.include?("#{dest}/zgenom.zsh")
      end
      File.write(zshrc, lines.join)
    end
  end
end
