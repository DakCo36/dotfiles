require 'spec_helper'
require 'components/shell/zsh_binary'

RSpec.describe Component::ZshBinaryComponent do
  subject(:zsh) { described_class.instance }
  let(:null_logger) { instance_spy(Logger) }
  let(:mock_curl) { instance_spy(Component::CurlComponent) }

  before do
    allow(zsh).to receive(:logger).and_return(null_logger)
    allow(zsh).to receive(:curl).and_return(mock_curl)
  end

  describe '#available?' do
    it 'returns true when zsh command is available' do
      # Given
      allow(zsh).to receive(:runCmd)
        .with('which', 'zsh')
        .and_return(true)
      # When
      available = zsh.available?
      # Then
      expect(available).to be true
    end

    it 'returns false when zsh command is missing' do
      # Given
      
      allow(zsh).to receive(:runCmd)
        .with('which', 'zsh')
        .and_raise(RuntimeError)
      # When
      available = zsh.available?
      # Then
      expect(available).to be false
    end
  end

  describe '#installed?' do
    it 'returns true when zsh is installed' do
      # Given
      allow(zsh).to receive(:runCmd)
        .with('which', 'zsh')
        .and_return(true)
      # When
      installed = zsh.installed?
      # Then
      expect(installed).to be true
    end

    it 'returns false when zsh is not installed' do
      # Given
      allow(zsh).to receive(:runCmd)
        .with('which','zsh')
        .and_raise(RuntimeError)
      # When
      installed = zsh.installed?
      # Then
      expect(installed).to be false
    end
  end

  describe '#version' do
    it 'returns the installed zsh version' do
      # Given
      expected_version = '5.9'
      expected_string = "zsh #{expected_version} (x86_64-pc-linux-musl)"
      allow(zsh).to receive(:runCmdWithOutput)
        .with('zsh', '--version')
        .and_return(expected_string)
      # When
      zsh_version = zsh.version()
      # Then
      expect(zsh_version).to eq(expected_version)
    end
  end

  describe '#install' do
    context 'When zsh is installed' do
      it 'Do nothing' do
        # Given
        allow(zsh).to receive(:installed?).and_return(true)
        # When
        zsh.install
        # Then
        expect(zsh).not_to receive(:download)
      end
    end

    context 'When zsh is not installed' do
      it 'install zsh' do
        # Given
        allow(zsh).to receive(:installed?).and_return(false)
        allow(zsh).to receive(:runCmd)
          .with('tar', '-xf', anything, '-C', anything)
          .and_return(true)
        allow(zsh).to receive(:configureAndMake).and_return(nil)

        # When
        zsh.install

        # Then
        expect(mock_curl).to have_received(:download).with(anything, anything)
        expect(zsh).to have_received(:configureAndMake)
      end
    end
  end
end
