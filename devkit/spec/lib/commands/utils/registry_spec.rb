require "spec_helper"
require "commands/utils/registry"

RSpec.describe Commands::Registry do
  subject(:registry) { described_class.instance }

  describe ".registered_components" do
    it "auto-discovers installable components" do
      components = described_class.registered_components
      expect(components).not_to be_empty
    end

    it "includes known installable components" do
      component_names = described_class.registered_components.map(&:name)
      expect(component_names).to include("Component::BatComponent")
      expect(component_names).to include("Component::FzfComponent")
      expect(component_names).to include("Component::NeovimComponent")
    end

    it "excludes RequiredComponent subclasses" do
      component_names = described_class.registered_components.map(&:name)
      expect(component_names).not_to include("Component::CurlComponent")
      expect(component_names).not_to include("Component::GitComponent")
      expect(component_names).not_to include("Component::TarComponent")
    end

    it "excludes abstract classes" do
      component_names = described_class.registered_components.map(&:name)
      expect(component_names).not_to include("Component::BaseComponent")
      expect(component_names).not_to include("Component::InstallableComponent")
      expect(component_names).not_to include("Component::RequiredComponent")
    end
  end

  describe "#all" do
    it "returns instances of registered components" do
      all = registry.all
      expect(all).to all(be_a(Component::BaseComponent))
    end
  end

  describe "#find" do
    it "finds component by name" do
      component = registry.find("bat")
      expect(component).to be_a(Component::BatComponent)
    end

    it "returns nil for unknown component" do
      component = registry.find("nonexistent")
      expect(component).to be_nil
    end
  end

  describe "#component_names" do
    it "returns lowercase hyphenated names" do
      names = registry.component_names
      expect(names).to include("bat")
      expect(names).to include("fzf")
    end
  end
end
