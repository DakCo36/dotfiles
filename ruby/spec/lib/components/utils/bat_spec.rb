require 'spec_helper'
require 'components/utils/bat'

RSpec.describe Component::BatComponent do
  subject(:bat) { described_class.instance }
  let(:null_logger) { instance_spy(Logger) }
  let(:mock_curl) { instance_spy(Component::CurlComponent) }
  let(:mock_tar) { instance_spy(Component::TarComponent) }
  let(:mock_github) { instance_spy(Component::GithubComponent) }
  let(:bin_path) { '/home/user/.local/bin' }
  let(:man1_path) { '/home/user/.local/share/man/man1' }
  let(:zsh_completions_path) { '/home/user/.local/share/zsh/site-functions' }
  let(:bash_completions_path) { '/home/user/.local/share/bash-completion/completions' }

  before do
    allow(bat).to receive(:logger).and_return(null_logger)
    allow(bat).to receive(:curl).and_return(mock_curl)
    allow(bat).to receive(:tar).and_return(mock_tar)
    allow(bat).to receive(:github).and_return(mock_github)

    mock_config = instance_double(Components::Configuration)
    allow(mock_config).to receive(:tmp).and_return('/tmp/test')
    allow(mock_config).to receive(:bin).and_return(bin_path)
    allow(mock_config).to receive(:man1).and_return(man1_path)
    allow(mock_config).to receive(:zsh_completions).and_return(zsh_completions_path)
    allow(mock_config).to receive(:bash_completions).and_return(bash_completions_path)
    
    stub_const("#{described_class}::CONFIG", mock_config)
  end

  describe '#available?' do
    it 'returns true when bat command is available' do
      # Give
      allow(bat)
        .to receive(:system)
        .with('bat', '--version', out: File::NULL, err: File::NULL)
        .and_return(true)
      
      # When
      available = bat.available?
      
      # Then
      expect(available).to be true
    end

    it 'returns false when bat command is missing' do
      # Given
      allow(bat)
        .to receive(:system)
        .with('bat', '--version', out: File::NULL, err: File::NULL)
        .and_return(false)
      # When
      available = bat.available?

      # Then
      expect(available).to be false
    end
  end

  describe '#version' do
    it 'returns the installed bat version' do
      status = instance_double(Process::Status, success?: true)
      allow(Open3).to receive(:capture2)
        .with('bat', '--version')
        .and_return(["bat 0.21.0 (405edf)\n", status])
      
      expect(bat.version).to eq('0.21.0')
    end

    it 'returns nil when command fails' do
      status = instance_double(Process::Status, success?: false)
      allow(Open3).to receive(:capture2)
        .with('bat', '--version')
        .and_return(["Unknown result", status])
      
      expect(bat.version).to be_nil
    end
    
    it 'returns nil when bat is not installed' do
      allow(Open3).to receive(:capture2)
        .with('bat', '--version')
        .and_raise(Errno::ENOENT)
      
      expect(bat.version).to be_nil
    end
  end

  describe '#installed?' do
    it 'returns true if bat is installed' do
      allow(bat).to receive(:available?).and_return(true)
      allow(bat).to receive(:version).and_return("0.21.0")

      expect(bat.installed?).to be true
    end

    it 'returns false if bat is not installed' do
      allow(bat).to receive(:available?).and_return(false)
      allow(bat).to receive(:version).and_return(nil)

      expect(bat.installed?).to be false
    end
  end

  # Skip test 'install'

  describe '#install!' do
    it 'installs bat' do
      allow(mock_github).to receive(:get_latest_release_tag).and_return('0.21.0')
      allow(mock_github)
        .to receive(:get_latest_release_asset_download_url)
        .and_return('https://github.com/sharkdp/bat/releases/download/0.21.0/bat-0.21.0-x86_64-unknown-linux-musl.tar.gz')
      allow(mock_curl).to receive(:download).and_return(["", "", instance_double(Process::Status, success?: true)])
      allow(mock_tar).to receive(:extract).and_return(["", "", instance_double(Process::Status, success?: true)])
      allow(bat).to receive(:setup_man_page).and_return(["", "", instance_double(Process::Status, success?: true)])
      allow(bat).to receive(:setup_completions).and_return(["", "", instance_double(Process::Status, success?: true)])
      allow(bat).to receive(:runCmd)
        .with('cp', anything, anything)
        .and_return(["", "", instance_double(Process::Status, success?: true)])

      bat.install!

      expect(mock_github).to have_received(:get_latest_release_tag)
      expect(mock_github).to have_received(:get_latest_release_asset_download_url)
      expect(mock_curl).to have_received(:download)
      expect(mock_tar).to have_received(:extract)
      expect(bat).to have_received(:setup_man_page)
      expect(bat).to have_received(:setup_completions)
    end
  end

  describe '#setup_man_page' do
    before do
      stub_const("#{described_class}::TMP_DIR_PATH", '/tmp/test/bat-assets')
      allow(FileUtils).to receive(:mkdir_p)
      allow(bat).to receive(:runCmd).and_return(["", "", instance_double(Process::Status, success?: true)])
    end

    it 'creates directory and copies bat.1' do
      bat.send(:setup_man_page)

      expect(FileUtils).to have_received(:mkdir_p).with(man1_path)
      expect(bat).to have_received(:runCmd).with('cp', '/tmp/test/bat-assets/bat.1', "#{man1_path}/bat.1")
    end
  end

  describe '#setup_completions' do
    before do
      stub_const("#{described_class}::TMP_DIR_PATH", '/tmp/test/bat-assets')
      allow(FileUtils).to receive(:mkdir_p)
      allow(bat).to receive(:runCmd).and_return(["", "", instance_double(Process::Status, success?: true)])
    end

    it 'creates directories and copies completion files' do
      bat.send(:setup_completions)

      expect(FileUtils).to have_received(:mkdir_p).with(zsh_completions_path)
      expect(FileUtils).to have_received(:mkdir_p).with(bash_completions_path)
      expect(bat).to have_received(:runCmd).with('cp', '/tmp/test/bat-assets/autocomplete/bat.zsh', "#{zsh_completions_path}/_bat")
      expect(bat).to have_received(:runCmd).with('cp', '/tmp/test/bat-assets/autocomplete/bat.bash', "#{bash_completions_path}/bat")
    end
  end
end
