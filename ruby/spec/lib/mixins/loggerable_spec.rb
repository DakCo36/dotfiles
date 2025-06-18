require 'logger'
require 'stringio'
require 'mixins/loggable'

RSpec.describe Loggable do
  # Given
  let(:log_output) { StringIO.new }
  let(:instance) do
    klass = Class.new do
      include Loggable

      def test_info_log(msg)
        logger.info(msg)
      end
    end

    obj = klass.new
    obj.instance_variable_set(:@logger, Logger.new(log_output).tap do |log|
      log.formatter = proc do |severity, datetime, progname, msg|
        caller_info = caller_locations(4, 1)[0]
        file = caller_info.path.split('/').last
        line = caller_info.lineno
        method = caller_info.label

        "[#{datetime}] #{severity} #{file}:#{line} #{method} - #{msg}\n"
      end
    end)
    obj
  end

  it 'returns a Logger instance' do
    # When

    # Then
    expect(instance.logger).to be_a(Logger)
  end

  it 'logs message with caller location info' do
    # When
    instance.test_info_log('hello world')

    # Then
    log_output.rewind
    logged = log_output.read
    puts "logged: #{logged}"
    expect(logged).to include('INFO')
    expect(logged).to include('hello world')
    expect(logged).to match(/test_info_log - hello world/)
  end
end
