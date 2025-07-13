require 'spec_helper'
require 'components/shell/zsh'

RSpec.describe Component::ZshComponent do
  let(:curl) { instance_double(Component::CurlComponent) }
  before do
    allow(Component::CurlComponent).to receive(:new).and_return(curl)
  end

  subject(:zsh) { described_class.new }
  before do
    null_logger = Logger.new(File::NULL)
    allow(zsh).to receive(:logger).and_return(null_logger)
  end
  
  describe '#exists?' do
    it 'returns true when zsh command is available' do
      # Given
      allow(zsh).to receive(:runCmd)
        .with('command', '-v', 'zsh')
        .and_return(true)
      # When
      exists = zsh.exists?
      # Then
      expect(exists).to be true
    end

    it 'returns false when zsh command is missing' do
      # Given
      allow(zsh).to receive(:runCmd)
        .with('command', '-v', 'zsh')
        .and_return(false)
      # When
      exists = zsh.exists?
      # Then
      expect(exists).to be false
    end
  end

  describe '#installed?' do
    it 'returns true when zsh is installed' do
      # Given
      allow(zsh).to receive(:runCmd)
        .with('command', '-v', 'zsh')
        .and_return(true)
      # When
      installed = zsh.installed?
      # Then
      expect(installed).to be true
    end

    it 'returns false when zsh is not installed' do
      # Given
      allow(zsh).to receive(:runCmd)
        .with('command', '-v', 'zsh')
        .and_return(false)
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
        allow(curl).to receive(:download).and_return(true)
        allow(zsh).to receive(:runCmd)
          .with('tar', '-xf', described_class::FILEPATH, '-C', File.dirname(described_class::FILEPATH))
          .and_return(true)
        allow(zsh).to receive(:configureAndInstall).and_return(nil)

        # When
        zsh.install
        # Then
        expect(curl).to have_received(:download).with(described_class::DOWNLOAD_URL, described_class::FILEPATH)
        expect(zsh).to have_received(:configureAndInstall)
      end
    end
  end
end
