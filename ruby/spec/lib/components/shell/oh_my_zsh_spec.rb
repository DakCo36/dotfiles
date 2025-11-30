require 'spec_helper'
require 'components/shell/oh_my_zsh'

RSpec.describe Component::OhMyZshComponent do
  subject(:oh_my_zsh) { described_class.instance }
  let(:mock_curl) { instance_spy(Component::CurlComponent) }
  let(:mock_zsh_binary) { instance_spy(Component::ZshBinaryComponent) }
  let(:mock_logger) { Logger.new(File::NULL) }

  before do
    allow(Component::ZshBinaryComponent).to receive(:instance).and_return(mock_zsh_binary)
    allow(Component::CurlComponent).to receive(:instance).and_return(mock_curl)
    allow(oh_my_zsh).to receive(:curl).and_return(mock_curl)
    allow(oh_my_zsh).to receive(:zsh_binary).and_return(mock_zsh_binary)
    allow(oh_my_zsh).to receive(:logger).and_return(mock_logger)
  end

  describe '#available?' do
    it 'returns true when target directory exists' do
      allow(Dir)
        .to receive(:exist?)
        .with(described_class::TARGET_DIR_PATH)
        .and_return(true)

      available = oh_my_zsh.available?

      expect(available).to be true
    end

    it 'returns false when target directory does not exist' do
      allow(Dir)
        .to receive(:exist?)
        .with(described_class::TARGET_DIR_PATH)
        .and_return(false)

      available = oh_my_zsh.available?

      expect(available).to be false
    end
  end

  describe '#installed?' do
    it 'returns true when target directory exists' do
      allow(Dir)
        .to receive(:exist?)
        .with(described_class::TARGET_DIR_PATH)
        .and_return(true)

      installed = oh_my_zsh.installed?

      expect(installed).to be true
    end

    it 'returns false when target directory is missing' do
      allow(Dir)
        .to receive(:exist?)
        .with(described_class::TARGET_DIR_PATH)
        .and_return(false)

      installed = oh_my_zsh.installed?

      expect(installed).to be false
    end
  end

  describe '#install' do
    context 'when already installed' do
      it 'does nothing' do
        allow(oh_my_zsh)
          .to receive(:installed?)
          .and_return(true)

        oh_my_zsh.install

        expect(mock_curl).not_to have_received(:download)
      end
    end

    context 'when not installed' do
      it 'downloads and runs the installer script' do
        allow(oh_my_zsh).to receive(:installed?).and_return(false)
        allow(mock_curl).to receive(:download).and_return(true)
        allow(oh_my_zsh).to receive(:runCmd).with('sh', '-c', described_class::TMP_SCRIPT_PATH, showStdout: true).and_return(true)
        allow(FileUtils).to receive(:rm_rf).with(described_class::TARGET_DIR_PATH)
        
        # Mock .zshrc file for configure step
        zshrc_path = described_class::ZSHRC
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(zshrc_path).and_return(true)
        allow(File).to receive(:read).with(zshrc_path).and_return("plugins=(git)")
        allow(File).to receive(:open).with(zshrc_path, 'w').and_yield(double('file', write: true))

        oh_my_zsh.install

        expect(mock_curl).to have_received(:available?)
        expect(mock_zsh_binary).to have_received(:available?)
        expect(mock_curl).to have_received(:download).with(described_class::DOWNLOAD_URL, described_class::TMP_SCRIPT_PATH)
        expect(oh_my_zsh).to have_received(:runCmd).with('sh', '-c', described_class::TMP_SCRIPT_PATH, showStdout: true)
      end
    end
  end

  # skip configure, because it just calls setPlugins

  describe '#setPlugins' do
    let(:zshrc_path) { described_class::ZSHRC }
    
    context 'when plugins=() already exists in .zshrc' do
      it 'replaces the existing plugins array' do
        # Given
        original_content = <<~CONTENT
          # Welcome to oh-my-zsh!
          export ZSH="$HOME/.oh-my-zsh"
          ZSH_THEME="robbyrussell"
          # plugins=(git)
          plugins=(git)
          source $ZSH/oh-my-zsh.sh
        CONTENT
        
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(zshrc_path).and_return(true)
        allow(File).to receive(:read).with(zshrc_path).and_return(original_content)
        
        file_handle = instance_double(File)
        allow(File).to receive(:open).with(zshrc_path, 'w').and_yield(file_handle)
        allow(file_handle).to receive(:write)
        
        # When
        oh_my_zsh.send(:setPlugins)
        
        # Then
        expect(file_handle).to have_received(:write) do |content|
          expect(content).to match(/plugins=\([^)\n]+\)/)
          expect(content).to include(/\# plugins=\(git\)/)
        end
      end
    end
    
    context 'when plugins=() does not exist in .zshrc' do
      it 'appends plugins configuration to the file' do
        # Given
        original_content = <<~CONTENT
          export ZSH="$HOME/.oh-my-zsh"
          ZSH_THEME="robbyrussell"
          source $ZSH/oh-my-zsh.sh
        CONTENT
        
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(zshrc_path).and_return(true)
        allow(File).to receive(:read).with(zshrc_path).and_return(original_content)
        
        file_handle = instance_double(File)
        allow(File).to receive(:open).with(zshrc_path, 'w').and_yield(file_handle)
        allow(file_handle).to receive(:write)
        
        # When
        oh_my_zsh.send(:setPlugins)
        
        # Then
        expect(file_handle).to have_received(:write) do |content|
          expect(content).to include('# oh-my-zsh plugins configuration')
          expect(content).to match(/plugins=\([^)\n]+\)/)
        end
      end
    end
    
    context 'when .zshrc file does not exist' do
      it 'raises an error' do
        # Given
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(zshrc_path).and_return(false)
        
        # When & Then
        expect {
          oh_my_zsh.send(:setPlugins)
        }.to raise_error(RuntimeError, '.zshrc file not found')
      end
    end
  end
end
