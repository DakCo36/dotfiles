require 'singleton'
require_relative '../mixins/loggable'

module Component
  class DependencyError < StandardError; end

  # This module defined the interface for an component.
  class BaseComponent
    include Loggable
    
    def self.inherited(subclass)
      super
      subclass.include Singleton # Make new method available
    end
    
    def available?
      raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
    end

    def version
      raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
    end
    
    def self.dependencies(&block)
      @dependencies ||= {}
      instance_eval(&block) if block_given?
      @dependencies
    end
    
    def self.depends_on(component_class, name: nil)
      # Create name from class name if not provided
      if name.nil?
        class_name = component_class.name.split('::').last  # Component::GitComponent → GitComponent
        name = class_name
          .gsub(/Component$/, '')  # GitComponent → Git
          .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')  # ABCDef → ABC_Def
          .gsub(/([a-z\d])([A-Z])/, '\1_\2')  # abcDef → abc_Def
          .downcase  # Git → git, OhMyZsh → oh_my_zsh
          .to_sym
      end
      
      dependencies[name] = component_class
      
      # Define a method to access the component instance
      # If name is curl, then create 'curl' method (getter)
      define_method(name) do
        instance_variable_name = "@#{name}"
        instance_variable_get(instance_variable_name) ||
          instance_variable_set(instance_variable_name, component_class.instance)
      end
    end
    
    def dependencies
      self.class.dependencies
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
