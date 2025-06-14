require 'fileutils'
require_relative 'base'

class Powerlevel10kInstaller < Installer
  def installed?
    Dir.exist?(File.expand_path('~/.oh-my-zsh/custom/themes/powerlevel10k'))
  end

  def install
    dest = File.expand_path('~/.oh-my-zsh/custom/themes/powerlevel10k')
    system("git clone --depth 1 https://github.com/romkatv/powerlevel10k.git #{dest}") unless installed?

    zshrc = File.expand_path('~/.zshrc')
    if File.exist?(zshrc)
      content = File.read(zshrc)
      if content =~ /^ZSH_THEME=/
        content.sub!(/^ZSH_THEME=.*/, 'ZSH_THEME="powerlevel10k/powerlevel10k"')
        File.write(zshrc, content)
      end
      lines = File.readlines(zshrc)
      unless lines.any? { |l| l =~ /^# Enable Powerlevel10k/ }
        addition = [
          "# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.",
          "# Initialization code that may require console input (password prompts, [y/n]",
          "# confirmations, etc.) must go above this block; everything else may go below.",
          "if [[ -r \"${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh\" ]]; then",
          "    source \"${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh\"",
          "fi"
        ]
        File.open(zshrc, 'a') { |f| addition.each { |l| f.puts l } }
      end
      unless lines.any? { |l| l =~ /^# To customize prompt/ }
        File.open(zshrc, 'a') do |f|
          f.puts "# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh."
          f.puts "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh"
        end
      end
    end

    local_p10k = File.join(File.dirname(__FILE__), '..', '.p10k.zsh')
    if File.exist?(local_p10k)
      FileUtils.ln_sf(local_p10k, File.expand_path('~/.p10k.zsh'))
    end
  end

  def rollback
    dest = File.expand_path('~/.oh-my-zsh/custom/themes/powerlevel10k')
    FileUtils.rm_rf(dest)

    zshrc = File.expand_path('~/.zshrc')
    if File.exist?(zshrc)
      content = File.read(zshrc)
      content.gsub!(/^ZSH_THEME="powerlevel10k\/powerlevel10k"/, 'ZSH_THEME="robbyrussell"')
      lines = content.lines.reject do |l|
        l =~ /^# Enable Powerlevel10k/ ||
        l.include?('p10k-instant-prompt') ||
        l =~ /^# Initialization code/ ||
        l =~ /^# confirmations/ ||
        l =~ /^# To customize prompt/ ||
        l.include?('p10k.zsh')
      end
      File.write(zshrc, lines.join)
    end

    p10k_link = File.expand_path('~/.p10k.zsh')
    FileUtils.rm_f(p10k_link) if File.symlink?(p10k_link)
  end
end
