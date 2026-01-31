require "spec_helper"
require "components/installable_component"

RSpec.describe Component::InstallableComponent do
  # Create a concrete test class since InstallableComponent is abstract
  let(:test_class) do
    Class.new(described_class) do
      def self.name
        "TestInstallableComponent"
      end

      def available?
        true
      end

      def version
        "1.0.0"
      end

      def installed?
        available?
      end

      def install!
        # noop for testing
      end

      def latest_version
        "2.0.0"
      end

      # Override config_key to return a valid key
      def config_key
        "test-component"
      end
    end
  end

  # Reset singleton for each test
  before do
    test_class.instance_variable_set(:@singleton__instance__, nil)
  end

  subject(:component) { test_class.instance }

  let(:null_logger) { instance_spy(Logger) }

  before do
    allow(component).to receive(:logger).and_return(null_logger)
  end

  describe "Configurable mixin" do
    it "includes Configurable and responds to config method" do
      expect(component).to respond_to(:config)
      expect(component.config).to be_a(Components::Configuration::ComponentConfig)
    end
  end

  describe "#upgradable?" do
    context "when installed and newer version available" do
      it "returns true" do
        allow(component).to receive(:installed?).and_return(true)
        allow(component).to receive(:version).and_return("1.0.0")
        allow(component).to receive(:latest_version).and_return("2.0.0")

        expect(component.upgradable?).to be true
      end
    end

    context "when already at latest version" do
      it "returns false" do
        allow(component).to receive(:installed?).and_return(true)
        allow(component).to receive(:version).and_return("2.0.0")
        allow(component).to receive(:latest_version).and_return("2.0.0")

        expect(component.upgradable?).to be false
      end
    end

    context "when not installed" do
      it "returns false" do
        allow(component).to receive(:installed?).and_return(false)

        expect(component.upgradable?).to be false
      end
    end
  end

  describe "#update" do
    context "when upgradable" do
      it "calls install!" do
        allow(component).to receive(:upgradable?).and_return(true)
        allow(component).to receive(:install!)

        component.update

        expect(component).to have_received(:install!)
      end
    end

    context "when not upgradable" do
      it "does not call install!" do
        allow(component).to receive(:upgradable?).and_return(false)
        allow(component).to receive(:install!)

        component.update

        expect(component).not_to have_received(:install!)
      end
    end
  end

  describe "Installable mixin" do
    it "is prepended" do
      expect(described_class.ancestors).to include(Installable)
    end
  end
end
