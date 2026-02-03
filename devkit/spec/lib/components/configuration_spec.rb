require "rspec"
require "spec_helper"
require "components/configuration"

RSpec.describe Components::Configuration do
  # Given
  let(:home_path) { "/home/user" }
  let(:config) { Components::Configuration.instance }

  before do
    # Reset singleton before each test
    Singleton.__init__(Components::Configuration)
    allow(Dir).to receive(:home).and_return(home_path)
  end

  context "when home directory is not changed" do
    it "return user home directory" do
      # When
      # Then
      expect(config.home).to eq(Dir.home)
    end

    it "allows setting a new home directory" do
      # Given
      new_home = "/tmp"
      # When
      config.home = new_home
      # Then
      expect(config.home).to eq(new_home)
    end
  end

  describe Components::Configuration::ComponentConfig do
    describe "default values" do
      it "has enabled true by default" do
        config_data = Components::Configuration::ComponentConfig.new
        expect(config_data.enabled).to be true
      end

      it "has nil for optional fields by default" do
        config_data = Components::Configuration::ComponentConfig.new
        expect(config_data.source).to be_nil
        expect(config_data.version).to be_nil
        expect(config_data.owner).to be_nil
        expect(config_data.repo).to be_nil
        expect(config_data.branch).to be_nil
        expect(config_data.resources).to be_nil
        expect(config_data.fallback_version).to be_nil
      end
    end

    describe "#contract_path" do
      it "replaces home directory with $HOME" do
        config_data = Components::Configuration::ComponentConfig.new(home: "/home/user")
        expect(config_data.contract_path("/home/user/test")).to eq("$HOME/test")
      end

      it "returns the original path if home directory is not in the path" do
        config_data = Components::Configuration::ComponentConfig.new(home: "/home/user")
        expect(config_data.contract_path("/tmp/test")).to eq("/tmp/test")
      end
    end

    describe "with values" do
      it "stores provided values" do
        config_data = Components::Configuration::ComponentConfig.new(
          enabled: true,
          source: "github",
          version: "1.0.0",
          owner: "junegunn",
          repo: "fzf"
        )
        expect(config_data.enabled).to be true
        expect(config_data.source).to eq("github")
        expect(config_data.version).to eq("1.0.0")
        expect(config_data.owner).to eq("junegunn")
        expect(config_data.repo).to eq("fzf")
      end

      it "is immutable" do
        config_data = Components::Configuration::ComponentConfig.new(owner: "test")
        expect { config_data.instance_variable_set(:@owner, "changed") }.to raise_error(FrozenError)
      end
    end
  end

  describe "#component_config" do
    let(:fixture_manifest) do
      {
        "fzf" => {
          "enabled" => true,
          "source" => "github",
          "version" => "latest",
          "owner" => "junegunn",
          "repo" => "fzf"
        }
      }
    end

    before do
      allow_any_instance_of(Components::Configuration)
        .to receive(:load_manifest)
        .and_return(fixture_manifest)
    end

    it "returns a ComponentConfig object" do
      result = config.component_config("fzf")
      expect(result).to be_a(Components::Configuration::ComponentConfig)
    end

    it "returns correct values from manifest" do
      result = config.component_config("fzf")
      expect(result.owner).to eq("junegunn")
      expect(result.repo).to eq("fzf")
      expect(result.source).to eq("github")
    end

    context "when component not found" do
      it "returns ComponentConfig with enabled: false" do
        result = config.component_config("nonexistent")
        expect(result.enabled).to be false
      end
    end
  end
end
