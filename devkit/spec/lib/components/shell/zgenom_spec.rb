require "spec_helper"
require "components/shell/zgenom"
require "components/tools/git"
require "components/shell/zsh_binary"

RSpec.describe Component::ZgenomComponent do
  subject(:zgenom) { described_class.instance }

  let(:mock_git) { instance_spy(Component::GitComponent) }
  let(:mock_zsh_binary) { instance_spy(Component::ZshBinaryComponent) }
  let(:mock_logger) { Logger.new(File::NULL) }
  let(:mock_config) { instance_double(Components::Configuration) }
  let(:home_path) { "/home/user" }
  let(:target_dir) { "/home/user/.zgenom" }
  let(:zshrc) { "/home/user/.zshrc" }

  before do
    allow(zgenom).to receive(:logger).and_return(mock_logger)
    allow(zgenom).to receive(:git).and_return(mock_git)
    allow(zgenom).to receive(:zsh_binary).and_return(mock_zsh_binary)
    allow(zgenom).to receive(:config).and_return(mock_config)

    allow(mock_config).to receive(:home).and_return(home_path)

    allow(Component::GitComponent).to receive(:instance).and_return(mock_git)
    allow(Component::ZshBinaryComponent).to receive(:instance).and_return(mock_zsh_binary)
  end

  describe "#available?" do
    it "returns true when zgenom directory and zgenom.zsh file exist" do
      # Given
      allow(Dir).to receive(:exist?).with(target_dir).and_return(true)
      allow(File).to receive(:exist?).with("#{target_dir}/zgenom.zsh").and_return(true)

      # When
      result = zgenom.available?

      # Then
      expect(result).to be true
    end

    it "returns false when zgenom directory does not exist" do
      # Given
      allow(Dir).to receive(:exist?).with(target_dir).and_return(false)

      # When
      result = zgenom.available?

      # Then
      expect(result).to be false
    end
  end

  describe "#installed?" do
    it "returns true when zgenom directory and zgenom.zsh file exist" do
      # Given
      allow(Dir).to receive(:exist?).with(target_dir).and_return(true)
      allow(File).to receive(:exist?).with("#{target_dir}/zgenom.zsh").and_return(true)

      # When
      result = zgenom.installed?

      # Then
      expect(result).to be true
    end

    it "returns false when zgenom directory is missing" do
      # Given
      allow(Dir).to receive(:exist?).with(target_dir).and_return(false)

      # When
      result = zgenom.installed?

      # Then
      expect(result).to be false
    end
  end

  describe "#install" do
    context "when already installed" do
      it "does nothing" do
        # Given
        allow(zgenom).to receive(:installed?).and_return(true)

        # When
        zgenom.install

        # Then
        expect(mock_git).not_to have_received(:clone)
      end
    end

    context "when not installed" do
      it "clones the zgenom repository" do
        # Given
        allow(zgenom).to receive(:installed?).and_return(false)
        allow(mock_git).to receive(:available?).and_return(true)
        allow(mock_zsh_binary).to receive(:available?).and_return(true)
        allow(mock_git).to receive(:clone).with(described_class::REPO_URL, target_dir)

        allow(Dir).to receive(:exist?).with(target_dir).and_return(false)
        allow(FileUtils).to receive(:rm_rf).and_return(nil)
        allow(FileUtils).to receive(:mkdir_p).and_return(nil)

        allow(zgenom).to receive(:configure).and_return(true)

        # Mock FileUtils to prevent actual file operations
        allow(FileUtils).to receive(:rm_rf).and_return(nil)
        allow(FileUtils).to receive(:mkdir_p).and_return(nil)
        allow(Dir).to receive(:exist?).and_return(false)

        # Let's spy on the dependencies method
        allow(zgenom).to receive(:dependencies).and_call_original

        # When
        zgenom.install

        # Then
        expect(mock_git).to have_received(:clone).with(described_class::REPO_URL, target_dir)
      end
    end
  end

  describe "#disableOhMyZshPlugins" do
    it "disables oh-my-zsh plugins" do
      # Given
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

      allow(File).to receive(:exist?).with(zshrc).and_return(true)
      allow(File).to receive(:read).with(zshrc).and_return(original_content)
      allow(File).to receive(:write).and_return(nil)

      # When
      zgenom.send(:disableOhMyZshPlugins)

      # Then
      expect(File).to have_received(:write).with(zshrc, expected_final_content)
    end
  end

  describe "#setPlugins" do
    it "skips when zgenom autoupdate already exists in .zshrc" do
      # Given
      content = <<~CONTENT
        Something bla
        # plugins=(git docker)

        something else
        zgenom autoupdate

        Hello world!
        PATH="$PATH"
      CONTENT

      allow(File).to receive(:exist?).with(zshrc).and_return(true)
      allow(File).to receive(:read).with(zshrc).and_return(content)

      # When
      zgenom.send(:setPlugins)

      # Then
      expect(File).not_to have_received(:write)
    end

    it "sets zgenom plugins" do
      # Given
      content = <<~CONTENT
        Something blah
        # plugins=(git docker)

        something else

        Hello world!
        PATH="$PATH"
      CONTENT

      allow(File).to receive(:exist?).with(zshrc).and_return(true)
      allow(File).to receive(:read).with(zshrc).and_return(content)
      captured_content = nil
      allow(File).to receive(:write) do |_path, written_content|
        captured_content = written_content
        nil
      end

      # When
      zgenom.send(:setPlugins)

      # Then
      expect(captured_content).to match(/zgenom autoupdate/)
      expect(captured_content).to match(/Something blah/)
    end
  end
end
