require "spec_helper"
require "components/required_component"

RSpec.describe Component::RequiredComponent do
  let(:test_class) do
    Class.new(described_class) do
      def self.name
        "TestRequiredComponent"
      end

      def available?
        true
      end

      def version
        "1.0.0"
      end
    end
  end

  before do
    test_class.instance_variable_set(:@singleton__instance__, nil)
  end

  subject(:component) { test_class.instance }

  describe "Configurable mixin" do
    it "does not include Configurable" do
      expect(component).not_to respond_to(:config)
    end
  end

  describe "install! method" do
    it "does not have install! method defined in RequiredComponent" do
      expect(described_class.instance_methods(false)).not_to include(:install!)
    end
  end
end
