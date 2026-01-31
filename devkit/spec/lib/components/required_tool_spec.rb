require "spec_helper"
require "components/required_tool"

RSpec.describe Component::RequiredTool do
  # Create a concrete test class since RequiredTool is abstract
  let(:test_class) do
    Class.new(described_class) do
      def self.name
        "TestRequiredTool"
      end

      def available?
        true
      end

      def version
        "1.0.0"
      end
    end
  end

  # Reset singleton for each test
  before do
    test_class.instance_variable_set(:@singleton__instance__, nil)
  end

  subject(:tool) { test_class.instance }

  describe "#installed?" do
    it "returns true when available? is true" do
      allow(tool).to receive(:available?).and_return(true)
      expect(tool.installed?).to be true
    end

    it "returns false when available? is false" do
      allow(tool).to receive(:available?).and_return(false)
      expect(tool.installed?).to be false
    end
  end

  describe "Configurable mixin" do
    it "does not include Configurable" do
      expect(tool).not_to respond_to(:config)
    end
  end

  describe "install! method" do
    it "does not have install! method defined in RequiredTool" do
      # RequiredTool should not define install! - it's for required tools assumed to be pre-installed
      expect(described_class.instance_methods(false)).not_to include(:install!)
    end
  end
end
