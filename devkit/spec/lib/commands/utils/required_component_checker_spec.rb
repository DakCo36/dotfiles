require "spec_helper"
require "commands/utils/required_component_checker"

RSpec.describe Commands::RequiredComponentChecker do
  describe ".check!" do
    context "when all required components are available" do
      it "does not raise" do
        Commands::RequiredComponentChecker::REQUIRED_COMPONENTS.each do |component_class|
          allow(component_class.instance).to receive(:available?).and_return(true)
        end

        expect { described_class.check! }.not_to raise_error
      end
    end

    context "when some required components are missing" do
      it "raises MissingToolError with component names" do
        curl = Component::CurlComponent.instance
        allow(curl).to receive(:available?).and_return(false)
        allow(curl).to receive(:display_name).and_return("curl")

        (Commands::RequiredComponentChecker::REQUIRED_COMPONENTS - [Component::CurlComponent]).each do |component_class|
          allow(component_class.instance).to receive(:available?).and_return(true)
        end

        expect { described_class.check! }.to raise_error(
          Commands::MissingToolError, /curl/
        )
      end
    end

    context "when all required components are missing" do
      it "raises MissingToolError listing all component names" do
        Commands::RequiredComponentChecker::REQUIRED_COMPONENTS.each do |component_class|
          component = component_class.instance
          allow(component).to receive(:available?).and_return(false)
        end

        expect { described_class.check! }.to raise_error(Commands::MissingToolError)
      end
    end
  end
end
