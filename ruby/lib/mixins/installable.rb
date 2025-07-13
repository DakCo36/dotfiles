module Installable
  # This module defines the interface for an installable component.

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
