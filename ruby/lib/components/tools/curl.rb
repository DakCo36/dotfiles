require 'open3'
require 'components/base'

module Component
  class CurlComponent < BaseComponent
    def available?
      system('curl', '--version', out: File::NULL, err: File::NULL)
    end

    def version
      output = `curl --version 2>&1`
      output.split[1] if $?.success?
    rescue Errno::ENOENT
      nil
    end

    def download(url, destination)
      if !available?
        raise "curl is not installed"
      end

      runCmd('curl', '-L', '-o', destination, url)
    end

    def get(url)
      if !available?
        raise "curl is not installed"
      end

      runCmdWithOutput('curl', '-L', url)
    end
  end
end
