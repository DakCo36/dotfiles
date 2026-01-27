require "spec_helper"
require "mixins/loggable"

RSpec.describe Loggable do
  # ANSI escape sequence pattern for color codes
  ANSI = /\e\[\d+m/

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

    it "logs in compact format with color: HH:MM:SS [L] file method - message" do
      # Expected: "12:34:56 \e[32m[I]\e[0m loggable_spec.rb SpecTestApp#test_info - hello"
      expect { app.test_info("hello") }.to output(
        /\d{2}:\d{2}:\d{2} #{ANSI}\[I\]#{ANSI} loggable_spec\.rb SpecTestApp#test_info - hello/
      ).to_stdout
    end

    it "logs ERROR level with red color" do
      expect { app.test_error("fail") }.to output(
        /\d{2}:\d{2}:\d{2} #{ANSI}\[E\]#{ANSI} loggable_spec\.rb SpecTestApp#test_error - fail/
      ).to_stdout
    end
  end

  describe "Verbose Mode" do
    before do 
      Loggable.setup(verbose: true)
      app.remove_instance_variable(:@logger) if app.instance_variable_defined?(:@logger)
    end

    it "logs in verbose format with color: [Date] LEVEL file:line method - message" do
      # Expected: "[2026-01-27 10:52:33 +0900] \e[32mINFO\e[0m loggable_spec.rb:14 SpecTestApp#test_info - verbose msg"
      expect { app.test_info("verbose msg") }.to output(
        /\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} \+\d{4}\] #{ANSI}INFO#{ANSI} loggable_spec\.rb:\d+ SpecTestApp#test_info - verbose msg/
      ).to_stdout
    end

    it "shows DEBUG logs in blue color" do
      expect { app.test_debug("visible now") }.to output(
        /#{ANSI}DEBUG#{ANSI} loggable_spec\.rb:\d+ SpecTestApp#test_debug - visible now/
      ).to_stdout
    end
  end
end
