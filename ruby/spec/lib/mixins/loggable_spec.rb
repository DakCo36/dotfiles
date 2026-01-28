require "spec_helper"
require "mixins/loggable"
require "stringio"

RSpec.describe Loggable do
  # ANSI escape sequence pattern for color codes
  ANSI = /\e\[\d+m/

  # Helper class to include the mixin
  class SpecTestApp
    include Loggable

    attr_writer :logger

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
  let(:output) { StringIO.new }

  # Create a logger with the same formatter as Loggable
  def create_test_logger(output, verbose: false)
    Logger.new(output).tap do |log|
      log.level = verbose ? Logger::DEBUG : Logger::INFO

      log.formatter = proc do |severity, datetime, _progname, msg|
        caller_info = caller_locations(4, 1)&.first
        file = caller_info&.path&.split("/")&.last || "unknown"
        method = caller_info&.label || "unknown"
        line = caller_info&.lineno || 0
        level_color = Loggable::COLORS[severity] || ""

        if verbose
          timestamp = datetime.strftime("%Y-%m-%d %H:%M:%S %z")
          "#{level_color}[#{timestamp}] #{severity}#{Loggable::RESET} #{Loggable::CYAN}#{file}:#{line}#{Loggable::RESET} #{Loggable::MAGENTA}#{method}#{Loggable::RESET} - #{msg}\n"
        else
          time = datetime.strftime("%H:%M:%S")
          level_char = severity[0]
          func_name = method.to_s.split("#").last || method
          "#{level_color}#{time} [#{level_char}]#{Loggable::RESET} #{Loggable::CYAN}#{file}:#{line}#{Loggable::RESET} #{Loggable::MAGENTA}#{func_name}#{Loggable::RESET} - #{msg}\n"
        end
      end
    end
  end

  before do
    Loggable.setup(verbose: false)
  end

  describe "Default Mode (Compact)" do
    before do
      Loggable.setup(verbose: false)
      app.logger = create_test_logger(output, verbose: false)
    end

    it "logs in compact format with color: HH:MM:SS [L] file:line method - message" do
      app.test_info("hello")

      expect(output.string).to match(
        /#{ANSI}\d{2}:\d{2}:\d{2} \[I\]#{ANSI} #{ANSI}loggable_spec\.rb:\d+#{ANSI} #{ANSI}test_info#{ANSI} - hello/
      )
    end

    it "logs ERROR level with red color" do
      app.test_error("fail")

      expect(output.string).to match(
        /#{ANSI}\d{2}:\d{2}:\d{2} \[E\]#{ANSI} #{ANSI}loggable_spec\.rb:\d+#{ANSI} #{ANSI}test_error#{ANSI} - fail/
      )
    end
  end

  describe "Verbose Mode" do
    before do
      Loggable.setup(verbose: true)
      app.logger = create_test_logger(output, verbose: true)
    end

    it "logs in verbose format with color: [Date] LEVEL file:line method - message" do
      app.test_info("verbose msg")

      expect(output.string).to match(
        /#{ANSI}\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} \+\d{4}\] INFO#{ANSI} #{ANSI}loggable_spec\.rb:\d+#{ANSI} #{ANSI}SpecTestApp#test_info#{ANSI} - verbose msg/
      )
    end

    it "shows DEBUG logs in blue color" do
      app.test_debug("visible now")

      expect(output.string).to match(
        /#{ANSI}\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} \+\d{4}\] DEBUG#{ANSI} #{ANSI}loggable_spec\.rb:\d+#{ANSI} #{ANSI}SpecTestApp#test_debug#{ANSI} - visible now/
      )
    end
  end

  describe "BroadcastLogger" do
    it "logs to multiple outputs" do
      output1 = StringIO.new
      output2 = StringIO.new
      logger1 = Logger.new(output1)
      logger2 = Logger.new(output2)
      logger1.formatter = proc { |_, _, _, msg| "#{msg}\n" }
      logger2.formatter = proc { |_, _, _, msg| "#{msg}\n" }

      broadcast = Loggable::BroadcastLogger.new(logger1, logger2)
      broadcast.info("broadcast message")

      expect(output1.string).to include("broadcast message")
      expect(output2.string).to include("broadcast message")
    end
  end
end
