require 'spec_helper'
require 'components/shell/oh_my_posh'
require 'components/fetch/curl'

RSpec.describe Component::OhMyPoshComponent do
  subject(:oh_my_posh) { described_class.instance }

  let(:mock_curl) { instance_spy(Component::CurlComponent) }
  let(:mock_logger) { Logger.new(File::NULL) }

  before do
    allow(Component::CurlComponent).to receive(:instance).and_return(mock_curl)
    allow(oh_my_posh).to receive(:curl).and_return(mock_curl)
    allow(oh_my_posh).to receive(:logger).and_return(mock_logger)
  end

  describe '#available?' do
    it 'returns true when binary exists and is executable' do
      allow(File).to receive(:exist?).with(described_class::BINARY_PATH).and_return(true)
      allow(File).to receive(:executable?).with(described_class::BINARY_PATH).and_return(true)

      expect(oh_my_posh.available?).to be true
    end

    it 'returns false when binary is missing' do
      allow(File).to receive(:exist?).with(described_class::BINARY_PATH).and_return(false)

      expect(oh_my_posh.available?).to be false
    end
  end

  describe '#installed?' do
    it 'returns true when binary and theme exist' do
      allow(oh_my_posh).to receive(:available?).and_return(true)
      allow(File).to receive(:exist?).with(described_class::DEFAULT_THEME_PATH).and_return(true)

      expect(oh_my_posh.installed?).to be true
    end

    it 'returns false when theme is missing' do
      allow(oh_my_posh).to receive(:available?).and_return(true)
      allow(File).to receive(:exist?).with(described_class::DEFAULT_THEME_PATH).and_return(false)

      expect(oh_my_posh.installed?).to be false
    end
  end

  describe '#install' do
    context 'when already installed' do
      it 'skips installation' do
        allow(oh_my_posh).to receive(:installed?).and_return(true)

        oh_my_posh.install

        expect(mock_curl).not_to have_received(:download)
      end
    end

    context 'when not installed' do
      before do
        allow(oh_my_posh).to receive(:installed?).and_return(false)
      end

      it 'downloads binary and installs theme' do
        allow(mock_curl).to receive(:available?).and_return(true)
        allow(mock_curl).to receive(:download).with(
          described_class::DOWNLOAD_URL,
          described_class::TMP_BINARY_PATH
        )

        allow(FileUtils).to receive(:mkdir_p).and_return(true)
        allow(FileUtils).to receive(:mv)
        allow(FileUtils).to receive(:chmod)
        allow(FileUtils).to receive(:cp)
        allow(FileUtils).to receive(:rm_f)

        allow(File).to receive(:exist?).with(described_class::DEFAULT_THEME_SOURCE).and_return(true)
        allow(File).to receive(:exist?).with(described_class::DEFAULT_THEME_PATH).and_return(false)
        allow(File).to receive(:exist?).with(described_class::TMP_BINARY_PATH).and_return(true)
        allow(Dir).to receive(:exist?).with(described_class::THEMES_DIR).and_return(false)
        allow(Dir).to receive(:exist?).with(described_class::CONFIG.bin).and_return(true)

        oh_my_posh.install

        expect(mock_curl).to have_received(:download).with(
          described_class::DOWNLOAD_URL,
          described_class::TMP_BINARY_PATH
        )
        expect(FileUtils).to have_received(:mv).with(
          described_class::TMP_BINARY_PATH,
          described_class::BINARY_PATH
        )
        expect(FileUtils).to have_received(:chmod).with(0o755, described_class::BINARY_PATH)
        expect(FileUtils).to have_received(:cp).with(
          described_class::DEFAULT_THEME_SOURCE,
          described_class::DEFAULT_THEME_PATH
        )
        expect(FileUtils).to have_received(:rm_f).with(described_class::TMP_BINARY_PATH)
      end
    end
  end
end
