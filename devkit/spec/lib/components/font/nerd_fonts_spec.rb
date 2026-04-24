require "spec_helper"
require "components/font/nerd_fonts"

RSpec.describe Component::NerdFontsComponent do
  subject(:nerd_fonts) { described_class.instance }

  let(:mock_curl) { instance_spy(Component::CurlComponent) }
  let(:mock_github) { instance_spy(Component::GithubComponent) }
  let(:mock_logger) { Logger.new(File::NULL) }
  let(:mock_config) { instance_double(Components::Configuration::ComponentConfig) }
  let(:home_path) { "/home/user" }
  let(:tmp_path) { "/tmp/test" }
  let(:fonts_dir) { "/home/user/.local/share/fonts/NerdFonts" }
  let(:fonts_base_dir) { "/home/user/.local/share/fonts" }
  let(:version_file) { "/home/user/.local/share/fonts/NerdFonts/.version" }

  before do
    allow(nerd_fonts).to receive(:curl).and_return(mock_curl)
    allow(nerd_fonts).to receive(:github).and_return(mock_github)
    allow(nerd_fonts).to receive(:logger).and_return(mock_logger)
    allow(nerd_fonts).to receive(:config).and_return(mock_config)

    allow(mock_config).to receive(:home).and_return(home_path)
    allow(mock_config).to receive(:tmp).and_return(tmp_path)
    allow(mock_config).to receive(:owner).and_return("ryanoasis")
    allow(mock_config).to receive(:repo).and_return("nerd-fonts")
  end

  describe "#installed?" do
    it "returns true when font files exist" do
      allow(Dir).to receive(:exist?).with(fonts_dir).and_return(true)
      allow(Dir).to receive(:glob).with(File.join(fonts_dir, "*.ttf")).and_return(["HackNerdFont-Regular.ttf"])

      expect(nerd_fonts.installed?).to be true
    end

    it "returns false when fonts directory does not exist" do
      allow(Dir).to receive(:exist?).with(fonts_dir).and_return(false)

      expect(nerd_fonts.installed?).to be false
    end

    it "returns false when no ttf files are found" do
      allow(Dir).to receive(:exist?).with(fonts_dir).and_return(true)
      allow(Dir).to receive(:glob).with(File.join(fonts_dir, "*.ttf")).and_return([])

      expect(nerd_fonts.installed?).to be false
    end
  end

  describe "#version" do
    it "returns the version from the version file" do
      allow(File).to receive(:exist?).with(version_file).and_return(true)
      allow(File).to receive(:read).with(version_file).and_return("3.3.0\n")

      expect(nerd_fonts.version).to eq("3.3.0")
    end

    it "returns nil when version file does not exist" do
      allow(File).to receive(:exist?).with(version_file).and_return(false)

      expect(nerd_fonts.version).to be_nil
    end
  end

  describe "#latest_version" do
    it "returns the latest version from GitHub" do
      allow(mock_github).to receive(:get_latest_release_tag)
        .with("ryanoasis", "nerd-fonts")
        .and_return("v3.3.0")

      expect(nerd_fonts.latest_version).to eq("3.3.0")
    end

    it "returns nil on failure" do
      allow(mock_github).to receive(:get_latest_release_tag)
        .and_raise(StandardError.new("API error"))

      expect(nerd_fonts.latest_version).to be_nil
    end
  end

  describe "#version_tag" do
    it "prepends v to version" do
      expect(nerd_fonts.version_tag("3.3.0")).to eq("v3.3.0")
    end

    it "returns latest as-is" do
      expect(nerd_fonts.version_tag("latest")).to eq("latest")
    end
  end

  describe "#install!" do
    before do
      allow(mock_config).to receive(:version).and_return("latest")
      allow(mock_config).to receive(:fallback_version).and_return("3.3.0")
      allow(mock_config).to receive(:resources).and_return(nil)
      allow(mock_config).to receive_message_chain(:contract_path).and_return("$HOME/.local/share/fonts/NerdFonts")

      allow(mock_github).to receive(:get_latest_release_tag)
        .with("ryanoasis", "nerd-fonts")
        .and_return("v3.3.0")

      allow(Dir).to receive(:exist?).with(fonts_dir).and_return(false)
      allow(FileUtils).to receive(:rm_rf)
      allow(FileUtils).to receive(:mkdir_p)
      allow(mock_curl).to receive(:download)
      allow(nerd_fonts).to receive(:runCmd)
      allow(File).to receive(:write)
    end

    it "downloads and extracts the font" do
      nerd_fonts.install!

      expect(mock_curl).to have_received(:download).with(
        "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/Hack.zip",
        "/tmp/test/Hack.zip"
      )
      expect(nerd_fonts).to have_received(:runCmd).with("unzip", "-o", "/tmp/test/Hack.zip", "-d", fonts_dir)
    end

    it "writes the version file" do
      nerd_fonts.install!

      expect(File).to have_received(:write).with(version_file, anything)
    end

    it "refreshes the font cache" do
      nerd_fonts.install!

      expect(nerd_fonts).to have_received(:runCmd).with("fc-cache", "-fv", fonts_base_dir)
    end

    it "cleans up existing fonts directory before install" do
      allow(Dir).to receive(:exist?).with(fonts_dir).and_return(true)

      nerd_fonts.install!

      expect(FileUtils).to have_received(:rm_rf).with(fonts_dir)
      expect(FileUtils).to have_received(:mkdir_p).with(fonts_dir)
    end
  end
end
