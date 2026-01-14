require 'open3'
require 'components/base'

module Component
  class TarComponent < BaseComponent
    def available?
      system('tar', '--version', out: File::NULL, err: File::NULL)
    end

    def version
      output = `tar --version 2>&1`
      output.split[2] if $?.success? # example) tar (GNU tar) 1.34
    rescue Errno::ENOENT
      nil
    end

    def installed?
      available? && version != nil
    end

    def extract(source, destination, stripComponents = 1)
      if !available?
        raise "tar is not installed"
      end

      FileUtils.mkdir_p(destination)
      runCmd('tar', '-xf', source, '-C', destination, '--strip-components', stripComponents.to_s)
    end
  end
end
