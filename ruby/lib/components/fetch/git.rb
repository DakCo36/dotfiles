require 'open3'
require 'components/base'

module Component
  class GitComponent < BaseComponent

    def available?
      system('git', '--version', out: File::NULL, err: File::NULL)
    end

    def version
      output = `git --version 2>&1`
      output.split[2] if $?.success?
    rescue Errno::ENOENT
      nil
    end

    def clone(url, destination)
      if !available?
        raise "git is not installed"
      end

      runCmd('git', 'clone', '--depth', '1', url, destination)
    end
  end
end
