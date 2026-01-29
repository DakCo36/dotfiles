require "spec_helper"
require "components/utils/ripgrep"

RSpec.describe Component::RipgrepComponent do
  subject(:ripgrep) { described_class.instance }
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
    allow(ripgrep).to receive(:logger).and_return(null_logger)
    allow(ripgrep).to receive(:curl).and_return(mock_curl)
    allow(ripgrep).to receive(:tar).and_return(mock_tar)
    allow(ripgrep).to receive(:github).and_return(mock_github)
    allow(ripgrep).to receive(:config).and_return(mock_config)

    allow(mock_config).to receive(:tmp).and_return(tmp_path)
    allow(mock_config).to receive(:bin).and_return(bin_path)
    allow(mock_config).to receive(:man1).and_return(man1_path)
    allow(mock_config).to receive(:zsh_completions).and_return(zsh_completions_path)
    allow(mock_config).to receive(:bash_completions).and_return(bash_completions_path)
    allow(mock_config).to receive(:arch).and_return("x86_64")
    allow(mock_config).to receive(:os).and_return("linux-gnu")
  end

  describe "#available?" do
    it "returns true when rg command is available" do
      # Given
      allow(ripgrep)
        .to receive(:system)
        .with("rg", "--version", out: File::NULL, err: File::NULL)
        .and_return(true)

      # When
      result = ripgrep.available?

      # Then
      expect(result).to be true
    end

    it "returns false when rg command is missing" do
      # Given
      allow(ripgrep)
        .to receive(:system)
        .with("rg", "--version", out: File::NULL, err: File::NULL)
        .and_return(false)

      # When
      result = ripgrep.available?

      # Then
      expect(result).to be false
    end
  end

  describe "#version" do
    it "returns the installed ripgrep version" do
      # Given
      status = instance_double(Process::Status, success?: true)
      allow(Open3).to receive(:capture2)
        .with("rg", "--version")
        .and_return(["ripgrep 14.1.0\n", status])

      # When
      result = ripgrep.version

      # Then
      expect(result).to eq("14.1.0")
    end

    it "returns nil when command fails" do
      # Given
      status = instance_double(Process::Status, success?: false)
      allow(Open3).to receive(:capture2)
        .with("rg", "--version")
        .and_return(["Unknown result", status])

      # When
      result = ripgrep.version

      # Then
      expect(result).to be_nil
    end

    it "returns nil when rg is not installed" do
      # Given
      allow(Open3).to receive(:capture2)
        .with("rg", "--version")
        .and_raise(Errno::ENOENT)

      # When
      result = ripgrep.version

      # Then
      expect(result).to be_nil
    end
  end

  describe "#installed?" do
    it "returns true if ripgrep is installed" do
      # Given
      allow(ripgrep).to receive(:available?).and_return(true)
      allow(ripgrep).to receive(:version).and_return("14.1.0")

      # When
      result = ripgrep.installed?

      # Then
      expect(result).to be true
    end

    it "returns false if ripgrep is not installed" do
      # Given
      allow(ripgrep).to receive(:available?).and_return(false)
      allow(ripgrep).to receive(:version).and_return(nil)

      # When
      result = ripgrep.installed?

      # Then
      expect(result).to be false
    end
  end

  describe "#latest_version" do
    it "returns the latest version from GitHub" do
      # Given
      allow(mock_github).to receive(:get_latest_release_tag).with("BurntSushi", "ripgrep").and_return("14.1.0")

      # When
      result = ripgrep.latest_version

      # Then
      expect(result).to eq("14.1.0")
    end

    it "returns nil when API call fails" do
      # Given
      allow(mock_github).to receive(:get_latest_release_tag).and_raise(StandardError.new("API error"))

      # When
      result = ripgrep.latest_version

      # Then
      expect(result).to be_nil
    end
  end

  describe "#install" do
    it "skips installation when already installed" do
      # Given
      allow(ripgrep).to receive(:installed?).and_return(true)
      allow(ripgrep).to receive(:install!)

      # When
      ripgrep.install

      # Then
      expect(ripgrep).not_to have_received(:install!)
      expect(null_logger).to have_received(:info).with("ripgrep already installed.")
    end

    it "calls install! when not installed" do
      # Given
      allow(ripgrep).to receive(:installed?).and_return(false)
      allow(ripgrep).to receive(:install!)

      # When
      ripgrep.install

      # Then
      expect(ripgrep).to have_received(:install!)
    end
  end

  describe "#install!" do
    before do
      allow(mock_github).to receive(:get_latest_release_tag).and_return("14.1.0")
      allow(mock_github)
        .to receive(:get_latest_release_asset_download_url)
        .and_return("https://github.com/BurntSushi/ripgrep/releases/download/14.1.0/ripgrep-14.1.0-x86_64-unknown-linux-musl.tar.gz")
      allow(mock_curl).to receive(:download)
      allow(mock_tar).to receive(:extract)
      allow(ripgrep).to receive(:runCmd)
      allow(FileUtils).to receive(:mkdir_p)
    end

    it "downloads and installs ripgrep" do
      # When
      ripgrep.install!

      # Then
      expect(mock_github).to have_received(:get_latest_release_tag)
      expect(mock_github).to have_received(:get_latest_release_asset_download_url)
      expect(mock_curl).to have_received(:download).with(anything, "#{tmp_path}/ripgrep-assets.tar.gz")
      expect(mock_tar).to have_received(:extract).with("#{tmp_path}/ripgrep-assets.tar.gz", "#{tmp_path}/ripgrep-assets", 1)
      expect(ripgrep).to have_received(:runCmd).with("cp", "#{tmp_path}/ripgrep-assets/rg", "#{bin_path}/rg")
    end
  end

  describe "#setup_man_page" do
    before do
      allow(FileUtils).to receive(:mkdir_p)
      allow(ripgrep).to receive(:runCmd)
    end

    it "creates directory and copies rg.1" do
      # When
      ripgrep.send(:setup_man_page)

      # Then
      expect(FileUtils).to have_received(:mkdir_p).with(man1_path)
      expect(ripgrep).to have_received(:runCmd).with("cp", "#{tmp_path}/ripgrep-assets/doc/rg.1", "#{man1_path}/rg.1")
    end
  end

  describe "#setup_completions" do
    before do
      allow(FileUtils).to receive(:mkdir_p)
      allow(ripgrep).to receive(:runCmd)
    end

    it "creates directories and copies completion files" do
      # When
      ripgrep.send(:setup_completions)

      # Then
      expect(FileUtils).to have_received(:mkdir_p).with(zsh_completions_path)
      expect(FileUtils).to have_received(:mkdir_p).with(bash_completions_path)
      expect(ripgrep).to have_received(:runCmd).with("cp", "#{tmp_path}/ripgrep-assets/complete/_rg",
                                                     "#{zsh_completions_path}/_rg")
      expect(ripgrep).to have_received(:runCmd).with("cp", "#{tmp_path}/ripgrep-assets/complete/rg.bash",
                                                     "#{bash_completions_path}/rg")
    end
  end
end
