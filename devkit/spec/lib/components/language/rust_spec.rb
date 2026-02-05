require "spec_helper"
require "open3"
require "components/language/rust"

RSpec.describe Component::RustComponent do
  subject(:rust) { described_class.instance }
  let(:null_logger) { instance_spy(Logger) }
  let(:mock_config) { instance_double(Components::Configuration::ComponentConfig, version: "1.93.0") }

  before do
    allow(rust).to receive(:logger).and_return(null_logger)
    allow(rust).to receive(:config).and_return(mock_config)
  end

  describe "#available?" do
    it "returns true when rust is available via mise" do
      # Given
      allow(rust)
        .to receive(:system)
        .with("mise", "which", "rustc", out: File::NULL, err: File::NULL)
        .and_return(true)

      # When
      result = rust.available?

      # Then
      expect(result).to be true
    end

    it "returns false when rust is not available via mise" do
      # Given
      allow(rust)
        .to receive(:system)
        .with("mise", "which", "rustc", out: File::NULL, err: File::NULL)
        .and_return(false)

      # When
      result = rust.available?

      # Then
      expect(result).to be false
    end
  end

  describe "#version" do
    it "returns the installed rust version" do
      # Given
      status = instance_double(Process::Status, success?: true)
      allow(Open3).to receive(:capture2)
        .with("mise", "current", "rust")
        .and_return(["rust 1.93.0\n", status])

      # When
      result = rust.version

      # Then
      expect(result).to eq("1.93.0")
    end

    it "returns nil when command fails" do
      # Given
      status = instance_double(Process::Status, success?: false)
      allow(Open3).to receive(:capture2)
        .with("mise", "current", "rust")
        .and_return(["", status])

      # When
      result = rust.version

      # Then
      expect(result).to be_nil
    end

    it "returns nil when mise is not installed" do
      # Given
      allow(Open3).to receive(:capture2)
        .with("mise", "current", "rust")
        .and_raise(Errno::ENOENT)

      # When
      result = rust.version

      # Then
      expect(result).to be_nil
    end
  end

  describe "#installed?" do
    it "returns true when rust is available and has version" do
      # Given
      allow(rust).to receive(:available?).and_return(true)
      allow(rust).to receive(:version).and_return("1.93.0")

      # When
      result = rust.installed?

      # Then
      expect(result).to be true
    end

    it "returns false when rust is not available" do
      # Given
      allow(rust).to receive(:available?).and_return(false)
      allow(rust).to receive(:version).and_return(nil)

      # When
      result = rust.installed?

      # Then
      expect(result).to be false
    end

    it "returns false when rust is available but version is nil" do
      # Given
      allow(rust).to receive(:available?).and_return(true)
      allow(rust).to receive(:version).and_return(nil)

      # When
      result = rust.installed?

      # Then
      expect(result).to be false
    end
  end

  describe "#target_version" do
    it "returns version from config when available" do
      # When
      result = rust.target_version

      # Then
      expect(result).to eq("1.93.0")
    end

    it "returns DEFAULT_VERSION when config version is nil" do
      # Given
      allow(mock_config).to receive(:version).and_return(nil)

      # When
      result = rust.target_version

      # Then
      expect(result).to eq(Component::RustComponent::DEFAULT_VERSION)
    end
  end

  describe "#latest_version" do
    it "returns the target version" do
      # When
      result = rust.latest_version

      # Then
      expect(result).to eq("1.93.0")
    end
  end

  describe "#install" do
    it "does nothing when rust is already installed" do
      # Given
      allow(rust).to receive(:installed?).and_return(true)
      allow(rust).to receive(:version).and_return("1.93.0")
      allow(rust).to receive(:install!)

      # When
      rust.install

      # Then
      expect(rust).not_to have_received(:install!)
      expect(null_logger).to have_received(:info).with(/already installed/)
    end

    it "calls install! when rust is not installed" do
      # Given
      allow(rust).to receive(:installed?).and_return(false)
      allow(rust).to receive(:install!)

      # When
      rust.install

      # Then
      expect(rust).to have_received(:install!)
    end
  end

  describe "#install!" do
    it "installs rust via mise using target version" do
      # Given
      allow(rust).to receive(:runCmd)
        .with("mise", "use", "--global", "rust@1.93.0")
        .and_return(["", "", instance_double(Process::Status, success?: true)])
      allow(rust).to receive(:setup_cargo_path)

      # When
      rust.install!

      # Then
      expect(rust).to have_received(:runCmd)
        .with("mise", "use", "--global", "rust@1.93.0")
      expect(rust).to have_received(:setup_cargo_path)
      expect(null_logger).to have_received(:info).with(/Installing Rust/)
      expect(null_logger).to have_received(:info).with(/installed successfully/)
    end
  end
end
