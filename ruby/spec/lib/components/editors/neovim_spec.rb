require 'spec_helper'
require 'components/editors/neovim'

RSpec.describe Component::NeovimComponent do
  subject(:neovim) { described_class.instance }
  let(:null_logger) { instance_spy(Logger) }
  let(:mock_curl) { instance_spy(Component::CurlComponent) }
  let(:mock_tar) { instance_spy(Component::TarComponent) }
  let(:mock_github) { instance_spy(Component::GithubComponent) }
  let(:home_path) { '/home/user' }
  let(:bin_path) { '/home/user/.local/bin' }
  let(:local_path) { '/home/user/.local' }
  let(:man1_path) { '/home/user/.local/share/man/man1' }

  before do
    allow(neovim).to receive(:logger).and_return(null_logger)
    allow(neovim).to receive(:curl).and_return(mock_curl)
    allow(neovim).to receive(:tar).and_return(mock_tar)
    allow(neovim).to receive(:github).and_return(mock_github)

    mock_config = instance_double(Components::Configuration)
    allow(mock_config).to receive(:tmp).and_return('/tmp/test')
    allow(mock_config).to receive(:home).and_return(home_path)
    allow(mock_config).to receive(:bin).and_return(bin_path)
    allow(mock_config).to receive(:local).and_return(local_path)
    allow(mock_config).to receive(:man1).and_return(man1_path)
    allow(mock_config).to receive(:contract_path) { |path| path.sub(home_path, '$HOME') }

    stub_const("#{described_class}::CONFIG", mock_config)
  end

  describe '#available?' do
    it 'returns true when nvim command is available' do
      # Given
      allow(neovim)
        .to receive(:system)
        .with('nvim', '--version', out: File::NULL, err: File::NULL)
        .and_return(true)

      # When
      available = neovim.available?

      # Then
      expect(available).to be true
    end

    it 'returns false when nvim command is missing' do
      # Given
      allow(neovim)
        .to receive(:system)
        .with('nvim', '--version', out: File::NULL, err: File::NULL)
        .and_return(false)

      # When
      available = neovim.available?

      # Then
      expect(available).to be false
    end
  end

  describe '#version' do
    it 'returns the installed neovim version' do
      # Given: nvim --version 출력 형식 "NVIM v0.10.0\nBuild type: Release\n..."
      status = instance_double(Process::Status, success?: true)
      allow(Open3).to receive(:capture2)
        .with('nvim', '--version')
        .and_return(["NVIM v0.10.0\nBuild type: Release\n", status])

      # When
      version = neovim.version

      # Then
      expect(version).to eq('0.10.0')
    end

    it 'returns nil when command fails' do
      # Given
      status = instance_double(Process::Status, success?: false)
      allow(Open3).to receive(:capture2)
        .with('nvim', '--version')
        .and_return(["Unknown result", status])

      # When
      version = neovim.version

      # Then
      expect(version).to be_nil
    end

    it 'returns nil when nvim is not installed' do
      # Given
      allow(Open3).to receive(:capture2)
        .with('nvim', '--version')
        .and_raise(Errno::ENOENT)

      # When
      version = neovim.version

      # Then
      expect(version).to be_nil
    end
  end

  describe '#installed?' do
    it 'returns true if neovim is installed' do
      # Given
      allow(neovim).to receive(:available?).and_return(true)
      allow(neovim).to receive(:version).and_return("0.10.0")

      # When & Then
      expect(neovim.installed?).to be true
    end

    it 'returns false if neovim is not installed' do
      # Given
      allow(neovim).to receive(:available?).and_return(false)
      allow(neovim).to receive(:version).and_return(nil)

      # When & Then
      expect(neovim.installed?).to be false
    end
  end

  describe '#install' do
    it 'skips installation if neovim is already installed' do
      # Given
      allow(neovim).to receive(:installed?).and_return(true)
      allow(neovim).to receive(:version).and_return("0.10.0")
      allow(neovim).to receive(:install!)

      # When
      neovim.install

      # Then
      expect(neovim).not_to have_received(:install!)
    end

    it 'calls install! if neovim is not installed' do
      # Given
      allow(neovim).to receive(:installed?).and_return(false)
      allow(neovim).to receive(:install!)

      # When
      neovim.install

      # Then
      expect(neovim).to have_received(:install!)
    end
  end

  describe '#install!' do
    before do
      allow(neovim).to receive(:install_neovim)
      allow(neovim).to receive(:install_vim_plug)
    end

    it 'installs neovim and vim-plug' do
      # When
      neovim.install!

      # Then
      expect(neovim).to have_received(:install_neovim)
      expect(neovim).to have_received(:install_vim_plug)
    end
  end

  describe '#install_neovim (private)' do
    before do
      stub_const("#{described_class}::TMP_DIR_PATH", '/tmp/test/nvim-assets')
      stub_const("#{described_class}::EXTRACTED_BIN_PATH", '/tmp/test/nvim-assets/bin')
      stub_const("#{described_class}::EXTRACTED_LIB_PATH", '/tmp/test/nvim-assets/lib')
      stub_const("#{described_class}::EXTRACTED_SHARE_PATH", '/tmp/test/nvim-assets/share')
      stub_const("#{described_class}::EXTRACTED_MAN_PATH", '/tmp/test/nvim-assets/man/man1')

      allow(mock_github).to receive(:get_latest_release_tag).and_return('v0.10.0')
      allow(mock_github)
        .to receive(:get_latest_release_asset_download_url)
        .with('neovim', 'neovim', 'nvim-linux-x86_64\\.tar\\.gz$')
        .and_return('https://github.com/neovim/neovim/releases/download/v0.10.0/nvim-linux-x86_64.tar.gz')
      allow(mock_curl).to receive(:download)
      allow(mock_tar).to receive(:extract)
      allow(FileUtils).to receive(:mkdir_p)
      allow(FileUtils).to receive(:cp_r)
      allow(Dir).to receive(:exist?).and_return(true)
      allow(Dir).to receive(:glob).and_return([])
      allow(File).to receive(:exist?).and_return(true)
      allow(neovim).to receive(:runCmd).and_return(["", "", instance_double(Process::Status, success?: true)])
    end

    it 'downloads and extracts neovim from GitHub releases' do
      # When
      neovim.send(:install_neovim)

      # Then
      expect(mock_github).to have_received(:get_latest_release_tag).with('neovim', 'neovim')
      expect(mock_github).to have_received(:get_latest_release_asset_download_url)
      expect(mock_curl).to have_received(:download)
      expect(mock_tar).to have_received(:extract)
    end

    it 'copies nvim binary to bin directory' do
      # When
      neovim.send(:install_neovim)

      # Then
      expect(neovim).to have_received(:runCmd).with(
        'cp',
        '/tmp/test/nvim-assets/bin/nvim',
        "#{bin_path}/nvim"
      )
    end
  end

  describe '#install_vim_plug (private)' do
    let(:vim_autoload_path) { '/home/user/.vim/autoload' }
    let(:nvim_autoload_path) { '/home/user/.local/share/nvim/site/autoload' }

    before do
      stub_const("#{described_class}::VIM_AUTOLOAD_PATH", vim_autoload_path)
      stub_const("#{described_class}::NVIM_AUTOLOAD_PATH", nvim_autoload_path)
      allow(FileUtils).to receive(:mkdir_p)
      allow(mock_curl).to receive(:download)
    end

    it 'installs vim-plug for both vim and neovim' do
      # When
      neovim.send(:install_vim_plug)

      # Then
      expect(FileUtils).to have_received(:mkdir_p).with(vim_autoload_path)
      expect(FileUtils).to have_received(:mkdir_p).with(nvim_autoload_path)
      expect(mock_curl).to have_received(:download).twice
    end
  end
end
