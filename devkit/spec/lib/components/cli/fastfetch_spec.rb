require "spec_helper"
require "components/cli/fastfetch"

RSpec.describe Component::FastfetchComponent do
  subject(:fastfetch) { described_class.instance }
  let(:null_logger) { instance_spy(Logger) }
  let(:mock_curl) { instance_spy(Component::CurlComponent) }
  let(:mock_tar) { instance_spy(Component::TarComponent) }
  let(:mock_github) { instance_spy(Component::GithubComponent) }
  let(:mock_config) { instance_double(Components::Configuration::ComponentConfig) }
  let(:tmp_path) { "/tmp/test" }
  let(:bin_path) { "/home/user/.local/bin" }
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
  end

  describe "#available?" do
    it "returns true when fastfetch command is available" do
      # Given
      allow(fastfetch)
        .to receive(:system)
        .with("fastfetch", "--version", out: File::NULL, err: File::NULL)
        .and_return(true)

      # When
      available = fastfetch.available?

      # Then
      expect(available).to be true
    end

    it "returns false when fastfetch command is missing" do
      # Given
      allow(fastfetch)
        .to receive(:system)
        .with("fastfetch", "--version", out: File::NULL, err: File::NULL)
        .and_return(false)

      # When
      available = fastfetch.available?

      # Then
      expect(available).to be false
    end
  end

  describe "#version" do
    it "returns the installed fastfetch version" do
      # Given: fastfetch version output format "fastfetch 2.57.1 (Linux)"
      status = instance_double(Process::Status, success?: true)
      allow(Open3).to receive(:capture2)
        .with("fastfetch", "--version")
        .and_return(["fastfetch 2.57.1 (Linux)\n", status])

      # When
      version = fastfetch.version

      # Then
      expect(version).to eq("2.57.1")
    end

    it "returns nil when command fails" do
      # Given
      status = instance_double(Process::Status, success?: false)
      allow(Open3).to receive(:capture2)
        .with("fastfetch", "--version")
        .and_return(["Unknown result", status])

      # When
      version = fastfetch.version

      # Then
      expect(version).to be_nil
    end

    it "returns nil when fastfetch is not installed" do
      # Given
      allow(Open3).to receive(:capture2)
        .with("fastfetch", "--version")
        .and_raise(Errno::ENOENT)

      # When
      version = fastfetch.version

      # Then
      expect(version).to be_nil
    end
  end

  describe "#installed?" do
    it "returns true if fastfetch is installed" do
      # Given
      allow(fastfetch).to receive(:available?).and_return(true)
      allow(fastfetch).to receive(:version).and_return("2.57.1")

      # When & Then
      expect(fastfetch.installed?).to be true
    end

    it "returns false if fastfetch is not installed" do
      # Given
      allow(fastfetch).to receive(:available?).and_return(false)
      allow(fastfetch).to receive(:version).and_return(nil)

      # When & Then
      expect(fastfetch.installed?).to be false
    end
  end

  describe "#install!" do
    it "installs fastfetch from GitHub releases" do
      allow(mock_config).to receive(:version).and_return("latest")
      allow(mock_config).to receive(:fallback_version).and_return("2.34.1")
      allow(mock_config).to receive(:owner).and_return("fastfetch-cli")
      allow(mock_config).to receive(:repo).and_return("fastfetch")

      allow(mock_github).to receive(:download_asset)
      allow(mock_tar).to receive(:extract).and_return(["", "", instance_double(Process::Status, success?: true)])
      allow(fastfetch).to receive(:setup_man_page).and_return(["", "",
                                                               instance_double(Process::Status, success?: true)])
      allow(fastfetch).to receive(:setup_completions).and_return(["", "",
                                                                  instance_double(Process::Status, success?: true)])
      allow(fastfetch).to receive(:runCmd)
        .with("cp", anything, anything)
        .and_return(["", "", instance_double(Process::Status, success?: true)])

      fastfetch.install!

      expect(mock_github).to have_received(:download_asset).with(
        owner: "fastfetch-cli",
        repo: "fastfetch",
        version: "latest",
        fallback_version: "2.34.1",
        asset_pattern: "fastfetch-linux-amd64\\.tar\\.gz$",
        fallback_asset: "fastfetch-linux-amd64.tar.gz",
        destination: "/tmp/test/fastfetch-assets.tar.gz"
      )
      expect(mock_tar).to have_received(:extract)
      expect(fastfetch).to have_received(:setup_man_page)
      expect(fastfetch).to have_received(:setup_completions)
    end
  end

  describe "#setup_man_page" do
    before do
      allow(FileUtils).to receive(:mkdir_p)
      allow(fastfetch).to receive(:runCmd).and_return(["", "", instance_double(Process::Status, success?: true)])
    end

    it "creates directory and copies fastfetch.1" do
      # When
      fastfetch.send(:setup_man_page)

      # Then
      expect(FileUtils).to have_received(:mkdir_p).with(man1_path)
      expect(fastfetch).to have_received(:runCmd).with(
        "cp",
        "/tmp/test/fastfetch-assets/usr/share/man/man1/fastfetch.1",
        "#{man1_path}/fastfetch.1"
      )
    end
  end

  describe "#setup_completions" do
    before do
      allow(FileUtils).to receive(:mkdir_p)
      allow(fastfetch).to receive(:runCmd).and_return(["", "", instance_double(Process::Status, success?: true)])
    end

    it "creates directories and copies completion files" do
      # When
      fastfetch.send(:setup_completions)

      # Then
      expect(FileUtils).to have_received(:mkdir_p).with(zsh_completions_path)
      expect(FileUtils).to have_received(:mkdir_p).with(bash_completions_path)
      expect(fastfetch).to have_received(:runCmd).with(
        "cp",
        "/tmp/test/fastfetch-assets/usr/share/zsh/site-functions/_fastfetch",
        "#{zsh_completions_path}/_fastfetch"
      )
      expect(fastfetch).to have_received(:runCmd).with(
        "cp",
        "/tmp/test/fastfetch-assets/usr/share/bash-completion/completions/fastfetch",
        "#{bash_completions_path}/fastfetch"
      )
    end
  end
end
