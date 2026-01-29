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
      caller_info = caller_locations(5, 1)&.first
      file = caller_info&.path&.split("/")&.last || "unknown"
      method = caller_info&.label || "unknown"
      line = caller_info&.lineno || 0
      level_color = Loggable::COLORS[severity] || ""

      if Loggable.verbose?
        timestamp = datetime.strftime("%Y-%m-%d %H:%M:%S %z")
        "#{level_color}[#{timestamp}] #{severity}#{RESET} #{CYAN}#{file}:#{line}#{RESET} #{MAGENTA}#{method}#{RESET} - #{msg}\n"
      else
        time = datetime.strftime("%H:%M:%S")
        level_char = severity[0]
        func_name = method.to_s.split("#").last || method
        "#{level_color}#{time} [#{level_char}]#{RESET} #{CYAN}#{file}:#{line}#{RESET} #{MAGENTA}#{func_name}#{RESET} - #{msg}\n"
      end
    end
  end

  def file_formatter
    proc do |severity, datetime, _progname, msg|
      caller_info = caller_locations(5, 1)&.first
      file = caller_info&.path&.split("/")&.last || "unknown"
      method = caller_info&.label || "unknown"
      line = caller_info&.lineno || 0

      timestamp = datetime.strftime("%Y-%m-%d %H:%M:%S %z")
      "[#{timestamp}] #{severity} #{file}:#{line} #{method} - #{msg}\n"
    end
  end

  # Simple broadcast logger that forwards to multiple loggers
  class BroadcastLogger
    def initialize(*loggers)
      @loggers = loggers
    end

    %i[debug info warn error fatal unknown].each do |level|
      define_method(level) do |msg = nil, &block|
        @loggers.each { |logger| logger.send(level, msg, &block) }
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
