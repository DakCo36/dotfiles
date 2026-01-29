require "spec_helper"
require "components/shell/powerlevel10k"
require "components/shell/oh_my_zsh"
require "components/tools/git"

RSpec.describe Component::Powerlevel10kComponent do
  subject(:p10k) { described_class.instance }

  let(:mock_git) { instance_spy(Component::GitComponent) }
  let(:mock_ohmyzsh) { instance_spy(Component::OhMyZshComponent) }
  let(:mock_logger) { Logger.new(File::NULL) }
  let(:mock_config) { instance_double(Components::Configuration) }
  let(:home_path) { "/home/user" }
  let(:target_dir) { "/home/user/.oh-my-zsh/custom/themes/powerlevel10k" }
  let(:zshrc) { "/home/user/.zshrc" }
  let(:p10k_dest) { "/home/user/.p10k.zsh" }

  before do
    allow(Component::GitComponent).to receive(:instance).and_return(mock_git)
    allow(Component::OhMyZshComponent).to receive(:instance).and_return(mock_ohmyzsh)
    allow(p10k).to receive(:logger).and_return(mock_logger)
    allow(p10k).to receive(:config).and_return(mock_config)

    allow(mock_config).to receive(:home).and_return(home_path)
  end

  describe "#available?" do
    it "returns true when theme directory exists" do
      # Given
      allow(Dir).to receive(:exist?).with(target_dir).and_return(true)

      # When
      result = p10k.available?

      # Then
      expect(result).to be true
    end

    it "returns false when theme directory does not exist" do
      # Given
      allow(Dir).to receive(:exist?).with(target_dir).and_return(false)

      # When
      result = p10k.available?

      # Then
      expect(result).to be false
    end
  end

  describe "#installed?" do
    it "returns true when theme directory exists" do
      # Given
      allow(Dir).to receive(:exist?).with(target_dir).and_return(true)

      # When
      result = p10k.installed?

      # Then
      expect(result).to be true
    end

    it "returns false when theme directory is missing" do
      # Given
      allow(Dir).to receive(:exist?).with(target_dir).and_return(false)

      # When
      result = p10k.installed?

      # Then
      expect(result).to be false
    end
  end

  describe "#install" do
    context "when already installed" do
      it "does nothing" do
        # Given
        allow(p10k).to receive(:installed?).and_return(true)
        allow(p10k).to receive(:configure)

        # When
        p10k.install

        # Then
        expect(mock_git).not_to have_received(:clone)
        expect(p10k).not_to have_received(:configure)
      end
    end

    context "when not installed" do
      it "clones the repository" do
        # Given
        allow(p10k).to receive(:installed?).and_return(false)
        allow(p10k).to receive(:configure)
        allow(mock_ohmyzsh).to receive(:available?).and_return(true)
        allow(mock_git).to receive(:available?).and_return(true)
        allow(Dir).to receive(:exist?).with(target_dir).and_return(false)
        allow(FileUtils).to receive(:mkdir_p).with(target_dir)
        allow(mock_git).to receive(:clone).with(described_class::REPO_URL, target_dir)

        # When
        p10k.install

        # Then
        expect(FileUtils).to have_received(:mkdir_p).with(target_dir)
        expect(mock_git).to have_received(:clone).with(described_class::REPO_URL, target_dir)
        expect(p10k).to have_received(:configure)
      end
    end
  end

  describe "#setInstantPrompt" do
    it "raises an error if .zshrc file does not exist" do
      # Given
      allow(File).to receive(:exist?).with(zshrc).and_return(false)

      # When & Then
      expect { p10k.send(:setInstantPrompt) }
        .to raise_error(RuntimeError, /.*file not found.*/)
    end

    it "skips if instant prompt already exists" do
      # Given
      zshrc_content = <<~EOF
        # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
        if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
            source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
        fi
        # Other content
      EOF

      allow(File).to receive(:exist?).with(zshrc).and_return(true)
      allow(File).to receive(:read).with(zshrc).and_return(zshrc_content)
      allow(File).to receive(:write).and_return(nil)

      # When
      p10k.send(:setInstantPrompt)

      # Then
      expect(File).not_to have_received(:write)
    end

    it "prepends instant prompt block to .zshrc" do
      # Given
      zshrc_content = <<~EOF
        # Existing content
        ZSH_THEME="robbyrussell"
      EOF

      allow(File).to receive(:exist?).with(zshrc).and_return(true)
      allow(File).to receive(:read).with(zshrc).and_return(zshrc_content)
      allow(File).to receive(:write).and_return(nil)

      # When
      p10k.send(:setInstantPrompt)

      # Then
      expect(File).to have_received(:write).with(zshrc, match(/^# Enable Powerlevel10k instant prompt/))
    end
  end

  describe "#setTheme" do
    it "raises an error if .zshrc file does not exist" do
      # Given
      allow(File).to receive(:exist?).with(zshrc).and_return(false)

      # When & Then
      expect { p10k.send(:setTheme) }
        .to raise_error(RuntimeError, /.*file not found.*/)
    end

    it "substitutes zsh theme in .zshrc file" do
      # Given
      zshrc_content = <<~EOF
        # Something blahblah
        ANOTHER=VARIABLE
        # Something else blahblah
        ZSH_THEME="robbyrussell"
        # Another thing blahblah
        ANOTHER_VARIABLE=VALUE
      EOF

      allow(File).to receive(:exist?).with(zshrc).and_return(true)
      allow(File).to receive(:read).with(zshrc).and_return(zshrc_content)
      allow(File).to receive(:write).and_return(nil)

      # When
      p10k.send(:setTheme)

      # Then
      expect(File).to have_received(:write).with(zshrc, match(%r{ZSH_THEME="powerlevel10k/powerlevel10k"}))
    end

    it "adds zsh theme to .zshrc file if not exist" do
      # Given
      zshrc_content = <<~EOF
        # Something blahblah
        ANOTHER=VARIABLE
        # Another thing blahblah
        ANOTHER_VARIABLE=VALUE
      EOF

      allow(File).to receive(:exist?).with(zshrc).and_return(true)
      allow(File).to receive(:read).with(zshrc).and_return(zshrc_content)
      allow(File).to receive(:write).and_return(nil)

      # When
      p10k.send(:setTheme)

      # Then
      expect(File).to have_received(:write).with(zshrc, match(%r{ZSH_THEME="powerlevel10k/powerlevel10k"}))
    end

    it "adds source .p10k.zsh to .zshrc file if not exist" do
      # Given
      zshrc_content = <<~EOF
        # Something blahblah
        ANOTHER=VARIABLE
        # Another thing blahblah
        ANOTHER_VARIABLE=VALUE
      EOF

      allow(File).to receive(:exist?).with(zshrc).and_return(true)
      allow(File).to receive(:read).with(zshrc).and_return(zshrc_content)
      allow(File).to receive(:write).and_return(nil)

      # When
      p10k.send(:setTheme)

      # Then
      expect(File).to have_received(:write).with(zshrc, match(%r{\[\[ ! -f ~/.p10k.zsh \]\] \|\| source ~/.p10k.zsh\n$}))
    end
  end

  describe "#setConfig" do
    let(:source_file) { File.join(described_class::CONFIG_DIR, "simple.zsh") }

    it "raises an error if source file does not exist" do
      # Given
      allow(File).to receive(:exist?).with(source_file).and_return(false)

      # When & Then
      expect { p10k.send(:setConfig) }
        .to raise_error(RuntimeError, /Config file .* not found/)
    end

    it "backups destination file if it exists" do
      # Given
      allow(File).to receive(:exist?).with(source_file).and_return(true)
      allow(File).to receive(:exist?).with(p10k_dest).and_return(true)
      allow(FileUtils).to receive(:cp)

      # When
      p10k.send(:setConfig)

      # Then
      expect(FileUtils).to have_received(:cp).with(p10k_dest, /.*backup_.*/)
    end
  end
end
