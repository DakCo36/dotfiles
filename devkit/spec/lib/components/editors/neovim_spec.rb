require "spec_helper"
require "components/editors/neovim"

RSpec.describe Component::NeovimComponent do
  subject(:neovim) { described_class.instance }

  let(:null_logger) { instance_spy(Logger) }
  let(:mock_curl) { instance_spy(Component::CurlComponent) }
  let(:mock_tar) { instance_spy(Component::TarComponent) }
  let(:mock_github) { instance_spy(Component::GithubComponent) }
  let(:mock_python) { instance_spy(Component::PythonComponent) }
  let(:mock_config) { instance_double(Components::Configuration) }
  let(:home_path) { "/home/user" }
  let(:local_path) { "/home/user/.local" }
  let(:tmp_path) { "/tmp/test" }

  before do
    allow(neovim).to receive(:logger).and_return(null_logger)
    allow(neovim).to receive(:curl).and_return(mock_curl)
    allow(neovim).to receive(:tar).and_return(mock_tar)
    allow(neovim).to receive(:github).and_return(mock_github)
    allow(neovim).to receive(:python).and_return(mock_python)
    allow(neovim).to receive(:config).and_return(mock_config)

    allow(mock_config).to receive(:tmp).and_return(tmp_path)
    allow(mock_config).to receive(:local).and_return(local_path)
    allow(mock_config).to receive(:home).and_return(home_path)
    allow(mock_config).to receive(:arch).and_return("x86_64")
    allow(mock_config).to receive(:os).and_return("linux-gnu")
    allow(mock_config).to receive(:component_config).with("neovim").and_return({ "version" => "latest", "fallback_version" => "0.10.0" })
  end

  describe "#available?" do
    it "returns true when nvim command is available" do
      # Given
      allow(neovim)
        .to receive(:system)
        .with("nvim", "--version", out: File::NULL, err: File::NULL)
        .and_return(true)

      # When
      result = neovim.available?

      # Then
      expect(result).to be true
    end

    it "returns false when nvim command is missing" do
      # Given
      allow(neovim)
        .to receive(:system)
        .with("nvim", "--version", out: File::NULL, err: File::NULL)
        .and_return(false)

      # When
      result = neovim.available?

      # Then
      expect(result).to be false
    end
  end

  describe "#target_asset_pattern" do
    context "when on macOS arm64 (Apple Silicon)" do
      it "returns the arm64 macOS asset pattern" do
        # Given
        allow(mock_config).to receive(:arch).and_return("arm64")
        allow(mock_config).to receive(:os).and_return("darwin23")

        # When
        result = neovim.send(:target_asset_pattern)

        # Then
        expect(result).to eq("nvim-macos-arm64\\.tar\\.gz")
      end
    end

    context "when on macOS x86_64 (Intel)" do
      it "returns the x86_64 macOS asset pattern" do
        # Given
        allow(mock_config).to receive(:arch).and_return("x86_64")
        allow(mock_config).to receive(:os).and_return("darwin21")

        # When
        result = neovim.send(:target_asset_pattern)

        # Then
        expect(result).to eq("nvim-macos-x86_64\\.tar\\.gz")
      end
    end

    context "when on Linux x86_64" do
      it "returns the x86_64 Linux asset pattern" do
        # Given
        allow(mock_config).to receive(:arch).and_return("x86_64")
        allow(mock_config).to receive(:os).and_return("linux-gnu")

        # When
        result = neovim.send(:target_asset_pattern)

        # Then
        expect(result).to eq("nvim-linux-x86_64\\.tar\\.gz")
      end
    end

    context "when on Linux arm64" do
      it "returns the arm64 Linux asset pattern" do
        # Given
        allow(mock_config).to receive(:arch).and_return("aarch64")
        allow(mock_config).to receive(:os).and_return("linux-gnu")

        # When
        result = neovim.send(:target_asset_pattern)

        # Then
        expect(result).to eq("nvim-linux-arm64\\.tar\\.gz")
      end
    end

    context "when on unsupported architecture" do
      it "raises an error" do
        # Given
        allow(mock_config).to receive(:arch).and_return("arm32")
        allow(mock_config).to receive(:os).and_return("linux-gnu")

        # When/Then
        expect { neovim.send(:target_asset_pattern) }.to raise_error("Unsupported architecture: arm32 on linux-gnu")
      end
    end
  end

  describe "#version" do
    it "returns the installed neovim version" do
      # Given
      status = instance_double(Process::Status, success?: true)
      allow(Open3).to receive(:capture2)
        .with("nvim", "--version")
        .and_return(["NVIM v0.10.0\nBuild type: Release\n", status])

      # When
      result = neovim.version

      # Then
      expect(result).to eq("0.10.0")
    end

    it "returns nil when command fails" do
      # Given
      status = instance_double(Process::Status, success?: false)
      allow(Open3).to receive(:capture2)
        .with("nvim", "--version")
        .and_return(["Unknown result", status])

      # When
      result = neovim.version

      # Then
      expect(result).to be_nil
    end

    it "returns nil when nvim is not installed" do
      # Given
      allow(Open3).to receive(:capture2)
        .with("nvim", "--version")
        .and_raise(Errno::ENOENT)

      # When
      result = neovim.version

      # Then
      expect(result).to be_nil
    end
  end

  describe "#installed?" do
    it "returns true if neovim is installed" do
      # Given
      allow(neovim).to receive(:available?).and_return(true)
      allow(neovim).to receive(:version).and_return("0.10.0")

      # When
      result = neovim.installed?

      # Then
      expect(result).to be true
    end

    it "returns false if neovim is not installed" do
      # Given
      allow(neovim).to receive(:available?).and_return(false)
      allow(neovim).to receive(:version).and_return(nil)

      # When
      result = neovim.installed?

      # Then
      expect(result).to be false
    end
  end

  describe "#latest_version" do
    it "returns the latest version from GitHub" do
      # Given
      allow(mock_github).to receive(:get_latest_release_tag).and_return("v0.10.0")

      # When
      result = neovim.latest_version

      # Then
      expect(result).to eq("0.10.0")
    end

    it "strips the v prefix from the tag" do
      # Given
      allow(mock_github).to receive(:get_latest_release_tag).and_return("v0.10.0")

      # When
      result = neovim.latest_version

      # Then
      expect(result).to eq("0.10.0")
    end

    it "returns nil on error" do
      # Given
      allow(mock_github).to receive(:get_latest_release_tag).and_raise(StandardError, "API error")

      # When
      result = neovim.latest_version

      # Then
      expect(result).to be_nil
    end
  end

  describe "#install" do
    let(:mock_node) { instance_spy(Component::NodeComponent) }

    before do
      allow(Component::CurlComponent).to receive(:instance).and_return(mock_curl)
      allow(Component::GithubComponent).to receive(:instance).and_return(mock_github)
      allow(Component::TarComponent).to receive(:instance).and_return(mock_tar)
      allow(Component::PythonComponent).to receive(:instance).and_return(mock_python)
      allow(Component::NodeComponent).to receive(:instance).and_return(mock_node)

      allow(mock_curl).to receive(:available?).and_return(true)
      allow(mock_github).to receive(:available?).and_return(true)
      allow(mock_tar).to receive(:available?).and_return(true)
      allow(mock_python).to receive(:available?).and_return(true)
      allow(mock_node).to receive(:available?).and_return(true)
    end

    context "when already installed" do
      it "does nothing" do
        # Given
        allow(neovim).to receive(:installed?).and_return(true)
        allow(neovim).to receive(:install!)

        # When
        neovim.install

        # Then
        expect(neovim).not_to have_received(:install!)
      end
    end

    context "when not installed" do
      it "calls install!" do
        # Given
        allow(neovim).to receive(:installed?).and_return(false)
        allow(neovim).to receive(:install!)

        # When
        neovim.install

        # Then
        expect(neovim).to have_received(:install!)
      end
    end
  end

  describe "#install_vim_plug" do
    let(:plug_path) { "/home/user/.vim/autoload/plug.vim" }

    context "when vim-plug already exists" do
      it "skips installation" do
        # Given
        allow(File).to receive(:exist?).with(plug_path).and_return(true)

        # When
        neovim.send(:install_vim_plug)

        # Then
        expect(mock_curl).not_to have_received(:download)
      end
    end

    context "when vim-plug does not exist" do
      it "downloads and installs vim-plug" do
        # Given
        allow(File).to receive(:exist?).with(plug_path).and_return(false)
        allow(FileUtils).to receive(:mkdir_p)
        allow(mock_curl).to receive(:download)

        # When
        neovim.send(:install_vim_plug)

        # Then
        expect(FileUtils).to have_received(:mkdir_p).with(File.dirname(plug_path))
        expect(mock_curl).to have_received(:download).with(described_class::VIM_PLUG_URL, plug_path)
      end
    end
  end

  describe "#backup_if_exists" do
    it "creates backup when file exists" do
      # Given
      file_path = "/home/user/.vimrc"
      allow(File).to receive(:exist?).with(file_path).and_return(true)
      allow(FileUtils).to receive(:cp)

      # When
      neovim.send(:backup_if_exists, file_path)

      # Then
      expect(FileUtils).to have_received(:cp).with(file_path, match(/\.backup_\d{14}$/))
    end

    it "does nothing when file does not exist" do
      # Given
      file_path = "/home/user/.vimrc"
      allow(File).to receive(:exist?).with(file_path).and_return(false)
      allow(FileUtils).to receive(:cp)

      # When
      neovim.send(:backup_if_exists, file_path)

      # Then
      expect(FileUtils).not_to have_received(:cp)
    end
  end

  describe "#resolve_version_and_url" do
    context "when specific version is configured" do
      before do
        allow(mock_config).to receive(:component_config)
          .with("neovim")
          .and_return({ "version" => "0.9.0" })
        allow(mock_github).to receive(:build_release_asset_url)
          .and_return("https://github.com/neovim/neovim/releases/download/v0.9.0/nvim-linux-x86_64.tar.gz")
      end

      it "returns URL without API call" do
        tag, url = neovim.send(:resolve_version_and_url)
        expect(tag).to eq("v0.9.0")
        expect(url).to include("v0.9.0")
        expect(mock_github).not_to have_received(:get_latest_release_tag)
      end
    end

    context "when latest version and API fails with fallback" do
      before do
        allow(mock_config).to receive(:component_config)
          .with("neovim")
          .and_return({ "version" => "latest", "fallback_version" => "0.10.0" })
        allow(mock_github).to receive(:get_latest_release_tag).and_raise(StandardError, "API rate limit")
        allow(mock_github).to receive(:build_release_asset_url)
          .and_return("https://github.com/neovim/neovim/releases/download/v0.10.0/nvim-fallback.tar.gz")
      end

      it "uses fallback version" do
        tag, _url = neovim.send(:resolve_version_and_url)
        expect(tag).to eq("v0.10.0")
      end
    end

    context "when API fails without fallback" do
      before do
        allow(mock_config).to receive(:component_config)
          .with("neovim")
          .and_return({ "version" => "latest", "fallback_version" => nil })
        allow(mock_github).to receive(:get_latest_release_tag).and_raise(StandardError, "API rate limit")
      end

      it "raises error" do
        expect { neovim.send(:resolve_version_and_url) }
          .to raise_error(/no fallback_version configured/)
      end
    end
  end
end
