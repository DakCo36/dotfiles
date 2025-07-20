require 'spec_helper'
require 'components/shell/oh_my_zsh'

RSpec.describe Component::OhMyZshComponent do
  let(:curl) { instance_double(Component::CurlComponent) }

  before do
    allow(Component::CurlComponent).to receive(:new).and_return(curl)
  end

  subject(:ohmyzsh) { described_class.new }
  before do
    null_logger = Logger.new(File::NULL)
    allow(ohmyzsh).to receive(:logger).and_return(null_logger)
  end

  describe '#installed?' do
    it 'returns true when target directory exists' do
      allow(Dir).to receive(:exist?).with(described_class::TARGET_DIR).and_return(true)
      expect(ohmyzsh.installed?).to be true
    end

    it 'returns false when target directory is missing' do
      allow(Dir).to receive(:exist?).with(described_class::TARGET_DIR).and_return(false)
      expect(ohmyzsh.installed?).to be false
    end
  end

  describe '#exists?' do
    it 'delegates to installed?' do
      allow(ohmyzsh).to receive(:installed?).and_return(true)
      expect(ohmyzsh.exists?).to be true
    end
  end

  describe '#install' do
    context 'when already installed' do
      it 'does nothing' do
        allow(ohmyzsh).to receive(:installed?).and_return(true)
        ohmyzsh.install
        expect(curl).not_to receive(:download)
      end
    end

    context 'when not installed' do
      it 'downloads and runs the installer script' do
        allow(ohmyzsh).to receive(:installed?).and_return(false)
        allow(curl).to receive(:download).and_return(true)
        allow(ohmyzsh).to receive(:runCmd).with('sh', described_class::SCRIPT_PATH, showStdout: true).and_return(true)
        allow(FileUtils).to receive(:rm_f)
        allow(File).to receive(:exist?).with(described_class::SCRIPT_PATH).and_return(true)

        ohmyzsh.install

        expect(curl).to have_received(:download).with(described_class::DOWNLOAD_URL, described_class::SCRIPT_PATH)
        expect(ohmyzsh).to have_received(:runCmd).with('sh', described_class::SCRIPT_PATH, showStdout: true)
      end
    end
  end
end
