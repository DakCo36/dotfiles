require "spec_helper"
require "open3"
require "components/language/node"

RSpec.describe Component::NodeComponent do
  subject(:node) { described_class.instance }
  let(:null_logger) { instance_spy(Logger) }

  before do
    allow(node).to receive(:logger).and_return(null_logger)
  end

  describe "#available?" do
    it "returns true when node is available via mise" do
      # Given
      allow(node)
        .to receive(:system)
        .with("mise", "which", "node", out: File::NULL, err: File::NULL)
        .and_return(true)

      # When
      result = node.available?

      # Then
      expect(result).to be true
    end

    it "returns false when node is not available via mise" do
      # Given
      allow(node)
        .to receive(:system)
        .with("mise", "which", "node", out: File::NULL, err: File::NULL)
        .and_return(false)

      # When
      result = node.available?

      # Then
      expect(result).to be false
    end
  end

  describe "#version" do
    it "returns the installed node version" do
      # Given
      status = instance_double(Process::Status, success?: true)
      allow(Open3).to receive(:capture2)
        .with("mise", "current", "node")
        .and_return(["node 24.13.0\n", status])

      # When
      result = node.version

      # Then
      expect(result).to eq("24.13.0")
    end

    it "returns nil when command fails" do
      # Given
      status = instance_double(Process::Status, success?: false)
      allow(Open3).to receive(:capture2)
        .with("mise", "current", "node")
        .and_return(["", status])

      # When
      result = node.version

      # Then
      expect(result).to be_nil
    end

    it "returns nil when mise is not installed" do
      # Given
      allow(Open3).to receive(:capture2)
        .with("mise", "current", "node")
        .and_raise(Errno::ENOENT)

      # When
      result = node.version

      # Then
      expect(result).to be_nil
    end
  end

  describe "#installed?" do
    it "returns true when node is available and has version" do
      # Given
      allow(node).to receive(:available?).and_return(true)
      allow(node).to receive(:version).and_return("24.13.0")

      # When
      result = node.installed?

      # Then
      expect(result).to be true
    end

    it "returns false when node is not available" do
      # Given
      allow(node).to receive(:available?).and_return(false)
      allow(node).to receive(:version).and_return(nil)

      # When
      result = node.installed?

      # Then
      expect(result).to be false
    end

    it "returns false when node is available but version is nil" do
      # Given
      allow(node).to receive(:available?).and_return(true)
      allow(node).to receive(:version).and_return(nil)

      # When
      result = node.installed?

      # Then
      expect(result).to be false
    end
  end

  describe "#latest_version" do
    it "returns the fixed NODE_VERSION constant" do
      # When
      result = node.latest_version

      # Then
      expect(result).to eq(Component::NodeComponent::NODE_VERSION)
      expect(result).to eq("24.13.0")
    end
  end

  describe "#install" do
    it "does nothing when node is already installed" do
      # Given
      allow(node).to receive(:installed?).and_return(true)
      allow(node).to receive(:version).and_return("24.13.0")
      allow(node).to receive(:install!)

      # When
      node.install

      # Then
      expect(node).not_to have_received(:install!)
      expect(null_logger).to have_received(:info).with(/already installed/)
    end

    it "calls install! when node is not installed" do
      # Given
      allow(node).to receive(:installed?).and_return(false)
      allow(node).to receive(:install!)

      # When
      node.install

      # Then
      expect(node).to have_received(:install!)
    end
  end

  describe "#install!" do
    it "installs node via mise" do
      # Given
      allow(node).to receive(:runCmd)
        .with("mise", "use", "--global", "node@24.13.0")
        .and_return(["", "", instance_double(Process::Status, success?: true)])

      # When
      node.install!

      # Then
      expect(node).to have_received(:runCmd)
        .with("mise", "use", "--global", "node@24.13.0")
      expect(null_logger).to have_received(:info).with(/Installing Node/)
      expect(null_logger).to have_received(:info).with(/installed successfully/)
    end
  end
end
