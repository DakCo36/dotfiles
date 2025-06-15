module Components
  # This module defined the interface for an component.

  class BaseComponent
    def exists?
      raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
    end
  end
end
