require "logger"

module Loggable
  # ANSI color codes for log levels
  COLORS = {
    "DEBUG" => "\e[34m",  # Blue
    "INFO"  => "\e[32m",  # Green
    "WARN"  => "\e[33m",  # Yellow
    "ERROR" => "\e[31m",  # Red
  }.freeze
  CYAN = "\e[36m"     # Cyan - for filename
  MAGENTA = "\e[35m"  # Magenta - for method name
  RESET = "\e[0m"

  LOG_FILE_PATH = "/tmp/dotfiles.ruby.log"

  LOG_LEVELS = {
    "debug" => Logger::DEBUG,
    "info"  => Logger::INFO,
    "warn"  => Logger::WARN,
    "error" => Logger::ERROR,
  }.freeze

  # Log entry with caller info captured at call site
  LogEntry = Struct.new(:message, :file, :line, :method_name)

  attr_reader :logger

  # Setup logging configuration
  # @param verbose [Boolean] Use verbose output format
  # @param level [String, nil] Log level (debug/info/warn/error), overrides ENV['LOG_LEVEL']
  def self.setup(verbose: false, level: nil)
    @verbose = verbose
    @log_level = set_log_level(level)
  end

  def self.verbose?
    @verbose
  end

  def self.log_level
    @log_level || set_log_level(nil)
  end

  def self.set_log_level(level)
    level_str = level || ENV["LOG_LEVEL"] || "info"
    LOG_LEVELS[level_str.to_s.downcase] || Logger::INFO
  end

  def self.colorize(severity, text)
    color = COLORS[severity] || ""
    "#{color}#{text}#{RESET}"
  end

  # Broadcast logger - outputs to both console and file
  def logger
    @logger ||= create_broadcast_logger
  end

  private

  def create_broadcast_logger
    BroadcastLogger.new(
      create_console_logger,
      create_file_logger
    )
  end

  def create_console_logger
    Logger.new($stdout).tap do |log|
      log.level = Loggable.log_level
      log.formatter = console_formatter
    end
  end

  def create_file_logger
    Logger.new(LOG_FILE_PATH).tap do |log|
      log.level = Logger::DEBUG  # File always captures all logs
      log.formatter = file_formatter
    end
  end

  def console_formatter
    proc do |severity, datetime, _progname, msg|
      file, line, method_name, text = extract_log_info(msg)
      level_color = Loggable::COLORS[severity] || ""

      if Loggable.verbose?
        timestamp = datetime.strftime("%Y-%m-%d %H:%M:%S %z")
        "#{level_color}[#{timestamp}] #{severity}#{RESET} #{CYAN}#{file}:#{line}#{RESET} #{MAGENTA}#{method_name}#{RESET} - #{text}\n"
      else
        time = datetime.strftime("%H:%M:%S")
        level_char = severity[0]
        func_name = method_name.to_s.split("#").last || method_name
        "#{level_color}#{time} [#{level_char}]#{RESET} #{CYAN}#{file}:#{line}#{RESET} #{MAGENTA}#{func_name}#{RESET} - #{text}\n"
      end
    end
  end

  def file_formatter
    proc do |severity, datetime, _progname, msg|
      file, line, method_name, text = extract_log_info(msg)
      timestamp = datetime.strftime("%Y-%m-%d %H:%M:%S %z")
      "[#{timestamp}] #{severity} #{file}:#{line} #{method_name} - #{text}\n"
    end
  end

  def extract_log_info(msg)
    if msg.is_a?(LogEntry)
      [msg.file, msg.line, msg.method_name, msg.message]
    else
      # Fallback for direct Logger usage
      ["unknown", 0, "unknown", msg.to_s]
    end
  end

  # Broadcast logger that captures caller info and forwards to multiple loggers
  class BroadcastLogger
    def initialize(*loggers)
      @loggers = loggers
    end

    %i[debug info warn error fatal unknown].each do |level|
      define_method(level) do |msg = nil, &block|
        # Capture caller info at call site (before stack gets deeper)
        caller_info = caller_locations(1, 1)&.first
        file = caller_info&.path&.split("/")&.last || "unknown"
        line = caller_info&.lineno || 0
        method_name = caller_info&.label || "unknown"

        entry = Loggable::LogEntry.new(msg, file, line, method_name)
        @loggers.each { |logger| logger.send(level, entry, &block) }
      end
    end

    def level=(level)
      @loggers.first.level = level
    end

    def level
      @loggers.first.level
    end
  end
end
