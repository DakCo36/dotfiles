require 'spec_helper'
require 'components/shell/powerlevel10k'
require 'components/shell/oh_my_zsh'
require 'components/fetch/git'

RSpec.describe Component::Powerlevel10kComponent do
  subject(:p10k) { described_class.instance }
  
  let(:mock_git) { instance_spy(Component::GitComponent) }
  let(:mock_ohmyzsh) { instance_spy(Component::OhMyZshComponent) }
  let(:mock_logger) { Logger.new(File::NULL) }
  
  before do
    allow(Component::GitComponent).to receive(:instance).and_return(mock_git)
    allow(Component::OhMyZshComponent).to receive(:instance).and_return(mock_ohmyzsh)
    allow(p10k).to receive(:logger).and_return(mock_logger)
  end

  describe '#available?' do
    it 'returns true when theme directory exists' do
      allow(Dir)
        .to receive(:exist?)
        .with(anything)
        .and_return(true)
      expect(p10k.available?).to be true
    end

    it 'returns false when theme directory does not exist' do
      allow(Dir).to receive(:exist?).with(described_class::TARGET_DIR_PATH).and_return(false)
      expect(p10k.available?).to be false
    end
  end

  describe '#installed?' do
    it 'returns true when theme directory exists' do
      allow(Dir).to receive(:exist?).with(described_class::TARGET_DIR_PATH).and_return(true)
      expect(p10k.installed?).to be true
    end

    it 'returns false when theme directory is missing' do
      allow(Dir).to receive(:exist?).with(described_class::TARGET_DIR_PATH).and_return(false)
      expect(p10k.installed?).to be false
    end
  end

  describe '#install' do
    context 'when already installed' do
      it 'does nothing' do
        allow(p10k).to receive(:installed?).and_return(true)
        allow(p10k).to receive(:configure)
        
        p10k.install
        
        expect(mock_git).not_to have_received(:clone)
        expect(p10k).not_to have_received(:configure)
      end
    end

    context 'when not installed' do
      it 'clones the repository' do
        allow(p10k).to receive(:installed?).and_return(false)
        allow(p10k).to receive(:configure)
        allow(mock_ohmyzsh).to receive(:available?).and_return(true)
        allow(mock_git).to receive(:available?).and_return(true)
        allow(Dir)
          .to receive(:exist?)
          .with(described_class::TARGET_DIR_PATH)
          .and_return(false)
        allow(FileUtils)
          .to receive(:mkdir_p)
          .with(described_class::TARGET_DIR_PATH)
        allow(mock_git)
          .to receive(:clone)
          .with(described_class::REPO_URL, described_class::TARGET_DIR_PATH)

        p10k.install
        
        expect(FileUtils).to have_received(:mkdir_p).with(described_class::TARGET_DIR_PATH)
        expect(mock_git).to have_received(:clone).with(described_class::REPO_URL, described_class::TARGET_DIR_PATH)
        expect(p10k).to have_received(:configure)
      end
    end
  end

  # Skip '#configure' test since it just call setTheme and setConfig

  describe '#setInstantPrompt' do
    it 'raises an error if .zshrc file does not exist' do
      allow(File)
        .to receive(:exist?)
        .with(described_class::ZSHRC)
        .and_return(false)

      expect { p10k.send(:setInstantPrompt) }
        .to raise_error(RuntimeError, /.*file not found.*/)
    end

    it 'skips if instant prompt already exists' do
      zshrc_content = <<~EOF
        # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
        if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
            source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
        fi
        # Other content
      EOF

      allow(File).to receive(:exist?).with(described_class::ZSHRC).and_return(true)
      allow(File).to receive(:read).with(described_class::ZSHRC).and_return(zshrc_content)
      allow(File).to receive(:open)

      p10k.send(:setInstantPrompt)

      expect(File).not_to have_received(:open)
    end

    it 'prepends instant prompt block to .zshrc' do
      file_double = instance_double(File)
      allow(file_double).to receive(:write)

      zshrc_content = <<~EOF
        # Existing content
        ZSH_THEME="robbyrussell"
      EOF

      allow(File).to receive(:exist?).with(described_class::ZSHRC).and_return(true)
      allow(File).to receive(:read).with(described_class::ZSHRC).and_return(zshrc_content)
      allow(File).to receive(:open).with(described_class::ZSHRC, 'w').and_yield(file_double)

      p10k.send(:setInstantPrompt)

      expect(file_double)
        .to have_received(:write)
        .with(match(/^# Enable Powerlevel10k instant prompt/))
    end
  end
  
  describe '#setTheme' do
    it 'raises an error if .zsh file does not exist' do
      allow(File)
        .to receive(:exist?)
        .with(described_class::ZSHRC)
        .and_return(false)

      expect { p10k.send(:setTheme) }
        .to raise_error(RuntimeError, /.*file not found.*/)
    end

    it 'substitute zsh theme in .zshrc file' do
      file_double = instance_double(File)
      allow(file_double).to receive(:write)

      zshrc_content = <<~EOF
        # Something blahblah
        ANOTHER=VARIABLE
        # Something else blahblah
        ZSH_THEME="robbyrussell"
        # Another thing blahblah
        ANOTHER_VARIABLE=VALUE
      EOF

      allow(File)
        .to receive(:exist?)
        .with(described_class::ZSHRC)
        .and_return(true)

      allow(File)
        .to receive(:read)
        .with(described_class::ZSHRC)
        .and_return(zshrc_content)

      allow(File)
        .to receive(:open)
        .with(described_class::ZSHRC, 'w')
        .and_yield(file_double)
      
      p10k.send(:setTheme)

      expect(file_double)
        .to have_received(:write)
        .with(match(/ZSH_THEME="powerlevel10k\/powerlevel10k"/))
    end

    it 'add zsh theme to .zshrc file if not exist' do
      file_double = instance_double(File)
      allow(file_double).to receive(:write)

      zshrc_content = <<~EOF
        # Somthing blahblah
        ANOTHER=VARIABLE
        # Another thing blahblah
        ANOTHER_VARIABLE=VALUE
      EOF

      allow(File)
        .to receive(:exist?)
        .with(described_class::ZSHRC)
        .and_return(true)

      allow(File)
        .to receive(:read)
        .with(described_class::ZSHRC)
        .and_return(zshrc_content)

      allow(File)
        .to receive(:open)
        .with(described_class::ZSHRC, 'w')
        .and_yield(file_double)
      
      p10k.send(:setTheme)

      expect(file_double)
        .to have_received(:write)
        .with(match(/ZSH_THEME="powerlevel10k\/powerlevel10k"/))
    end

    it 'add source .p10k.zsh to .zshrc file if not exist' do
      file_double = instance_double(File)
      allow(file_double).to receive(:write)

      zshrc_content = <<~EOF
        # Something blahblah
        ANOTHER=VARIABLE
        # Another thing blahblah
        ANOTHER_VARIABLE=VALUE
      EOF

      allow(File)
        .to receive(:exist?)
        .with(described_class::ZSHRC)
        .and_return(true)

      allow(File)
        .to receive(:read)
        .with(described_class::ZSHRC)
        .and_return(zshrc_content)

      allow(File)
        .to receive(:open)
        .with(described_class::ZSHRC, 'w')
        .and_yield(file_double)
        
      p10k.send(:setTheme)

      expect(file_double)
        .to have_received(:write)
        .with(match(/\[\[ ! -f ~\/.p10k.zsh \]\] \|\| source ~\/.p10k.zsh\n$/))
    end
  end

  describe '#setConfig' do
    it 'raises an error if source file does not exist' do
      allow(File)
        .to receive(:exist?)
        .with(anything)
        .and_return(false)

      expect { p10k.send(:setConfig) }
        .to raise_error(RuntimeError, /Config file .* not found/)
    end

    it 'Backups destination file if it exists' do
      allow(File)
        .to receive(:exist?)
        .with(anything)
        .and_return(true)

      allow(FileUtils)
        .to receive(:cp)
        .with(anything, anything)

      p10k.send(:setConfig)

      expect(FileUtils).to have_received(:cp).with(anything, /.*backup_.*/)
    end
  end
end
