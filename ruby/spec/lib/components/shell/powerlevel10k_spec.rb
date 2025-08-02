require 'spec_helper'
require 'components/shell/powerlevel10k'
require 'components/shell/oh_my_zsh'
require 'components/fetch/git'

RSpec.describe Component::Powerlevel10kComponent do
  subject(:p10k) { described_class.new }
  
  let(:mock_git) { instance_spy(Component::GitComponent) }
  let(:mock_ohmyzsh) { instance_spy(Component::OhMyZshComponent) }
  let(:null_logger) { Logger.new(File::NULL) }
  
  before do
    allow(p10k).to receive(:logger).and_return(null_logger)
    allow(Component::GitComponent).to receive(:new).and_return(mock_git)
    allow(Component::OhMyZshComponent).to receive(:new).and_return(mock_ohmyzsh)
    p10k.instance_variable_set(:@git, mock_git)
    p10k.instance_variable_set(:@ohmyzsh, mock_ohmyzsh)
  end

  describe '#exists?' do
    it 'returns true when theme directory exists' do
      allow(Dir).to receive(:exist?).with(described_class::THEME_DIR).and_return(true)
      expect(p10k.exists?).to be true
    end

    it 'returns false when theme directory does not exist' do
      allow(Dir).to receive(:exist?).with(described_class::THEME_DIR).and_return(false)
      expect(p10k.exists?).to be false
    end
  end

  describe '#installed?' do
    it 'returns true when theme directory exists' do
      allow(Dir).to receive(:exist?).with(described_class::THEME_DIR).and_return(true)
      expect(p10k.installed?).to be true
    end

    it 'returns false when theme directory is missing' do
      allow(Dir).to receive(:exist?).with(described_class::THEME_DIR).and_return(false)
      expect(p10k.installed?).to be false
    end
  end

  describe '#install' do
    context 'when already installed' do
      it 'does nothing' do
        allow(p10k).to receive(:installed?).and_return(true)
        
        p10k.install
        
        expect(mock_git).not_to have_received(:clone)
      end
    end

    context 'when not installed' do
      before do
        allow(p10k).to receive(:installed?).and_return(false)
      end

      context 'when Oh My Zsh is installed' do
        it 'clones the repository' do
          allow(mock_ohmyzsh).to receive(:installed?).and_return(true)
          allow(Dir).to receive(:exist?).with(described_class::THEME_DIR).and_return(false)
          allow(FileUtils).to receive(:mkdir_p).with(described_class::THEME_DIR)
          allow(mock_git).to receive(:clone).with(described_class::REPO_URL, described_class::THEME_DIR)

          p10k.install
          
          expect(FileUtils).to have_received(:mkdir_p).with(described_class::THEME_DIR)
          expect(mock_git).to have_received(:clone).with(described_class::REPO_URL, described_class::THEME_DIR)
        end

        it 'does not create theme directory if it already exists' do
          allow(mock_ohmyzsh).to receive(:installed?).and_return(true)
          allow(Dir).to receive(:exist?).with(described_class::THEME_DIR).and_return(true)
          allow(FileUtils).to receive(:mkdir_p)
          allow(mock_git).to receive(:clone).with(described_class::REPO_URL, described_class::THEME_DIR)
          
          p10k.install
          
          expect(FileUtils).not_to have_received(:mkdir_p)
          expect(mock_git).to have_received(:clone).with(described_class::REPO_URL, described_class::THEME_DIR)
        end
      end

      context 'when Oh My Zsh is not installed' do
        it 'raises an error' do
          allow(mock_ohmyzsh).to receive(:installed?).and_return(false)
          
          expect { p10k.install }.to raise_error(RuntimeError, 'Oh My Zsh is not installed. Please install Oh My Zsh first.')
        end
      end
    end
  end
end
