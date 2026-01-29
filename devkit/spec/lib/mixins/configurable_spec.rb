require "logger"
require "rspec"
require "spec_helper"
require "mixins/configurable"
require "components/configuration"

RSpec.describe Configurable do
  # Test fixture data
  let(:fixture_config) do
    {
      "fzf" => {
        "enabled" => true,
        "version" => "latest",
        "source" => "github",
        "owner" => "junegunn",
        "repo" => "fzf"
      }
    }
  end

  # Create a test class that includes Configurable
  let(:test_class) do
    Class.new do
      include Configurable

      def display_name
        "fzf"
      end
    end
  end

  let(:instance) { test_class.new }

  before do
    # Reset Configuration singleton before each test
    Singleton.__init__(Components::Configuration)

    # Mock manifest loading to use fixture data instead of real file
    allow_any_instance_of(Components::Configuration)
      .to receive(:load_manifest)
      .and_return(fixture_config)
  end

  describe "#component_config" do
    context "when manifest exists" do
      it "returns the component's configuration hash" do
        config = instance.component_config
        expect(config).to be_a(Hash)
        expect(config["owner"]).to eq("junegunn")
        expect(config["repo"]).to eq("fzf")
      end
    end

    context "when component has no config" do
      let(:test_class) do
        Class.new do
          include Configurable

          def display_name
            "nonexistent_component"
          end
        end
      end

      it "returns an empty hash" do
        expect(instance.component_config).to eq({})
      end
    end
  end

  describe "#config_version" do
    it "returns the configured version" do
      expect(instance.config_version).to eq("latest")
    end
  end

  describe "#config_enabled?" do
    it "returns true when enabled is true" do
      expect(instance.config_enabled?).to be true
    end

    context "when component is not in manifest" do
      let(:test_class) do
        Class.new do
          include Configurable

          def display_name
            "nonexistent_component"
          end
        end
      end

      it "returns false" do
        expect(instance.config_enabled?).to be false
      end
    end
  end

  describe "#config_source" do
    it "returns the configured source type" do
      expect(instance.config_source).to eq("github")
    end
  end

  describe "#config_key" do
    it "defaults to display_name" do
      expect(instance.config_key).to eq("fzf")
    end
  end

  describe "#config" do
    it "returns the Configuration singleton instance" do
      # Given / When
      result = instance.config

      # Then
      expect(result).to be_a(Components::Configuration)
      expect(result).to eq(Components::Configuration.instance)
    end
  end
end
