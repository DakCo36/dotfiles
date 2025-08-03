module Installable
  # This module defines the interface for an installable component.

  def self.prepended(base)
    # Ensure this module is only prepended to BaseComponent subclasses
    unless base < Component::BaseComponent
      raise TypeError, "Installable can only be prepended to classes that inherit from Component::BaseComponent"
    end
  end
  
  def install
    # 1. Validate all dependencies inherit from BaseComponent
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
    
    # 3. Raise error if any dependency is not installable
    needs_to_install.each do |name, component_class|
      component = component_class.instance
      unless component.respond_to?(:install)
        raise Component::DependencyError, "Dependency #{name} is not installable and not available"
      end
    end
    
    # 4. Install dependencies
    needs_to_install.each do |name, component_class|
      logger.info("Installing dependency: #{name}")
      component_class.instance.install unless component_class.instance.installed?
    end
    
    # Call the original install method
    super
  end

  def installed?
  	super
  end

  def rollback
    super
  end

  def backup
    super
  end
end
