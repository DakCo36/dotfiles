require 'spec_helper'
require 'components/utils/ripgrep'

RSpec.describe Component::RipgrepComponent do
  subject(:ripgrep) { described_class.instance }
  let(:null_logger) { instance_spy(Logger) }
  let(:mock_curl) { instance_spy(Component::CurlComponent) }
  let(:mock_tar) { instance_spy(Component::TarComponent) }
  let(:mock_github) { instance_spy(Component::GithubComponent) }
  let(:bin_path) { '/home/user/.local/bin' }
  let(:man1_path) { '/home/user/.local/share/man/man1' }
  let(:zsh_completions_path) { '/home/user/.local/share/zsh/site-functions' }
  let(:bash_completions_path) { '/home/user/.local/share/bash-completion/completions' }

  before do
    allow(ripgrep).to receive(:logger).and_return(null_logger)
    allow(ripgrep).to receive(:curl).and_return(mock_curl)
    allow(ripgrep).to receive(:tar).and_return(mock_tar)
    allow(ripgrep).to receive(:github).and_return(mock_github)

    mock_config = instance_double(Components::Configuration)
    allow(mock_config).to receive(:tmp).and_return('/tmp/test')
    allow(mock_config).to receive(:bin).and_return(bin_path)
    allow(mock_config).to receive(:man1).and_return(man1_path)
    allow(mock_config).to receive(:zsh_completions).and_return(zsh_completions_path)
    allow(mock_config).to receive(:bash_completions).and_return(bash_completions_path)

    stub_const("#{described_class}::CONFIG", mock_config)
  end

  describe '#available?' do
    it 'returns true when rg command is available' do
      # Given
      allow(ripgrep)
        .to receive(:system)
        .with('rg', '--version', out: File::NULL, err: File::NULL)
        .and_return(true)

      # When
      available = ripgrep.available?

      # Then
      expect(available).to be true
    end

    it 'returns false when rg command is missing' do
      # Given
      allow(ripgrep)
        .to receive(:system)
        .with('rg', '--version', out: File::NULL, err: File::NULL)
        .and_return(false)

      # When
      available = ripgrep.available?

      # Then
      expect(available).to be false
    end
  end

  describe '#version' do
    it 'returns the installed ripgrep version' do
      # Given
      status = instance_double(Process::Status, success?: true)
      allow(Open3).to receive(:capture2)
        .with('rg', '--version')
        .and_return(["ripgrep 14.1.0\n", status])

      # When
      version = ripgrep.version

      # Then
      expect(version).to eq('14.1.0')
    end

    it 'returns nil when command fails' do
      # Given
      status = instance_double(Process::Status, success?: false)
      allow(Open3).to receive(:capture2)
        .with('rg', '--version')
        .and_return(["Unknown result", status])

      # When
      version = ripgrep.version

      # Then
      expect(version).to be_nil
    end

    it 'returns nil when rg is not installed' do
      # Given
      allow(Open3).to receive(:capture2)
        .with('rg', '--version')
        .and_raise(Errno::ENOENT)

      # When
      version = ripgrep.version

      # Then
      expect(version).to be_nil
    end
  end

  describe '#installed?' do
    it 'returns true if ripgrep is installed' do
      # Given
      allow(ripgrep).to receive(:available?).and_return(true)
      allow(ripgrep).to receive(:version).and_return("14.1.0")

      # When & Then
      expect(ripgrep.installed?).to be true
    end

    it 'returns false if ripgrep is not installed' do
      # Given
      allow(ripgrep).to receive(:available?).and_return(false)
      allow(ripgrep).to receive(:version).and_return(nil)

      # When & Then
      expect(ripgrep.installed?).to be false
    end
  end

  describe '#install!' do
    it 'installs ripgrep from GitHub releases' do
      # Given
      allow(mock_github).to receive(:get_latest_release_tag).and_return('14.1.0')
      allow(mock_github)
        .to receive(:get_latest_release_asset_download_url)
        .and_return('https://github.com/BurntSushi/ripgrep/releases/download/14.1.0/ripgrep-14.1.0-x86_64-unknown-linux-musl.tar.gz')
      allow(mock_curl).to receive(:download).and_return(["", "", instance_double(Process::Status, success?: true)])
      allow(mock_tar).to receive(:extract).and_return(["", "", instance_double(Process::Status, success?: true)])
      allow(ripgrep).to receive(:setup_man_page).and_return(["", "", instance_double(Process::Status, success?: true)])
      allow(ripgrep).to receive(:setup_completions).and_return(["", "", instance_double(Process::Status, success?: true)])
      allow(ripgrep).to receive(:runCmd)
        .with('cp', anything, anything)
        .and_return(["", "", instance_double(Process::Status, success?: true)])

      # When
      ripgrep.install!

      # Then
      expect(mock_github).to have_received(:get_latest_release_tag)
      expect(mock_github).to have_received(:get_latest_release_asset_download_url)
      expect(mock_curl).to have_received(:download)
      expect(mock_tar).to have_received(:extract)
      expect(ripgrep).to have_received(:setup_man_page)
      expect(ripgrep).to have_received(:setup_completions)
    end
  end

  describe '#setup_man_page' do
    before do
      stub_const("#{described_class}::TMP_DIR_PATH", '/tmp/test/ripgrep-assets')
      allow(FileUtils).to receive(:mkdir_p)
      allow(ripgrep).to receive(:runCmd).and_return(["", "", instance_double(Process::Status, success?: true)])
    end

    it 'creates directory and copies rg.1' do
      # When
      ripgrep.send(:setup_man_page)

      # Then
      expect(FileUtils).to have_received(:mkdir_p).with(man1_path)
      expect(ripgrep).to have_received(:runCmd).with('cp', '/tmp/test/ripgrep-assets/doc/rg.1', "#{man1_path}/rg.1")
    end
  end

  describe '#setup_completions' do
    before do
      stub_const("#{described_class}::TMP_DIR_PATH", '/tmp/test/ripgrep-assets')
      allow(FileUtils).to receive(:mkdir_p)
      allow(ripgrep).to receive(:runCmd).and_return(["", "", instance_double(Process::Status, success?: true)])
    end

    it 'creates directories and copies completion files' do
      # When
      ripgrep.send(:setup_completions)

      # Then
      expect(FileUtils).to have_received(:mkdir_p).with(zsh_completions_path)
      expect(FileUtils).to have_received(:mkdir_p).with(bash_completions_path)
      expect(ripgrep).to have_received(:runCmd).with('cp', '/tmp/test/ripgrep-assets/complete/_rg', "#{zsh_completions_path}/_rg")
      expect(ripgrep).to have_received(:runCmd).with('cp', '/tmp/test/ripgrep-assets/complete/rg.bash', "#{bash_completions_path}/rg")
    end
  end
end
