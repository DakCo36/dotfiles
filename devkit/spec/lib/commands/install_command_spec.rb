require "spec_helper"
require "commands/install_command"

RSpec.describe Commands::InstallCommand do
  let(:registry) { Commands::Registry.instance }
  let(:null_logger) { instance_spy(Logger) }

  before do
    Commands::RequiredComponentChecker::REQUIRED_COMPONENTS.each do |component_class|
      allow(component_class.instance).to receive(:available?).and_return(true)
    end
  end

  describe "#execute" do
    context "when all components are already installed" do
      it "reports no components to install" do
        allow(registry).to receive(:not_installed).and_return([])

        command = described_class.new
        allow(command).to receive(:logger).and_return(null_logger)

        command.execute([])

        expect(null_logger).to have_received(:info).with(/설치할 컴포넌트가 없습니다/)
      end
    end

    context "when dry-run mode is enabled" do
      it "shows plan without executing installation" do
        mock_component = instance_double(
          Component::BatComponent,
          display_name: "bat",
          installed?: false,
          dependencies: {},
          latest_version: "0.24.0"
        )
        allow(mock_component).to receive(:is_a?).with(anything).and_return(false)
        allow(mock_component).to receive(:class).and_return(Component::BatComponent)
        allow(mock_component).to receive(:respond_to?).with(:install!).and_return(true)

        allow(registry).to receive(:not_installed).and_return([mock_component])

        resolver = instance_double(Commands::DependencyResolver)
        allow(Commands::DependencyResolver).to receive(:new).and_return(resolver)
        allow(resolver).to receive(:resolve).and_return([mock_component])

        command = described_class.new(dry_run: true)
        allow(command).to receive(:logger).and_return(null_logger)

        command.execute([])

        expect(null_logger).to have_received(:info).with(/dry-run/)
      end
    end
  end
end
