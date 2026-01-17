require 'spec_helper'
require 'components/utils/fd'

RSpec.describe Component::FdComponent do
  subject(:fd) { described_class.instance }
  let(:null_logger) { instance_spy(Logger) }
  let(:mock_curl) { instance_spy(Component::CurlComponent) }
  let(:mock_tar) { instance_spy(Component::TarComponent) }
  let(:mock_github) { instance_spy(Component::GithubComponent) }
  let(:bin_path) { '/home/user/.local/bin' }
  let(:man1_path) { '/home/user/.local/share/man/man1' }
  let(:zsh_completions_path) { '/home/user/.local/share/zsh/site-functions' }
  let(:bash_completions_path) { '/home/user/.local/share/bash-completion/completions' }

  before do
    allow(fd).to receive(:logger).and_return(null_logger)
    allow(fd).to receive(:curl).and_return(mock_curl)
    allow(fd).to receive(:tar).and_return(mock_tar)
    allow(fd).to receive(:github).and_return(mock_github)

    mock_config = instance_double(Components::Configuration)
    allow(mock_config).to receive(:tmp).and_return('/tmp/test')
    allow(mock_config).to receive(:bin).and_return(bin_path)
    allow(mock_config).to receive(:man1).and_return(man1_path)
    allow(mock_config).to receive(:zsh_completions).and_return(zsh_completions_path)
    allow(mock_config).to receive(:bash_completions).and_return(bash_completions_path)

    stub_const("#{described_class}::CONFIG", mock_config)
  end

  describe '#available?' do
    it 'returns true when fd command is available' do
      # Given
      allow(fd)
        .to receive(:system)
        .with('fd', '--version', out: File::NULL, err: File::NULL)
        .and_return(true)

      # When
      available = fd.available?

      # Then
      expect(available).to be true
    end

    it 'returns false when fd command is missing' do
      # Given
      allow(fd)
        .to receive(:system)
        .with('fd', '--version', out: File::NULL, err: File::NULL)
        .and_return(false)

      # When
      available = fd.available?

      # Then
      expect(available).to be false
    end
  end

  describe '#version' do
    it 'returns the installed fd version' do
      # Given
      status = instance_double(Process::Status, success?: true)
      allow(Open3).to receive(:capture2)
        .with('fd', '--version')
        .and_return(["fd 10.3.0\n", status])

      # When
      version = fd.version

      # Then
      expect(version).to eq('10.3.0')
    end

    it 'returns nil when command fails' do
      # Given
      status = instance_double(Process::Status, success?: false)
      allow(Open3).to receive(:capture2)
        .with('fd', '--version')
        .and_return(["Unknown result", status])

      # When
      version = fd.version

      # Then
      expect(version).to be_nil
    end

    it 'returns nil when fd is not installed' do
      # Given
      allow(Open3).to receive(:capture2)
        .with('fd', '--version')
        .and_raise(Errno::ENOENT)

      # When
      version = fd.version

      # Then
      expect(version).to be_nil
    end
  end

  describe '#installed?' do
    it 'returns true if fd is installed' do
      # Given
      allow(fd).to receive(:available?).and_return(true)
      allow(fd).to receive(:version).and_return("10.3.0")

      # When & Then
      expect(fd.installed?).to be true
    end

    it 'returns false if fd is not installed' do
      # Given
      allow(fd).to receive(:available?).and_return(false)
      allow(fd).to receive(:version).and_return(nil)

      # When & Then
      expect(fd.installed?).to be false
    end
  end

  describe '#install!' do
    it 'installs fd from GitHub releases' do
      # Given
      allow(mock_github).to receive(:get_latest_release_tag).and_return('v10.3.0')
      allow(mock_github)
        .to receive(:get_latest_release_asset_download_url)
        .and_return('https://github.com/sharkdp/fd/releases/download/v10.3.0/fd-v10.3.0-x86_64-unknown-linux-musl.tar.gz')
      allow(mock_curl).to receive(:download).and_return(["", "", instance_double(Process::Status, success?: true)])
      allow(mock_tar).to receive(:extract).and_return(["", "", instance_double(Process::Status, success?: true)])
      allow(fd).to receive(:setup_man_page).and_return(["", "", instance_double(Process::Status, success?: true)])
      allow(fd).to receive(:setup_completions).and_return(["", "", instance_double(Process::Status, success?: true)])
      allow(fd).to receive(:runCmd)
        .with('cp', anything, anything)
        .and_return(["", "", instance_double(Process::Status, success?: true)])

      # When
      fd.install!

      # Then
      expect(mock_github).to have_received(:get_latest_release_tag)
      expect(mock_github).to have_received(:get_latest_release_asset_download_url)
      expect(mock_curl).to have_received(:download)
      expect(mock_tar).to have_received(:extract)
      expect(fd).to have_received(:setup_man_page)
      expect(fd).to have_received(:setup_completions)
    end
  end

  describe '#setup_man_page' do
    before do
      stub_const("#{described_class}::TMP_DIR_PATH", '/tmp/test/fd-assets')
      allow(FileUtils).to receive(:mkdir_p)
      allow(fd).to receive(:runCmd).and_return(["", "", instance_double(Process::Status, success?: true)])
    end

    it 'creates directory and copies fd.1' do
      # When
      fd.send(:setup_man_page)

      # Then
      expect(FileUtils).to have_received(:mkdir_p).with(man1_path)
      expect(fd).to have_received(:runCmd).with('cp', '/tmp/test/fd-assets/fd.1', "#{man1_path}/fd.1")
    end
  end

  describe '#setup_completions' do
    before do
      stub_const("#{described_class}::TMP_DIR_PATH", '/tmp/test/fd-assets')
      allow(FileUtils).to receive(:mkdir_p)
      allow(fd).to receive(:runCmd).and_return(["", "", instance_double(Process::Status, success?: true)])
    end

    it 'creates directories and copies completion files' do
      # When
      fd.send(:setup_completions)

      # Then
      expect(FileUtils).to have_received(:mkdir_p).with(zsh_completions_path)
      expect(FileUtils).to have_received(:mkdir_p).with(bash_completions_path)
      expect(fd).to have_received(:runCmd).with('cp', '/tmp/test/fd-assets/autocomplete/_fd', "#{zsh_completions_path}/_fd")
      expect(fd).to have_received(:runCmd).with('cp', '/tmp/test/fd-assets/autocomplete/fd.bash', "#{bash_completions_path}/fd")
    end
  end
end
