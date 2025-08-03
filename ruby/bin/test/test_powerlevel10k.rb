#!/usr/bin/env ruby
require_relative '../bin_helper'
require 'mixins/loggable'
require 'components/shell/powerlevel10k'

if __FILE__ == $0
  powerlevel10k = Component::Powerlevel10kComponent.instance

  powerlevel10k.install!
end
