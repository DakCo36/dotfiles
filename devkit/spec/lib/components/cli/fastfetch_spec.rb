require "spec_helper"
require "components/cli/fastfetch"

RSpec.describe Component::FastfetchComponent do
  subject(:fastfetch) { described_class.instance }
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
    allow(fastfetch).to receive(:logger).and_return(null_logger)
    allow(fastfetch).to receive(:curl).and_return(mock_curl)
    allow(fastfetch).to receive(:tar).and_return(mock_tar)
    allow(fastfetch).to receive(:github).and_return(mock_github)
    allow(fastfetch).to receive(:config).and_return(mock_config)

    allow(mock_config).to receive(:tmp).and_return(tmp_path)
    allow(mock_config).to receive(:bin).and_return(bin_path)
    allow(mock_config).to receive(:man1).and_return(man1_path)
    allow(mock_config).to receive(:zsh_completions).and_return(zsh_completions_path)
    allow(mock_config).to receive(:bash_completions).and_return(bash_completions_path)
    allow(mock_config).to receive(:arch).and_return("x86_64")
    allow(mock_config).to receive(:os).and_return("linux-gnu")
    allow(mock_config).to receive(:component_config).with("fastfetch").and_return({ "version" => "latest", "fallback_version" => "2.30.1" })
  end

  describe "#available?" do
    it "returns true when fastfetch command is available" do
      # Given
      allow(fastfetch)
        .to receive(:system)
        .with("fastfetch", "--version", out: File::NULL, err: File::NULL)
        .and_return(true)

      # When
      result = fastfetch.available?

      # Then
      expect(result).to be true
    end

    it "returns false when fastfetch command is missing" do
      # Given
      allow(fastfetch)
        .to receive(:system)
        .with("fastfetch", "--version", out: File::NULL, err: File::NULL)
        .and_return(false)

      # When
      result = fastfetch.available?

      # Then
      expect(result).to be false
    end
  end

  describe "#version" do
    it "returns the installed fastfetch version" do
      # Given
      status = instance_double(Process::Status, success?: true)
      allow(Open3).to receive(:capture2)
        .with("fastfetch", "--version")
        .and_return(["fastfetch 2.57.1 (Linux)\n", status])

      # When
      result = fastfetch.version

      # Then
      expect(result).to eq("2.57.1")
    end

    it "returns nil when command fails" do
      # Given
      status = instance_double(Process::Status, success?: false)
      allow(Open3).to receive(:capture2)
        .with("fastfetch", "--version")
        .and_return(["Unknown result", status])

      # When
      result = fastfetch.version

      # Then
      expect(result).to be_nil
    end

    it "returns nil when fastfetch is not installed" do
      # Given
      allow(Open3).to receive(:capture2)
        .with("fastfetch", "--version")
        .and_raise(Errno::ENOENT)

      # When
      result = fastfetch.version

      # Then
      expect(result).to be_nil
    end
  end

  describe "#installed?" do
    it "returns true if fastfetch is installed" do
      # Given
      allow(fastfetch).to receive(:available?).and_return(true)
      allow(fastfetch).to receive(:version).and_return("2.57.1")

      # When
      result = fastfetch.installed?

      # Then
      expect(result).to be true
    end

    it "returns false if fastfetch is not installed" do
      # Given
      allow(fastfetch).to receive(:available?).and_return(false)
      allow(fastfetch).to receive(:version).and_return(nil)

      # When
      result = fastfetch.installed?

      # Then
      expect(result).to be false
    end
  end

  describe "#latest_version" do
    it "returns the latest version from GitHub" do
      # Given
      allow(mock_github).to receive(:get_latest_release_tag).with("fastfetch-cli", "fastfetch").and_return("2.57.1")

      # When
      result = fastfetch.latest_version

      # Then
      expect(result).to eq("2.57.1")
    end

    it "returns nil when API call fails" do
      # Given
      allow(mock_github).to receive(:get_latest_release_tag).and_raise(StandardError.new("API error"))

      # When
      result = fastfetch.latest_version

      # Then
      expect(result).to be_nil
    end
  end

  describe "#install" do
    it "skips installation when already installed" do
      # Given
      allow(fastfetch).to receive(:installed?).and_return(true)
      allow(fastfetch).to receive(:install!)

      # When
      fastfetch.install

      # Then
      expect(fastfetch).not_to have_received(:install!)
      expect(null_logger).to have_received(:info).with("fastfetch already installed.")
    end

    it "calls install! when not installed" do
      # Given
      allow(fastfetch).to receive(:installed?).and_return(false)
      allow(fastfetch).to receive(:install!)

      # When
      fastfetch.install

      # Then
      expect(fastfetch).to have_received(:install!)
    end
  end

  describe "#install!" do
    before do
      allow(mock_github).to receive(:get_latest_release_tag).and_return("2.57.1")
      allow(mock_github)
        .to receive(:get_latest_release_asset_download_url)
        .and_return("https://github.com/fastfetch-cli/fastfetch/releases/download/2.57.1/fastfetch-linux-amd64.tar.gz")
      allow(mock_curl).to receive(:download)
      allow(mock_tar).to receive(:extract)
      allow(fastfetch).to receive(:runCmd)
      allow(FileUtils).to receive(:mkdir_p)
    end

    it "downloads and installs fastfetch" do
      # When
      fastfetch.install!

      # Then
      expect(mock_github).to have_received(:get_latest_release_tag)
      expect(mock_github).to have_received(:get_latest_release_asset_download_url)
      expect(mock_curl).to have_received(:download).with(anything, "#{tmp_path}/fastfetch-assets.tar.gz")
      expect(mock_tar).to have_received(:extract).with("#{tmp_path}/fastfetch-assets.tar.gz", "#{tmp_path}/fastfetch-assets", 1)
      expect(fastfetch).to have_received(:runCmd).with("cp", "#{tmp_path}/fastfetch-assets/usr/bin/fastfetch", "#{bin_path}/fastfetch")
      expect(fastfetch).to have_received(:runCmd).with("cp", "#{tmp_path}/fastfetch-assets/usr/bin/flashfetch", "#{bin_path}/flashfetch")
    end
  end

  describe "#setup_man_page" do
    before do
      allow(FileUtils).to receive(:mkdir_p)
      allow(fastfetch).to receive(:runCmd)
    end

    it "creates directory and copies fastfetch.1" do
      # When
      fastfetch.send(:setup_man_page)

      # Then
      expect(FileUtils).to have_received(:mkdir_p).with(man1_path)
      expect(fastfetch).to have_received(:runCmd).with(
        "cp",
        "#{tmp_path}/fastfetch-assets/usr/share/man/man1/fastfetch.1",
        "#{man1_path}/fastfetch.1"
      )
    end
  end

  describe "#setup_completions" do
    before do
      allow(FileUtils).to receive(:mkdir_p)
      allow(fastfetch).to receive(:runCmd)
    end

    it "creates directories and copies completion files" do
      # When
      fastfetch.send(:setup_completions)

      # Then
      expect(FileUtils).to have_received(:mkdir_p).with(zsh_completions_path)
      expect(FileUtils).to have_received(:mkdir_p).with(bash_completions_path)
      expect(fastfetch).to have_received(:runCmd).with(
        "cp",
        "#{tmp_path}/fastfetch-assets/usr/share/zsh/site-functions/_fastfetch",
        "#{zsh_completions_path}/_fastfetch"
      )
      expect(fastfetch).to have_received(:runCmd).with(
        "cp",
        "#{tmp_path}/fastfetch-assets/usr/share/bash-completion/completions/fastfetch",
        "#{bash_completions_path}/fastfetch"
      )
    end
  end

  describe "#resolve_version_and_url" do
    context "when specific version is configured" do
      before do
        allow(mock_config).to receive(:component_config)
          .with("fastfetch")
          .and_return({ "version" => "2.30.0" })
        allow(mock_github).to receive(:build_release_asset_url)
          .and_return("https://github.com/fastfetch-cli/fastfetch/releases/download/2.30.0/fastfetch-linux-amd64.tar.gz")
      end

      it "returns URL without API call" do
        tag, url = fastfetch.send(:resolve_version_and_url)
        expect(tag).to eq("2.30.0")
        expect(url).to include("2.30.0")
        expect(mock_github).not_to have_received(:get_latest_release_tag)
      end
    end

    context "when latest version and API fails with fallback" do
      before do
        allow(mock_config).to receive(:component_config)
          .with("fastfetch")
          .and_return({ "version" => "latest", "fallback_version" => "2.30.1" })
        allow(mock_github).to receive(:get_latest_release_tag).and_raise(StandardError, "API rate limit")
        allow(mock_github).to receive(:build_release_asset_url)
          .and_return("https://github.com/fastfetch-cli/fastfetch/releases/download/2.30.1/fastfetch-fallback.tar.gz")
      end

      it "uses fallback version" do
        tag, _url = fastfetch.send(:resolve_version_and_url)
        expect(tag).to eq("2.30.1")
      end
    end

    context "when API fails without fallback" do
      before do
        allow(mock_config).to receive(:component_config)
          .with("fastfetch")
          .and_return({ "version" => "latest", "fallback_version" => nil })
        allow(mock_github).to receive(:get_latest_release_tag).and_raise(StandardError, "API rate limit")
      end

      it "raises error" do
        expect { fastfetch.send(:resolve_version_and_url) }
          .to raise_error(/no fallback_version configured/)
      end
    end
  end
end
