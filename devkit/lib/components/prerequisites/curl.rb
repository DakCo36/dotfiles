require "open3"
require "components/required_component"

module Component
  class CurlComponent < RequiredComponent

    def available?
      system("curl", "--version", out: File::NULL, err: File::NULL)
    end

    def version
      output = `curl --version 2>&1`
      output.split[1] if $?.success?
    rescue Errno::ENOENT
      nil
    end

    def download(url, destination)
      raise "curl is not installed" unless available?

      runCmd("curl", "-L", "-o", destination, url)
    end

    def get(url)
      raise "curl is not installed" unless available?

      runCmdWithOutput("curl", "-L", url)
    end

  end
end
