require 'spec_helper'
require 'components/shell/zgenom'
require 'components/fetch/git'
require 'components/shell/zsh_binary'
require 'components/shell/zgenom'

RSpec.describe Component::ZgenomComponent do
  subject(:zgenom) { described_class.instance }

  let(:mock_git) { instance_spy(Component::GitComponent) }
  let(:mock_zsh_binary) { instance_spy(Component::ZshBinaryComponent) }
  let(:mock_logger) { Logger.new(File::NULL) }

  before do
    allow(zgenom).to receive(:logger).and_return(mock_logger)
    allow(zgenom).to receive(:git).and_return(mock_git)
    allow(zgenom).to receive(:zsh_binary).and_return(mock_zsh_binary)
    
    # Mock the instance methods for dependency checking
    allow(Component::GitComponent).to receive(:instance).and_return(mock_git)
    allow(Component::ZshBinaryComponent).to receive(:instance).and_return(mock_zsh_binary)
  end

  describe '#available?' do
    it 'returns true when zgenom directory exists' do
      allow(Dir).to receive(:exist?).with(described_class::TARGET_DIR_PATH).and_return(true)
      expect(zgenom.available?).to be true
    end

    it 'returns false when zgenom directory does not exist' do
      allow(Dir).to receive(:exist?).with(described_class::TARGET_DIR_PATH).and_return(false)
      expect(zgenom.available?).to be false
    end
  end

  describe '#installed?' do
    it 'returns true when zgenom directory exists' do
      allow(Dir).to receive(:exist?).with(described_class::TARGET_DIR_PATH).and_return(true)
      expect(zgenom.installed?).to be true
    end

    it 'returns false when zgenom directory is missing' do
      allow(Dir).to receive(:exist?).with(described_class::TARGET_DIR_PATH).and_return(false)
      expect(zgenom.installed?).to be false
    end
  end

  describe '#install' do
    context 'when already installed' do
      it 'does nothing' do
        allow(zgenom).to receive(:installed?).and_return(true)

        zgenom.install

        expect(mock_git).not_to have_received(:clone)
      end
    end

    context 'when not installed' do
      it 'clones the zgenom repository' do
        allow(zgenom).to receive(:installed?).and_return(false)
        allow(mock_git).to receive(:available?).and_return(true)
        allow(mock_zsh_binary).to receive(:available?).and_return(true)
        allow(mock_git).to receive(:clone).with(described_class::REPO_URL, described_class::TARGET_DIR_PATH)
        
        allow(zgenom).to receive(:configure).and_return(true)

        # Let's spy on the dependencies method
        allow(zgenom).to receive(:dependencies).and_call_original

        zgenom.install

        expect(mock_git)
          .to have_received(:clone)
          .with(described_class::REPO_URL, described_class::TARGET_DIR_PATH)
      end
    end
  end

  describe '#disableOhMyZshPlugins' do
    it 'disables oh-my-zsh plugins' do
      original_content = <<~CONTENT
        source $ZSH/oh-my-zsh.sh
        plugins=(git docker)
        
        something else
        another thing
      CONTENT

      expected_final_content = <<~CONTENT
        # source $ZSH/oh-my-zsh.sh
        # plugins=(git docker)

        something else
        another thing
      CONTENT

      allow(File).to receive(:exists?).with(described_class::ZSHRC).and_return(true)
      
    end
  end
end
