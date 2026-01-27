$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))

PROJECT_ROOT = File.expand_path("..", __dir__)
RESOURCES_ROOT = File.join(PROJECT_ROOT, "resources")

RSpec.configure do |config|
  # DEBUG: Track where File.write is called for home directory files
  config.before(:each) do
    original_file_write = File.method(:write)
    
    allow(File).to receive(:write) do |path, *args|
      home_dir = ENV["HOME"] || Dir.home
      if path.to_s.start_with?(home_dir) && !path.to_s.include?("/tmp/")
        # Print the caller location to find the source!
        puts "\n" + "="*60
        puts "⚠️  WARNING: File.write called for home directory file!"
        puts "📁 Path: #{path}"
        puts "📍 Called from:"
        caller.first(10).each { |line| puts "   #{line}" }
        puts "="*60 + "\n"
      end
      original_file_write.call(path, *args)
    end
  end
end
