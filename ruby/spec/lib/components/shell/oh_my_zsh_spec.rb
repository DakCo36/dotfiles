require 'spec_helper'
require 'components/shell/oh_my_zsh'

RSpec.describe Component::OhMyZshComponent do
  subject(:oh_my_zsh) { described_class.instance }
  let(:mock_curl) { instance_spy(Component::CurlComponent) }
  let(:mock_logger) { instance_spy(Logger) }

  before do
    allow(oh_my_zsh).to receive(:curl).and_return(mock_curl)
    allow(oh_my_zsh).to receive(:logger).and_return(mock_logger)
  end

  describe '#installed?' do
    it 'returns true when target directory exists' do
      allow(Dir)
        .to receive(:exist?)
        .with(anything)
        .and_return(true)

      installed = oh_my_zsh.installed?

      expect(installed).to be true
    end

    it 'returns false when target directory is missing' do
      allow(Dir)
        .to receive(:exist?)
        .with(anything)
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
        allow(oh_my_zsh).to receive(:runCmd).with('sh', anything, showStdout: true).and_return(true)
        allow(FileUtils).to receive(:rm_rf).with(anything)

        oh_my_zsh.install

        expect(mock_curl).to have_received(:download).with(anything, anything)
        expect(oh_my_zsh).to have_received(:runCmd).with('sh', anything, showStdout: true)
      end
    end
  end
end
