require "logger"

module Loggable
  # ANSI color codes for log levels
  COLORS = {
    "TRACE" => "\e[90m",  # 회색 (Gray)
    "DEBUG" => "\e[34m",  # 파랑 (Blue)
    "INFO"  => "\e[32m",  # 녹색 (Green)
    "WARN"  => "\e[33m",  # 노랑 (Yellow)
    "ERROR" => "\e[31m",  # 빨강 (Red)
  }.freeze
  CYAN = "\e[36m"     # 청록색 - 파일명용
  MAGENTA = "\e[35m"  # 자주색 - 메서드명용
  RESET = "\e[0m"

  attr_reader :logger

  def self.setup(verbose: false)
    @verbose = verbose
  end

  def self.verbose?
    @verbose
  end

  def self.colorize(severity, text)
    color = COLORS[severity] || ""
    "#{color}#{text}#{RESET}"
  end

  def logger
    @logger ||= Logger.new($stdout).tap do |log|
      log.level = Loggable.verbose? ? Logger::DEBUG : Logger::INFO
      
      log.formatter = proc do |severity, datetime, _progname, msg|
        caller_info = caller_locations(4, 1)&.first
        file = caller_info&.path&.split("/")&.last || "unknown"
        method = caller_info&.label || "unknown"
        line = caller_info&.lineno || 0
        level_color = Loggable::COLORS[severity] || ""

        if Loggable.verbose?
          # Verbose Mode: [2026-01-20 23:37:36 +0000] INFO cli.rb:141 method - ...
          timestamp = datetime.strftime("%Y-%m-%d %H:%M:%S %z")
          "#{level_color}[#{timestamp}] #{severity}#{RESET} #{CYAN}#{file}:#{line}#{RESET} #{MAGENTA}#{method}#{RESET} - #{msg}\n"
        else
          # Compact Mode: 12:31:59 [I] cli.rb:141 method - message
          time = datetime.strftime("%H:%M:%S")
          level_char = severity[0]
          func_name = method.to_s.split("#").last || method
          "#{level_color}#{time} [#{level_char}]#{RESET} #{CYAN}#{file}:#{line}#{RESET} #{MAGENTA}#{func_name}#{RESET} - #{msg}\n"
        end
      end
    end
  end
end
