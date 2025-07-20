require 'spec_helper'
require 'components/shell/powerlevel10k'

RSpec.describe Component::Powerlevel10kComponent do
  subject(:p10k) { described_class.new }
  before do
    null_logger = Logger.new(File::NULL)
    allow(p10k).to receive(:logger).and_return(null_logger)
  end

  describe '#exists?' do
    it 'returns true when git command is available' do
      allow(p10k).to receive(:runCmd).with('git', '--version').and_return(true)
      expect(p10k.exists?).to be true
    end

    it 'returns false when git command is missing' do
      allow(p10k).to receive(:runCmd).with('git', '--version').and_raise(RuntimeError)
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
        expect(p10k).not_to receive(:runCmd)
      end
    end

    context 'when not installed' do
      it 'clones the repository and updates zshrc' do
        allow(p10k).to receive(:installed?).and_return(false)
        allow(p10k).to receive(:runCmd).with('git', 'clone', '--depth', '1', described_class::REPO_URL, described_class::THEME_DIR).and_return(true)
        allow(p10k).to receive(:update_zshrc).and_return(true)
        allow(FileUtils).to receive(:ln_sf)
        allow(File).to receive(:exist?).with(described_class::LOCAL_P10K).and_return(true)

        p10k.install

        expect(p10k).to have_received(:runCmd).with('git', 'clone', '--depth', '1', described_class::REPO_URL, described_class::THEME_DIR)
        expect(p10k).to have_received(:update_zshrc)
      end
    end
  end
end
