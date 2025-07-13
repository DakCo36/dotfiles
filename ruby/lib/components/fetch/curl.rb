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

      runCmd('curl', '-L', '-o', destination, url)
    end
  end
end
