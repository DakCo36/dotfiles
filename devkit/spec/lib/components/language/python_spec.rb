require "spec_helper"
require "open3"
require "components/language/python"

RSpec.describe Component::PythonComponent do
  subject(:python) { described_class.instance }
  let(:null_logger) { instance_spy(Logger) }

  before do
    allow(python).to receive(:logger).and_return(null_logger)
  end

  describe "#available?" do
    it "returns true when python is available via mise" do
      # Given
      allow(python)
        .to receive(:system)
        .with("mise", "which", "python", out: File::NULL, err: File::NULL)
        .and_return(true)

      # When
      result = python.available?

      # Then
      expect(result).to be true
    end

    it "returns false when python is not available via mise" do
      # Given
      allow(python)
        .to receive(:system)
        .with("mise", "which", "python", out: File::NULL, err: File::NULL)
        .and_return(false)

      # When
      result = python.available?

      # Then
      expect(result).to be false
    end
  end

  describe "#version" do
    it "returns the installed python version" do
      # Given
      status = instance_double(Process::Status, success?: true)
      allow(Open3).to receive(:capture2)
        .with("mise", "current", "python")
        .and_return(["python 3.12.8\n", status])

      # When
      result = python.version

      # Then
      expect(result).to eq("3.12.8")
    end

    it "returns nil when command fails" do
      # Given
      status = instance_double(Process::Status, success?: false)
      allow(Open3).to receive(:capture2)
        .with("mise", "current", "python")
        .and_return(["", status])

      # When
      result = python.version

      # Then
      expect(result).to be_nil
    end

    it "returns nil when mise is not installed" do
      # Given
      allow(Open3).to receive(:capture2)
        .with("mise", "current", "python")
        .and_raise(Errno::ENOENT)

      # When
      result = python.version

      # Then
      expect(result).to be_nil
    end
  end

  describe "#installed?" do
    it "returns true when python is available and has version" do
      # Given
      allow(python).to receive(:available?).and_return(true)
      allow(python).to receive(:version).and_return("3.12.8")

      # When
      result = python.installed?

      # Then
      expect(result).to be true
    end

    it "returns false when python is not available" do
      # Given
      allow(python).to receive(:available?).and_return(false)
      allow(python).to receive(:version).and_return(nil)

      # When
      result = python.installed?

      # Then
      expect(result).to be false
    end

    it "returns false when python is available but version is nil" do
      # Given
      allow(python).to receive(:available?).and_return(true)
      allow(python).to receive(:version).and_return(nil)

      # When
      result = python.installed?

      # Then
      expect(result).to be false
    end
  end

  describe "#latest_version" do
    it "returns the fixed PYTHON_VERSION constant" do
      # When
      result = python.latest_version

      # Then
      expect(result).to eq(Component::PythonComponent::PYTHON_VERSION)
      expect(result).to eq("3.12.8")
    end
  end

  describe "#install" do
    it "does nothing when python is already installed" do
      # Given
      allow(python).to receive(:installed?).and_return(true)
      allow(python).to receive(:version).and_return("3.12.8")
      allow(python).to receive(:install!)

      # When
      python.install

      # Then
      expect(python).not_to have_received(:install!)
      expect(null_logger).to have_received(:info).with(/already installed/)
    end

    it "calls install! when python is not installed" do
      # Given
      allow(python).to receive(:installed?).and_return(false)
      allow(python).to receive(:install!)

      # When
      python.install

      # Then
      expect(python).to have_received(:install!)
    end
  end

  describe "#install!" do
    it "installs python via mise" do
      # Given
      allow(python).to receive(:runCmd)
        .with("mise", "use", "--global", "python@3.12.8")
        .and_return(["", "", instance_double(Process::Status, success?: true)])

      # When
      python.install!

      # Then
      expect(python).to have_received(:runCmd)
        .with("mise", "use", "--global", "python@3.12.8")
      expect(null_logger).to have_received(:info).with(/Installing Python/)
      expect(null_logger).to have_received(:info).with(/installed successfully/)
    end
  end
end
