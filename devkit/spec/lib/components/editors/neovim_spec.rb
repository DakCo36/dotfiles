require "spec_helper"
require "components/editors/neovim"

RSpec.describe Component::NeovimComponent do
  subject(:neovim) { described_class.instance }

  let(:null_logger) { instance_spy(Logger) }
  let(:mock_curl) { instance_spy(Component::CurlComponent) }
  let(:mock_tar) { instance_spy(Component::TarComponent) }
  let(:mock_github) { instance_spy(Component::GithubComponent) }
  let(:mock_python) { instance_spy(Component::PythonComponent) }
  let(:home_path) { "/home/user" }
  let(:local_path) { "/home/user/.local" }

  before do
    allow(neovim).to receive(:logger).and_return(null_logger)
    allow(neovim).to receive(:curl).and_return(mock_curl)
    allow(neovim).to receive(:tar).and_return(mock_tar)
    allow(neovim).to receive(:github).and_return(mock_github)
    allow(neovim).to receive(:python).and_return(mock_python)

    mock_config = instance_double(Components::Configuration)
    allow(mock_config).to receive(:tmp).and_return("/tmp/test")
    allow(mock_config).to receive(:local).and_return(local_path)
    allow(mock_config).to receive(:home).and_return(home_path)

    stub_const("#{described_class}::CONFIG", mock_config)
  end

  describe "#available?" do
    it "returns true when nvim command is available" do
      allow(neovim)
        .to receive(:system)
        .with("nvim", "--version", out: File::NULL, err: File::NULL)
        .and_return(true)

      expect(neovim.available?).to be true
    end

    it "returns false when nvim command is missing" do
      allow(neovim)
        .to receive(:system)
        .with("nvim", "--version", out: File::NULL, err: File::NULL)
        .and_return(false)

      expect(neovim.available?).to be false
    end
  end

  describe "#version" do
    it "returns the installed neovim version" do
      status = instance_double(Process::Status, success?: true)
      allow(Open3).to receive(:capture2)
        .with("nvim", "--version")
        .and_return(["NVIM v0.10.0\nBuild type: Release\n", status])

      expect(neovim.version).to eq("0.10.0")
    end

    it "returns nil when command fails" do
      status = instance_double(Process::Status, success?: false)
      allow(Open3).to receive(:capture2)
        .with("nvim", "--version")
        .and_return(["Unknown result", status])

      expect(neovim.version).to be_nil
    end

    it "returns nil when nvim is not installed" do
      allow(Open3).to receive(:capture2)
        .with("nvim", "--version")
        .and_raise(Errno::ENOENT)

      expect(neovim.version).to be_nil
    end
  end

  describe "#installed?" do
    it "returns true if neovim is installed" do
      allow(neovim).to receive(:available?).and_return(true)
      allow(neovim).to receive(:version).and_return("0.10.0")

      expect(neovim.installed?).to be true
    end

    it "returns false if neovim is not installed" do
      allow(neovim).to receive(:available?).and_return(false)
      allow(neovim).to receive(:version).and_return(nil)

      expect(neovim.installed?).to be false
    end
  end

  describe "#latest_version" do
    it "returns the latest version from GitHub" do
      allow(mock_github).to receive(:get_latest_release_tag).and_return("v0.10.0")

      expect(neovim.latest_version).to eq("0.10.0")
    end

    it "strips the v prefix from the tag" do
      allow(mock_github).to receive(:get_latest_release_tag).and_return("v0.10.0")

      expect(neovim.latest_version).to eq("0.10.0")
    end

    it "returns nil on error" do
      allow(mock_github).to receive(:get_latest_release_tag).and_raise(StandardError, "API error")

      expect(neovim.latest_version).to be_nil
    end
  end

  describe "#install" do
    context "when already installed" do
      it "does nothing" do
        allow(neovim).to receive(:installed?).and_return(true)
        allow(neovim).to receive(:install!)

        neovim.install

        expect(neovim).not_to have_received(:install!)
      end
    end

    context "when not installed" do
      it "calls install!" do
        allow(neovim).to receive(:installed?).and_return(false)
        allow(neovim).to receive(:install!)

        neovim.install

        expect(neovim).to have_received(:install!)
      end
    end
  end

  describe "#install_vim_plug" do
    let(:plug_path) { "/home/user/.vim/autoload/plug.vim" }

    context "when vim-plug already exists" do
      it "skips installation" do
        allow(File).to receive(:exist?).with(plug_path).and_return(true)

        neovim.send(:install_vim_plug)

        expect(mock_curl).not_to have_received(:download)
      end
    end

    context "when vim-plug does not exist" do
      it "downloads and installs vim-plug" do
        allow(File).to receive(:exist?).with(plug_path).and_return(false)
        allow(FileUtils).to receive(:mkdir_p)
        allow(mock_curl).to receive(:download)

        neovim.send(:install_vim_plug)

        expect(FileUtils).to have_received(:mkdir_p).with(File.dirname(plug_path))
        expect(mock_curl).to have_received(:download).with(described_class::VIM_PLUG_URL, plug_path)
      end
    end
  end

  describe "#backup_if_exists" do
    it "creates backup when file exists" do
      file_path = "/home/user/.vimrc"
      allow(File).to receive(:exist?).with(file_path).and_return(true)
      allow(FileUtils).to receive(:cp)

      neovim.send(:backup_if_exists, file_path)

      expect(FileUtils).to have_received(:cp).with(file_path, match(/\.backup_\d{14}$/))
    end

    it "does nothing when file does not exist" do
      file_path = "/home/user/.vimrc"
      allow(File).to receive(:exist?).with(file_path).and_return(false)
      allow(FileUtils).to receive(:cp)

      neovim.send(:backup_if_exists, file_path)

      expect(FileUtils).not_to have_received(:cp)
    end
  end
end
