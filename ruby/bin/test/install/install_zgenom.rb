#!/usr/bin/env ruby
require_relative '../bin_helper'
require 'mixins/loggable'
require 'components/shell/zgenom'

if __FILE__ == $0
  zgenom = Component::ZgenomComponent.instance

  zgenom.install
end
