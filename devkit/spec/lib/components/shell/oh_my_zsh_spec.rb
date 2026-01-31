require "spec_helper"
require "components/shell/oh_my_zsh"

RSpec.describe Component::OhMyZshComponent do
  subject(:oh_my_zsh) { described_class.instance }
  let(:mock_curl) { instance_spy(Component::CurlComponent) }
  let(:mock_zsh_binary) { instance_spy(Component::ZshBinaryComponent) }
  let(:mock_logger) { Logger.new(File::NULL) }
  let(:mock_config) { instance_double(Components::Configuration) }
  let(:home_path) { "/home/user" }
  let(:tmp_path) { "/tmp/test" }
  let(:target_dir) { "/home/user/.oh-my-zsh" }
  let(:tmp_script) { "/tmp/test/install-oh-my-zsh.sh" }
  let(:zshrc) { "/home/user/.zshrc" }

  before do
    allow(Component::ZshBinaryComponent).to receive(:instance).and_return(mock_zsh_binary)
    allow(Component::CurlComponent).to receive(:instance).and_return(mock_curl)
    allow(oh_my_zsh).to receive(:curl).and_return(mock_curl)
    allow(oh_my_zsh).to receive(:zsh_binary).and_return(mock_zsh_binary)
    allow(oh_my_zsh).to receive(:logger).and_return(mock_logger)
    allow(oh_my_zsh).to receive(:config).and_return(mock_config)

    allow(mock_config).to receive(:home).and_return(home_path)
    allow(mock_config).to receive(:tmp).and_return(tmp_path)
  end

  describe "#available?" do
    it "returns true when target directory exists" do
      # Given
      allow(Dir).to receive(:exist?).with(target_dir).and_return(true)

      # When
      result = oh_my_zsh.available?

      # Then
      expect(result).to be true
    end

    it "returns false when target directory does not exist" do
      # Given
      allow(Dir).to receive(:exist?).with(target_dir).and_return(false)

      # When
      result = oh_my_zsh.available?

      # Then
      expect(result).to be false
    end
  end

  describe "#installed?" do
    it "returns true when target directory exists" do
      # Given
      allow(Dir).to receive(:exist?).with(target_dir).and_return(true)

      # When
      result = oh_my_zsh.installed?

      # Then
      expect(result).to be true
    end

    it "returns false when target directory is missing" do
      # Given
      allow(Dir).to receive(:exist?).with(target_dir).and_return(false)

      # When
      result = oh_my_zsh.installed?

      # Then
      expect(result).to be false
    end
  end

  describe "#install" do
    context "when already installed" do
      it "does nothing" do
        # Given
        allow(oh_my_zsh).to receive(:installed?).and_return(true)

        # When
        oh_my_zsh.install

        # Then
        expect(mock_curl).not_to have_received(:download)
      end
    end

    context "when not installed" do
      it "downloads and runs the installer script" do
        # Given
        allow(oh_my_zsh).to receive(:installed?).and_return(false)
        allow(mock_curl).to receive(:available?).and_return(true)
        allow(mock_zsh_binary).to receive(:available?).and_return(true)
        allow(mock_curl).to receive(:download).and_return(true)
        allow(oh_my_zsh).to receive(:runCmd).with("sh", "-c", described_class::TMP_SCRIPT_PATH,
                                                  showStdout: true).and_return(true)
        allow(FileUtils).to receive(:rm_rf).with(described_class::TARGET_DIR_PATH)
        allow(FileUtils).to receive(:rm_f)
        allow(File).to receive(:chmod)

        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(zshrc_path).and_return(true)
        allow(File).to receive(:exist?).with(described_class::TMP_SCRIPT_PATH).and_return(true)
        allow(File).to receive(:read).with(zshrc_path).and_return("plugins=(git)")
        allow(File).to receive(:open).with(zshrc_path, "w").and_yield(double("file", write: true))
        allow(File).to receive(:write).and_return(nil)

        # When
        oh_my_zsh.install

        expect(mock_curl).to have_received(:download).with(described_class::DOWNLOAD_URL,
                                                           described_class::TMP_SCRIPT_PATH)
        expect(oh_my_zsh).to have_received(:runCmd).with("sh", "-c", described_class::TMP_SCRIPT_PATH, showStdout: true)
      end
    end
  end

  describe "#setPlugins" do
    context "when plugins=() already exists in .zshrc" do
      it "replaces the existing plugins array" do
        # Given
        original_content = <<~CONTENT
          # Welcome to oh-my-zsh!
          export ZSH="$HOME/.oh-my-zsh"
          ZSH_THEME="robbyrussell"
          # plugins=(git)
          plugins=(git)
          source $ZSH/oh-my-zsh.sh
        CONTENT

        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(zshrc).and_return(true)
        allow(File).to receive(:read).with(zshrc).and_return(original_content)
        captured_content = nil
        allow(File).to receive(:write) do |_path, content|
          captured_content = content
          nil
        end

        # When
        oh_my_zsh.send(:setPlugins)

        # Then
        expect(captured_content).to match(/plugins=\([^\n]+\)/)
      end
    end

    context "when plugins=() does not exist in .zshrc" do
      it "appends plugins configuration to the file" do
        # Given
        original_content = <<~CONTENT
          export ZSH="$HOME/.oh-my-zsh"
          ZSH_THEME="robbyrussell"
          source $ZSH/oh-my-zsh.sh
        CONTENT

        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(zshrc).and_return(true)
        allow(File).to receive(:read).with(zshrc).and_return(original_content)
        captured_content = nil
        allow(File).to receive(:write) do |_path, content|
          captured_content = content
          nil
        end

        # When
        oh_my_zsh.send(:setPlugins)

        # Then
        expect(captured_content).to include("# oh-my-zsh plugins configuration")
        expect(captured_content).to match(/plugins=\([^\n]+\)/)
      end
    end

    context "when .zshrc file does not exist" do
      it "raises an error" do
        # Given
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(zshrc).and_return(false)

        # When & Then
        expect do
          oh_my_zsh.send(:setPlugins)
        end.to raise_error(RuntimeError, ".zshrc file not found")
      end
    end
  end
end
