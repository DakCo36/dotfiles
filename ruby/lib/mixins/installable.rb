module Installable
  # This module defines the interface for an installable component.

  def self.included(base)
    # Ensure this module is only included in BaseComponent subclasses
    unless base < Component::BaseComponent
      raise TypeError, "Installable can only be included in classes that inherit from Component::BaseComponent"
    end
    
    base.class_eval do
      # Backup the original install method
      alias_method :install_self, :install
      
      # Define new install method that handles dependencies
      define_method :install do
        dependencies.each do |name, component_class|
          unless component_class < Component::BaseComponent
            raise TypeError, "Dependency #{name} (#{component_class}) must inherit from Component::BaseComponent"
          end
        end
        
        # 2. Filter out dependencies that are already available
        needs_to_install = dependencies.reject do |name, component_class|
          component = component_class.instance
          component.respond_to?(:available?) && component.available?
        end
        
        # 3. raise error if any dependency is not installable
        needs_to_install.each do |name, component_class|
          component = component_class.instance
          unless component.respond_to?(:install)
            raise Component::DependencyError, "Dependency #{name} is not installable and not available"
          end
        end
        
        # 4. Install dependencies
        needs_to_install.each do |name, component_class|
          logger.info("Installing dependency: #{name}")
          component_class.instance.install
        end
        
        # Call the original install method
        install_self
      end
    end
  end

  def installed?
  	raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  def install
  	raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  def rollback
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  def backup
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end
end
