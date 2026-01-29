require "spec_helper"
require "components/shell/zgenom"
require "components/tools/git"
require "components/shell/zsh_binary"
require "components/shell/zgenom"

RSpec.describe Component::ZgenomComponent do
  subject(:zgenom) { described_class.instance }

  let(:mock_git) { instance_spy(Component::GitComponent) }
  let(:mock_zsh_binary) { instance_spy(Component::ZshBinaryComponent) }
  let(:mock_logger) { Logger.new(File::NULL) }

  before do
    allow(zgenom).to receive(:logger).and_return(mock_logger)
    allow(zgenom).to receive(:git).and_return(mock_git)
    allow(zgenom).to receive(:zsh_binary).and_return(mock_zsh_binary)

    # Mock the instance methods for dependency checking
    allow(Component::GitComponent).to receive(:instance).and_return(mock_git)
    allow(Component::ZshBinaryComponent).to receive(:instance).and_return(mock_zsh_binary)
  end

  describe "#available?" do
    it "returns true when zgenom directory and zgenom.zsh file exist" do
      allow(Dir).to receive(:exist?).with(described_class::TARGET_DIR_PATH).and_return(true)
      allow(File).to receive(:exist?).and_return(true)
      expect(zgenom.available?).to be true
    end

    it "returns false when zgenom directory does not exist" do
      allow(Dir).to receive(:exist?).with(described_class::TARGET_DIR_PATH).and_return(false)
      allow(File).to receive(:exist?).and_return(false)
      expect(zgenom.available?).to be false
    end
  end

  describe "#installed?" do
    it "returns true when zgenom directory and zgenom.zsh file exist" do
      allow(Dir).to receive(:exist?).with(described_class::TARGET_DIR_PATH).and_return(true)
      allow(File).to receive(:exist?).and_return(true)
      expect(zgenom.installed?).to be true
    end

    it "returns false when zgenom directory is missing" do
      allow(Dir).to receive(:exist?).with(described_class::TARGET_DIR_PATH).and_return(false)
      allow(File).to receive(:exist?).and_return(false)
      expect(zgenom.installed?).to be false
    end
  end

  describe "#install" do
    context "when already installed" do
      it "does nothing" do
        allow(zgenom).to receive(:installed?).and_return(true)

        zgenom.install

        expect(mock_git).not_to have_received(:clone)
      end
    end

    context "when not installed" do
      it "clones the zgenom repository" do
        allow(zgenom).to receive(:installed?).and_return(false)
        allow(mock_git).to receive(:available?).and_return(true)
        allow(mock_zsh_binary).to receive(:available?).and_return(true)
        allow(mock_git).to receive(:clone).with(described_class::REPO_URL, described_class::TARGET_DIR_PATH)

        allow(Dir).to receive(:exist?).with(described_class::TARGET_DIR_PATH).and_return(false)
        allow(FileUtils).to receive(:rm_rf).and_return(nil)
        allow(FileUtils).to receive(:mkdir_p).and_return(nil)

        allow(zgenom).to receive(:configure).and_return(true)

        # Let's spy on the dependencies method
        allow(zgenom).to receive(:dependencies).and_call_original

        zgenom.install

        expect(mock_git)
          .to have_received(:clone)
          .with(described_class::REPO_URL, described_class::TARGET_DIR_PATH)
      end
    end
  end

  describe "#disableOhMyZshPlugins" do
    it "disables oh-my-zsh plugins" do
      original_content = <<~CONTENT
        source $ZSH/oh-my-zsh.sh
        plugins=(git docker)

        something else
        another thing
      CONTENT

      expected_final_content = <<~CONTENT
        # source $ZSH/oh-my-zsh.sh
        # plugins=(git docker)

        something else
        another thing
      CONTENT

      # Given
      allow(File).to receive(:exist?).with(described_class::ZSHRC).and_return(true)
      allow(File).to receive(:read).with(described_class::ZSHRC).and_return(original_content)
      allow(File).to receive(:write).and_return(nil)

      zgenom.send(:disableOhMyZshPlugins)

      expect(File).to have_received(:write).with(described_class::ZSHRC, expected_final_content)
    end
  end

  describe "#setPlugins" do

    it "Already zgenom autoupdate exists in .zshrc, skip" do
      content = <<~CONTENT
        Something bla
        # plugins=(git docker)

        something else
        zgenom autoupdate

        Hello world!
        PATH="$PATH"
      CONTENT

      allow(File).to receive(:exist?).with(described_class::ZSHRC).and_return(true)
      allow(File).to receive(:read).with(described_class::ZSHRC).and_return(content)

      expect(File).not_to receive(:open).with(described_class::ZSHRC, "w")

      zgenom.send(:setPlugins)
    end

    it "set zgenom pluings" do
      content = <<~CONTENT
        Something blah
        # plugins=(git docker)

        something else

        Hello world!
        PATH="$PATH"
      CONTENT

      allow(File).to receive(:exist?).with(described_class::ZSHRC).and_return(true)
      allow(File).to receive(:read).with(described_class::ZSHRC).and_return(content)
      # Capture the arguments passed to File.write
      captured_path = nil
      captured_content = nil
      allow(File).to receive(:write) do |path, written_content|
        captured_path = path
        captured_content = written_content
        nil
      end

      zgenom.send(:setPlugins)

      expect(captured_path).to eq(described_class::ZSHRC)
      expect(captured_content).to match(/zgenom autoupdate/)
      expect(captured_content).to match(/Something blah/)
    end
  end
end
