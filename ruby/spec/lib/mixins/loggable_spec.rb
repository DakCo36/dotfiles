require "spec_helper"
require "mixins/loggable"

RSpec.describe Loggable do
  # Helper class to include the mixin
  class SpecTestApp
    include Loggable

    def test_info(msg)
      logger.info(msg)
    end

    def test_error(msg)
      logger.error(msg)
    end

    def test_debug(msg)
      logger.debug(msg)
    end
  end

  let(:app) { SpecTestApp.new }

  # Reset Loggable configuration before each test
  before do
    Loggable.setup(verbose: false)
    # We need to force a reset of the memoized logger to apply new settings
    if app.instance_variable_defined?(:@logger)
      app.remove_instance_variable(:@logger) 
    end
  end

  describe "Default Mode (Compact)" do
    before { Loggable.setup(verbose: false) }

    it "logs in compact format: HH:MM:SS [L] file method - message" do
      # Expected: "12:34:56 [I] loggerable_spec.rb test_info - hello"
      expect { app.test_info("hello") }.to output(
        /\d{2}:\d{2}:\d{2} \[I\] loggable_spec\.rb SpecTestApp#test_info - hello/
      ).to_stdout
    end

    it "logs ERROR level correctly" do
      expect { app.test_error("fail") }.to output(
        /\d{2}:\d{2}:\d{2} \[E\] loggable_spec\.rb SpecTestApp#test_error - fail/
      ).to_stdout
    end
  end

  describe "Verbose Mode" do
    before do 
      Loggable.setup(verbose: true)
      app.remove_instance_variable(:@logger) if app.instance_variable_defined?(:@logger)
    end

    it "logs in verbose format: [Date] LEVEL file:line method - message" do
      # Expected: "[2026-01-27 10:52:33 +0900] INFO loggerable_spec.rb:14 test_info - verbose msg"
      expect { app.test_info("verbose msg") }.to output(
        /\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} \+\d{4}\] INFO loggable_spec\.rb:\d+ SpecTestApp#test_info - verbose msg/
      ).to_stdout
    end

    it "shows DEBUG logs (which are hidden in Compact defaults)" do
      expect { app.test_debug("visible now") }.to output(
        /DEBUG loggable_spec\.rb:\d+ SpecTestApp#test_debug - visible now/
      ).to_stdout
    end
  end
end
