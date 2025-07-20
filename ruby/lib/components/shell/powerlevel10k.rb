require 'fileutils'
require_relative '../base'
require_relative '../configuration'
require_relative '../../mixins/installable'
require_relative '../../mixins/loggable'

module Component
  # Component for installing the powerlevel10k zsh theme
  class Powerlevel10kComponent < BaseComponent
    include Installable
    include Loggable

    CONFIG = Components::Configuration.instance
    REPO_URL = 'https://github.com/romkatv/powerlevel10k.git'
    THEME_DIR = File.join(CONFIG.home, '.oh-my-zsh/custom/themes/powerlevel10k')
    ZSHRC = File.join(CONFIG.home, '.zshrc')
    LOCAL_P10K = File.expand_path(File.join(File.dirname(__FILE__), '..', '.p10k.zsh'))
    P10K_LINK = File.join(CONFIG.home, '.p10k.zsh')

    def exists?
      runCmd('git', '--version')
      true
    rescue RuntimeError
      logger.warn('git command not found')
      false
    end

    def installed?
      Dir.exist?(THEME_DIR)
    end

    def install
      if installed?
        logger.info('Powerlevel10k already installed.')
        return
      end

      logger.info('Installing Powerlevel10k theme')
      runCmd('git', 'clone', '--depth', '1', REPO_URL, THEME_DIR)
      update_zshrc
      FileUtils.ln_sf(LOCAL_P10K, P10K_LINK) if File.exist?(LOCAL_P10K)
    rescue => e
      logger.error("Failed to install Powerlevel10k: #{e}")
      raise e
    end

    def rollback
      FileUtils.rm_rf(THEME_DIR)
      rollback_zshrc
      FileUtils.rm_f(P10K_LINK) if File.symlink?(P10K_LINK)
    end

    private

    def update_zshrc
      return unless File.exist?(ZSHRC)

      content = File.read(ZSHRC)
      if content =~ /^ZSH_THEME=/
        content.sub!(/^ZSH_THEME=.*/, 'ZSH_THEME="powerlevel10k/powerlevel10k"')
      else
        content << "\nZSH_THEME=\"powerlevel10k/powerlevel10k\"\n"
      end

      lines = content.lines
      unless lines.any? { |l| l =~ /^# Enable Powerlevel10k/ }
        addition = [
          '# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.',
          '# Initialization code that may require console input (password prompts, [y/n]',
          '# confirmations, etc.) must go above this block; everything else may go below.',
          'if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then',
          '    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"',
          'fi'
        ]
        File.open(ZSHRC, 'a') { |f| addition.each { |l| f.puts l } }
      end

      unless lines.any? { |l| l =~ /^# To customize prompt/ }
        File.open(ZSHRC, 'a') do |f|
          f.puts '# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.'
          f.puts '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh'
        end
      end

      File.write(ZSHRC, content)
    end

    def rollback_zshrc
      return unless File.exist?(ZSHRC)

      content = File.read(ZSHRC)
      content.gsub!(/^ZSH_THEME="powerlevel10k\/powerlevel10k"/, 'ZSH_THEME="robbyrussell"')
      lines = content.lines.reject do |l|
        l =~ /^# Enable Powerlevel10k/ ||
        l.include?('p10k-instant-prompt') ||
        l =~ /^# Initialization code/ ||
        l =~ /^# confirmations/ ||
        l =~ /^# To customize prompt/ ||
        l.include?('p10k.zsh')
      end
      File.write(ZSHRC, lines.join)
    end
  end
end
