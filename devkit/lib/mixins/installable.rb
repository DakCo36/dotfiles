module Installable
  # This module defines the interface for an installable component.

  def self.prepended(base)
    # Ensure this module is only prepended to BaseComponent subclasses
    return if base < Component::BaseComponent

    raise TypeError, "Installable can only be prepended to classes that inherit from Component::BaseComponent"
  end

  def install
    dependencies.each do |name, component_class|
      unless component_class < Component::BaseComponent
        raise TypeError, "Dependency #{name} (#{component_class}) must inherit from Component::BaseComponent"
      end
    end

    installable_deps = dependencies.reject do |_name, component_class|
      component_class < Component::RequiredComponent
    end

    needs_to_install = installable_deps.reject do |_name, component_class|
      component_class.instance.installed?
    end

    needs_to_install.each do |name, component_class|
      component = component_class.instance
      unless component.respond_to?(:install)
        raise Component::DependencyError, "Dependency #{name} is not installable and not available"
      end
    end

    needs_to_install.each do |name, component_class|
      logger.info("Installing dependency: #{name}")
      component_class.instance.install
    end

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
