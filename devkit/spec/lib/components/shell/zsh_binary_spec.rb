require "spec_helper"
require "components/shell/zsh_binary"

RSpec.describe Component::ZshBinaryComponent do
  subject(:zsh) { described_class.instance }
  let(:null_logger) { instance_spy(Logger) }
  let(:mock_curl) { instance_spy(Component::CurlComponent) }
  let(:mock_config) { instance_double(Components::Configuration::ComponentConfig) }
  let(:home_path) { "/home/user" }
  let(:bash_profile_path) { "/home/user/.bash_profile" }
  let(:bashrc_path) { "/home/user/.bashrc" }
  let(:local_path) { "/home/user/.local" }
  let(:bin_path) { "/home/user/.local/bin" }
  let(:tmp_path) { "/tmp/test" }
  let(:path_fixture) { "#{bin_path}:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin" }

  before do
    allow(zsh).to receive(:logger).and_return(null_logger)
    allow(zsh).to receive(:curl).and_return(mock_curl)
    allow(zsh).to receive(:config).and_return(mock_config)

    allow(mock_config).to receive(:bash_profile).and_return(bash_profile_path)
    allow(mock_config).to receive(:bashrc).and_return(bashrc_path)
    allow(mock_config).to receive(:local).and_return(local_path)
    allow(mock_config).to receive(:bin).and_return(bin_path)
    allow(mock_config).to receive(:tmp).and_return(tmp_path)
    allow(mock_config).to receive(:contract_path) do |path|
      path.sub("/home/user", "$HOME")
    end

    allow(FileUtils).to receive(:touch)
    allow(FileUtils).to receive(:cp)
  end

  describe "#available?" do
    it "returns true when zsh command is available" do
      # Given
      allow(zsh).to receive(:runCmd).with("which", "zsh").and_return(true)

      # When
      result = zsh.available?

      # Then
      expect(result).to be true
    end

    it "returns false when zsh command is missing" do
      # Given
      allow(zsh).to receive(:runCmd).with("which", "zsh").and_raise(RuntimeError)

      # When
      result = zsh.available?

      # Then
      expect(result).to be false
    end
  end

  describe "#installed?" do
    it "returns true when zsh is installed locally and executable and in PATH" do
      # Given
      local_zsh_path = File.join(bin_path, "zsh")
      allow(ENV).to receive(:[]).with("PATH").and_return(path_fixture)
      allow(File).to receive(:exist?).with(local_zsh_path).and_return(true)
      allow(File).to receive(:executable?).with(local_zsh_path).and_return(true)

      # When
      result = zsh.installed?

      # Then
      expect(result).to be true
    end

    it "returns false when zsh is installed locally but not executable" do
      # Given
      local_zsh_path = File.join(bin_path, "zsh")
      allow(ENV).to receive(:[]).with("PATH").and_return(path_fixture)
      allow(File).to receive(:exist?).with(local_zsh_path).and_return(true)
      allow(File).to receive(:executable?).with(local_zsh_path).and_return(false)

      # When
      result = zsh.installed?

      # Then
      expect(result).to be false
    end

    it "returns false when zsh is not installed locally" do
      # Given
      local_zsh_path = File.join(bin_path, "zsh")
      allow(ENV).to receive(:[]).with("PATH").and_return(path_fixture)
      allow(File).to receive(:exist?).with(local_zsh_path).and_return(false)
      allow(File).to receive(:executable?).with(local_zsh_path).and_return(false)

      # When
      result = zsh.installed?

      # Then
      expect(result).to be false
    end

    it "returns false when zsh is installed locally and executable but not in PATH" do
      # Given
      local_zsh_path = File.join(bin_path, "zsh")
      allow(ENV).to receive(:[]).with("PATH").and_return("/usr/local/bin:/bin:/usr/bin")
      allow(File).to receive(:exist?).with(local_zsh_path).and_return(true)
      allow(File).to receive(:executable?).with(local_zsh_path).and_return(true)

      # When
      result = zsh.installed?

      # Then
      expect(result).to be false
    end
  end

  describe "#version" do
    it "returns the installed zsh version" do
      # Given
      expected_version = "5.9"
      expected_string = "zsh #{expected_version} (x86_64-pc-linux-musl)"
      allow(zsh).to receive(:runCmdWithOutput).with("zsh", "--version").and_return(expected_string)

      # When
      result = zsh.version

      # Then
      expect(result).to eq(expected_version)
    end
  end

  describe "#install" do
    before do
      allow(zsh).to receive(:setPath).and_return(nil)
    end

    context "when zsh is installed" do
      it "does nothing" do
        # Given
        allow(zsh).to receive(:installed?).and_return(true)

        # When
        zsh.install

        # Then
        expect(mock_curl).not_to have_received(:download)
      end
    end

    context "when zsh is not installed" do
      it "installs zsh" do
        # Given
        allow(zsh).to receive(:installed?).and_return(false)
        allow(zsh).to receive(:runCmd).with("tar", "-xf", anything, "-C", anything).and_return(true)
        allow(zsh).to receive(:configureAndMake).and_return(nil)

        # When
        zsh.install

        # Then
        expect(mock_curl).to have_received(:download).with(anything, "#{tmp_path}/zsh-5.9.tar.xz")
        expect(zsh).to have_received(:configureAndMake)
      end
    end
  end

  describe "#addExecZshInBashProfile" do
    let(:file_handler) { instance_double(File) }

    before do
      allow(File).to receive(:exist?).with(bash_profile_path).and_return(true)
      allow(File).to receive(:open).with(bash_profile_path, "a").and_yield(file_handler)
      allow(file_handler).to receive(:puts)
    end

    context "when exec zsh does not exist" do
      it "adds exec zsh block to bash_profile" do
        # Given
        allow(File).to receive(:read).with(bash_profile_path).and_return("export PATH=\"/usr/bin:$PATH\"\n")

        # When
        zsh.send(:addExecZshInBashProfile)

        # Then
        expect(file_handler).to have_received(:puts).with("")
        expect(file_handler).to have_received(:puts).with("# Auto-launch zsh")
        expect(file_handler).to have_received(:puts).with("if [ -x \"$HOME/.local/bin/zsh\" ] && [ -z \"$ZSH_VERSION\" ]; then")
        expect(file_handler).to have_received(:puts).with("  exec \"$HOME/.local/bin/zsh\"")
        expect(file_handler).to have_received(:puts).with("fi")
      end
    end

    context "when exec zsh already exists" do
      it "skips adding exec zsh" do
        # Given
        original_content = <<~CONTENT
          export PATH="/usr/bin:$PATH"
          if [ -x "$HOME/.local/bin/zsh" ]; then
            exec "$HOME/.local/bin/zsh"
          fi
        CONTENT
        allow(File).to receive(:read).with(bash_profile_path).and_return(original_content)

        # When
        zsh.send(:addExecZshInBashProfile)

        # Then
        expect(file_handler).not_to have_received(:puts)
      end
    end
  end
end
