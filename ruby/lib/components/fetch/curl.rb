require 'open3'
require_relative '../base'
require_relative '../../mixins/loggable'

module Component
  class CurlComponent < BaseComponent
    include Loggable
    def exists?
      system('curl', '--version', out: File::NULL, err: File::NULL)
    end

    def version
      output = `curl --version 2>&1`
      output.split[1] if $?.success?
    rescue Errno::ENOENT
      nil
    end

    def download(url, destination)
      if !exists?
        raise "curl is not installed"
      end

      out, err, status = Open3.capture3('curl', '-L', '-o', destination, url)
      if status.success?
        logger.info("Successfully, download from #{url} to #{destination}")
      else
        logger.error("Failed to download #{url} to #{destination}")
        logger.error("Stdout: ${out}")
        logger.error("Stderr: ${err}")
        raise "Download failed"
      end
    end
  end
end
