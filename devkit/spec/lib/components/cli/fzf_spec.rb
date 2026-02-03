require "spec_helper"
require "components/cli/fzf"

RSpec.describe Component::FzfComponent do
  subject(:fzf) { described_class.instance }
  let(:null_logger) { instance_spy(Logger) }
  let(:mock_curl) { instance_spy(Component::CurlComponent) }
  let(:mock_tar) { instance_spy(Component::TarComponent) }
  let(:mock_github) { instance_spy(Component::GithubComponent) }
  let(:mock_config) { instance_double(Components::Configuration::ComponentConfig) }
  let(:tmp_path) { "/tmp/test" }
  let(:bin_path) { "/home/user/.local/bin" }
  let(:home_path) { "/home/user" }
  let(:zshrc_path) { "/home/user/.zshrc" }

  before do
    allow(fzf).to receive(:logger).and_return(null_logger)
    allow(fzf).to receive(:curl).and_return(mock_curl)
    allow(fzf).to receive(:tar).and_return(mock_tar)
    allow(fzf).to receive(:github).and_return(mock_github)
    allow(fzf).to receive(:config).and_return(mock_config)

    allow(mock_config).to receive(:tmp).and_return(tmp_path)
    allow(mock_config).to receive(:bin).and_return(bin_path)
    allow(mock_config).to receive(:home).and_return(home_path)
    allow(mock_config).to receive(:zshrc).and_return(zshrc_path)
    allow(mock_config).to receive(:arch).and_return("x86_64")
  end

  describe "#available?" do
    it "returns true when fzf command is available" do
      # Given
      allow(fzf)
        .to receive(:system)
        .with("fzf", "--version", out: File::NULL, err: File::NULL)
        .and_return(true)

      # When
      available = fzf.available?

      # Then
      expect(available).to be true
    end

    it "returns false when fzf command is missing" do
      # Given
      allow(fzf)
        .to receive(:system)
        .with("fzf", "--version", out: File::NULL, err: File::NULL)
        .and_return(false)

      # When
      available = fzf.available?

      # Then
      expect(available).to be false
    end
  end

  describe "#version" do
    it "returns the installed fzf version" do
      # Given
      status = instance_double(Process::Status, success?: true)
      allow(Open3).to receive(:capture2)
        .with("fzf", "--version")
        .and_return(["0.57.0 (fc7630a)\n", status])

      # When
      version = fzf.version

      # Then
      expect(version).to eq("0.57.0")
    end

    it "returns nil when command fails" do
      # Given
      status = instance_double(Process::Status, success?: false)
      allow(Open3).to receive(:capture2)
        .with("fzf", "--version")
        .and_return(["Unknown result", status])

      # When
      version = fzf.version

      # Then
      expect(version).to be_nil
    end

    it "returns nil when fzf is not installed" do
      # Given
      allow(Open3).to receive(:capture2)
        .with("fzf", "--version")
        .and_raise(Errno::ENOENT)

      # When
      version = fzf.version

      # Then
      expect(version).to be_nil
    end
  end

  describe "#installed?" do
    it "returns true if fzf is installed" do
      # Given
      allow(fzf).to receive(:available?).and_return(true)
      allow(fzf).to receive(:version).and_return("0.57.0")

      # When & Then
      expect(fzf.installed?).to be true
    end

    it "returns false if fzf is not installed" do
      # Given
      allow(fzf).to receive(:available?).and_return(false)
      allow(fzf).to receive(:version).and_return(nil)

      # When & Then
      expect(fzf.installed?).to be false
    end
  end

  describe "#install!" do
    it "installs fzf from GitHub releases" do
      allow(mock_config).to receive(:version).and_return("latest")
      allow(mock_config).to receive(:fallback_version).and_return("0.57.0")
      allow(mock_config).to receive(:owner).and_return("junegunn")
      allow(mock_config).to receive(:repo).and_return("fzf")

      allow(mock_github).to receive(:download_asset)
      allow(mock_tar).to receive(:extract).and_return(["", "", instance_double(Process::Status, success?: true)])
      allow(fzf).to receive(:setup_shell_integration)
      allow(fzf).to receive(:runCmd)
        .with("cp", anything, anything)
        .and_return(["", "", instance_double(Process::Status, success?: true)])

      fzf.install!

      expect(mock_github).to have_received(:download_asset).with(
        owner: "junegunn",
        repo: "fzf",
        version: "latest",
        fallback_version: "v0.57.0",
        asset_pattern: "fzf-.*-linux_amd64\\.tar\\.gz",
        fallback_asset: "fzf-0.57.0-linux_amd64.tar.gz",
        destination: "/tmp/test/fzf-assets.tar.gz"
      )
      expect(mock_tar).to have_received(:extract)
      expect(fzf).to have_received(:setup_shell_integration)
    end
  end

  describe "#setup_shell_integration" do
    context "when .zshrc does not exist" do
      it "does nothing" do
        # Given
        allow(File).to receive(:exist?).with(zshrc_path).and_return(false)
        allow(File).to receive(:read).and_return(nil)
        allow(File).to receive(:open).and_return(nil)

        # When
        fzf.send(:setup_shell_integration)

        # Then
        expect(File).not_to have_received(:read)
        expect(File).not_to have_received(:open)
      end
    end

    context "when fzf integration already exists" do
      it "skips adding integration" do
        # Given
        zshrc_content = <<~EOF
          # existing config
          eval "$(fzf --zsh)"
          # more config
        EOF

        allow(File).to receive(:exist?).with(zshrc_path).and_return(true)
        allow(File).to receive(:read).with(zshrc_path).and_return(zshrc_content)
        allow(File).to receive(:open).and_return(nil)

        # When
        fzf.send(:setup_shell_integration)

        # Then
        expect(File).not_to have_received(:open)
      end
    end

    context "when fzf integration does not exist" do
      it "adds fzf shell integration to .zshrc" do
        # Given
        file_double = instance_double(File)
        allow(file_double).to receive(:write)

        zshrc_content = <<~EOF
          # existing config
          ZSH_THEME="powerlevel10k/powerlevel10k"
        EOF

        allow(File).to receive(:exist?).with(zshrc_path).and_return(true)
        allow(File).to receive(:read).with(zshrc_path).and_return(zshrc_content)
        allow(File).to receive(:open).with(zshrc_path, "a").and_yield(file_double)

        # When
        fzf.send(:setup_shell_integration)

        # Then
        expect(file_double)
          .to have_received(:write)
          .with(match(/eval.*fzf --zsh/))
      end
    end
  end
end
