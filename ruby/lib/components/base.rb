module Component
  # This module defined the interface for an component.
  class BaseComponent
    def exists?
      raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
    end

    def version
      raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
    end

    private
    def runCmd(command, *args, showStdout: false)
      logger.info('Command: ' + command + ' ' + args.join(' '))
      out, err, status = Open3.capture3(command, *args)
      unless status.success?
        logger.warn("Command failed: #{command} #{args.join(' ')}")
        logger.warn("Exit status: #{status.exitstatus}")
        logger.warn("Stdout: #{out}") unless out.empty?
        logger.warn("Stderr: #{err}") unless err.empty?
        raise "Command `#{command}` failed"
      end

      if (showStdout)
        logger.info("Stdout: #{out}") unless out.empty?
      end

      [out, err, status]
    end

    def runCmdWithOutput(command, *args, showStdout: false)
      out, err, status = runCmd(command, *args, showStdout: false)
      out
    end

    def withDir(dir)
      logger.debug('Changing from ' + Dir.pwd + ' to ' + dir)
      Dir.chdir(dir) do
        yield
      end
    rescue Errno::ENOENT => e
      logger.error("Directory not found: #{dir}")
      raise e
    end
  end
end
