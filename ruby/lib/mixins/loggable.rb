require "logger"

module Loggable
  attr_reader :logger

  def self.setup(verbose: false)
    @verbose = verbose
  end

  def self.verbose?
    @verbose
  end

  def logger
    @logger ||= Logger.new($stdout).tap do |log|
      log.level = Loggable.verbose? ? Logger::DEBUG : Logger::INFO
      
      log.formatter = proc do |severity, datetime, _progname, msg|
        caller_info = caller_locations(4, 1)&.first
        file = caller_info&.path&.split("/")&.last || "unknown"
        method = caller_info&.label || "unknown"
        line = caller_info&.lineno || 0

        if Loggable.verbose?
          # Verbose Mode: [2026-01-20 23:37:36 +0000] INFO cli.rb:141 block in CLI::Runner#show_install_plan - ...
          timestamp = datetime.strftime("%Y-%m-%d %H:%M:%S %z")
          "[#{timestamp}] #{severity} #{file}:#{line} #{method} - #{msg}\n"
        else
          # Compact Mode: 12:31:59 [I] cli.rb install - message
          time = datetime.strftime("%H:%M:%S")
          level_char = severity[0]
          "#{time} [#{level_char}] #{file} #{method} - #{msg}\n"
        end
      end
    end
  end
end
