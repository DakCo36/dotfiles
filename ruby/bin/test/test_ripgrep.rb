#!/usr/bin/env ruby
require_relative '../bin_helper'
require 'mixins/loggable'
require 'components/utils/ripgrep'

if __FILE__ == $0
  ripgrep = Component::RipgrepComponent.instance

  ripgrep.install
end
