$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))

PROJECT_ROOT = File.expand_path("..", __dir__)
RESOURCES_ROOT = File.join(PROJECT_ROOT, "resources")

RSpec.configure do |config|
  # Home directory protection - prevents unmocked file writes during tests
  config.before(:each) do
    home_dir = ENV["HOME"] || Dir.home

    original_file_write = File.method(:write)
    allow(File).to receive(:write) do |path, *args|
      if path.to_s.start_with?(home_dir) && !path.to_s.include?("/tmp/")
        raise <<~ERROR
          
          ❌ PROTECTION ERROR: File.write attempted on home directory!
          📁 Path: #{path}
          
          You must mock File.write in your test:
            allow(File).to receive(:write).and_return(nil)
          
        ERROR
      else
        original_file_write.call(path, *args)
      end
    end

    original_rm_rf = FileUtils.method(:rm_rf)
    allow(FileUtils).to receive(:rm_rf) do |path, *args|
      if path.to_s.start_with?(home_dir) && !path.to_s.include?("/tmp/")
        raise <<~ERROR
          
          ❌ PROTECTION ERROR: FileUtils.rm_rf attempted on home directory!
          📁 Path: #{path}
          
          You must mock FileUtils.rm_rf in your test:
            allow(FileUtils).to receive(:rm_rf).and_return(nil)
          
        ERROR
      else
        original_rm_rf.call(path, *args)
      end
    end
  end
end
