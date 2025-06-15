require 'logger'

module Loggable
  attr_reader :logger
  def logger
    @logger ||= Logger.new(STDOUT).tap do |log|
      log.formatter = proc do |severity, datetime, progname, msg|
        caller_info = caller_locations(4, 1)[0]
        file = caller_info.path.split('/').last
        line = caller_info.lineno
        method = caller_info.label

        "[#{datetime}] #{severity} #{file}:#{line} #{method} - #{msg}\n"
      end # end of proc
    end # end of tap
  end
end
