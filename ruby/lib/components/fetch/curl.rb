require_relative 'base'

module Component
  class CurlComponent < BaseComponent
    def exists?
      system('curl', '--version', out: File::NULL, err: File::NULL)
    end

    def version
      output = `curl --version 2>&1`
      output.split[1] if $?.success?
    rescue Errno::ENOENT
      nil
    end
  end
end
