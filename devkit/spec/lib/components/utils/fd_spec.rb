require "spec_helper"
require "components/utils/fd"

RSpec.describe Component::FdComponent do
  subject(:fd) { described_class.instance }
  let(:null_logger) { instance_spy(Logger) }
  let(:mock_curl) { instance_spy(Component::CurlComponent) }
  let(:mock_tar) { instance_spy(Component::TarComponent) }
  let(:mock_github) { instance_spy(Component::GithubComponent) }
  let(:mock_config) { instance_double(Components::Configuration) }
  let(:bin_path) { "/home/user/.local/bin" }
  let(:tmp_path) { "/tmp/test" }
  let(:man1_path) { "/home/user/.local/share/man/man1" }
  let(:zsh_completions_path) { "/home/user/.local/share/zsh/site-functions" }
  let(:bash_completions_path) { "/home/user/.local/share/bash-completion/completions" }

  before do
    allow(fd).to receive(:logger).and_return(null_logger)
    allow(fd).to receive(:curl).and_return(mock_curl)
    allow(fd).to receive(:tar).and_return(mock_tar)
    allow(fd).to receive(:github).and_return(mock_github)
    allow(fd).to receive(:config).and_return(mock_config)

    allow(mock_config).to receive(:tmp).and_return(tmp_path)
    allow(mock_config).to receive(:bin).and_return(bin_path)
    allow(mock_config).to receive(:man1).and_return(man1_path)
    allow(mock_config).to receive(:zsh_completions).and_return(zsh_completions_path)
    allow(mock_config).to receive(:bash_completions).and_return(bash_completions_path)
    allow(mock_config).to receive(:arch).and_return("x86_64")
    allow(mock_config).to receive(:os).and_return("linux-gnu")
    allow(mock_config).to receive(:component_config).with("fd").and_return({ "version" => "latest", "fallback_version" => "10.2.0" })
  end

  describe "#available?" do
    it "returns true when fd command is available" do
      # Given
      allow(fd)
        .to receive(:system)
        .with("fd", "--version", out: File::NULL, err: File::NULL)
        .and_return(true)

      # When
      result = fd.available?

      # Then
      expect(result).to be true
    end

    it "returns false when fd command is missing" do
      # Given
      allow(fd)
        .to receive(:system)
        .with("fd", "--version", out: File::NULL, err: File::NULL)
        .and_return(false)

      # When
      result = fd.available?

      # Then
      expect(result).to be false
    end
  end

  describe "#version" do
    it "returns the installed fd version" do
      # Given
      status = instance_double(Process::Status, success?: true)
      allow(Open3).to receive(:capture2)
        .with("fd", "--version")
        .and_return(["fd 10.3.0\n", status])

      # When
      result = fd.version

      # Then
      expect(result).to eq("10.3.0")
    end

    it "returns nil when command fails" do
      # Given
      status = instance_double(Process::Status, success?: false)
      allow(Open3).to receive(:capture2)
        .with("fd", "--version")
        .and_return(["Unknown result", status])

      # When
      result = fd.version

      # Then
      expect(result).to be_nil
    end

    it "returns nil when fd is not installed" do
      # Given
      allow(Open3).to receive(:capture2)
        .with("fd", "--version")
        .and_raise(Errno::ENOENT)

      # When
      result = fd.version

      # Then
      expect(result).to be_nil
    end
  end

  describe "#installed?" do
    it "returns true if fd is installed" do
      # Given
      allow(fd).to receive(:available?).and_return(true)
      allow(fd).to receive(:version).and_return("10.3.0")

      # When
      result = fd.installed?

      # Then
      expect(result).to be true
    end

    it "returns false if fd is not installed" do
      # Given
      allow(fd).to receive(:available?).and_return(false)
      allow(fd).to receive(:version).and_return(nil)

      # When
      result = fd.installed?

      # Then
      expect(result).to be false
    end
  end

  describe "#latest_version" do
    it "returns the latest version from GitHub" do
      # Given
      allow(mock_github).to receive(:get_latest_release_tag).with("sharkdp", "fd").and_return("v10.3.0")

      # When
      result = fd.latest_version

      # Then
      expect(result).to eq("10.3.0")
    end

    it "returns nil when API call fails" do
      # Given
      allow(mock_github).to receive(:get_latest_release_tag).and_raise(StandardError.new("API error"))

      # When
      result = fd.latest_version

      # Then
      expect(result).to be_nil
    end
  end

  describe "#install" do
    it "skips installation when already installed" do
      # Given
      allow(fd).to receive(:installed?).and_return(true)
      allow(fd).to receive(:install!)

      # When
      fd.install

      # Then
      expect(fd).not_to have_received(:install!)
      expect(null_logger).to have_received(:info).with("fd already installed.")
    end

    it "calls install! when not installed" do
      # Given
      allow(fd).to receive(:installed?).and_return(false)
      allow(fd).to receive(:install!)

      # When
      fd.install

      # Then
      expect(fd).to have_received(:install!)
    end
  end

  describe "#install!" do
    before do
      allow(mock_github).to receive(:get_latest_release_tag).and_return("v10.3.0")
      allow(mock_github)
        .to receive(:get_latest_release_asset_download_url)
        .and_return("https://github.com/sharkdp/fd/releases/download/v10.3.0/fd-v10.3.0-x86_64-unknown-linux-musl.tar.gz")
      allow(mock_curl).to receive(:download)
      allow(mock_tar).to receive(:extract)
      allow(fd).to receive(:runCmd)
      allow(FileUtils).to receive(:mkdir_p)
    end

    it "downloads and installs fd" do
      # When
      fd.install!

      # Then
      expect(mock_github).to have_received(:get_latest_release_tag)
      expect(mock_github).to have_received(:get_latest_release_asset_download_url)
      expect(mock_curl).to have_received(:download).with(anything, "#{tmp_path}/fd-assets.tar.gz")
      expect(mock_tar).to have_received(:extract).with("#{tmp_path}/fd-assets.tar.gz", "#{tmp_path}/fd-assets", 1)
      expect(fd).to have_received(:runCmd).with("cp", "#{tmp_path}/fd-assets/fd", "#{bin_path}/fd")
    end
  end

  describe "#setup_man_page" do
    before do
      allow(FileUtils).to receive(:mkdir_p)
      allow(fd).to receive(:runCmd)
    end

    it "creates directory and copies fd.1" do
      # When
      fd.send(:setup_man_page)

      # Then
      expect(FileUtils).to have_received(:mkdir_p).with(man1_path)
      expect(fd).to have_received(:runCmd).with("cp", "#{tmp_path}/fd-assets/fd.1", "#{man1_path}/fd.1")
    end
  end

  describe "#setup_completions" do
    before do
      allow(FileUtils).to receive(:mkdir_p)
      allow(fd).to receive(:runCmd)
    end

    it "creates directories and copies completion files" do
      # When
      fd.send(:setup_completions)

      # Then
      expect(FileUtils).to have_received(:mkdir_p).with(zsh_completions_path)
      expect(FileUtils).to have_received(:mkdir_p).with(bash_completions_path)
      expect(fd).to have_received(:runCmd).with("cp", "#{tmp_path}/fd-assets/autocomplete/_fd",
                                                "#{zsh_completions_path}/_fd")
      expect(fd).to have_received(:runCmd).with("cp", "#{tmp_path}/fd-assets/autocomplete/fd.bash",
                                                "#{bash_completions_path}/fd")
    end
  end

  describe "#resolve_version_and_url" do
    context "when specific version is configured" do
      before do
        allow(mock_config).to receive(:component_config)
          .with("fd")
          .and_return({ "version" => "10.2.0" })
        allow(mock_github).to receive(:build_release_asset_url)
          .and_return("https://github.com/sharkdp/fd/releases/download/v10.2.0/fd-v10.2.0-x86_64-unknown-linux-musl.tar.gz")
      end

      it "returns URL without API call" do
        tag, url = fd.send(:resolve_version_and_url)
        expect(tag).to eq("v10.2.0")
        expect(url).to include("v10.2.0")
        expect(mock_github).not_to have_received(:get_latest_release_tag)
      end
    end

    context "when latest version and API fails with fallback" do
      before do
        allow(mock_config).to receive(:component_config)
          .with("fd")
          .and_return({ "version" => "latest", "fallback_version" => "10.2.0" })
        allow(mock_github).to receive(:get_latest_release_tag).and_raise(StandardError, "API rate limit")
        allow(mock_github).to receive(:build_release_asset_url)
          .and_return("https://github.com/sharkdp/fd/releases/download/v10.2.0/fd-fallback.tar.gz")
      end

      it "uses fallback version" do
        tag, _url = fd.send(:resolve_version_and_url)
        expect(tag).to eq("v10.2.0")
      end
    end

    context "when API fails without fallback" do
      before do
        allow(mock_config).to receive(:component_config)
          .with("fd")
          .and_return({ "version" => "latest", "fallback_version" => nil })
        allow(mock_github).to receive(:get_latest_release_tag).and_raise(StandardError, "API rate limit")
      end

      it "raises error" do
        expect { fd.send(:resolve_version_and_url) }
          .to raise_error(/no fallback_version configured/)
      end
    end
  end
end
