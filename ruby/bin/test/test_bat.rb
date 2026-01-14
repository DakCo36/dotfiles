#!/usr/bin/env ruby
require_relative '../bin_helper'
require 'mixins/loggable'
require 'components/utils/bat'

if __FILE__ == $0
  bat = Component::BatComponent.instance

  bat.install
end
