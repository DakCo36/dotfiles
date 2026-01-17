#!/usr/bin/env ruby
require_relative '../bin_helper'
require 'mixins/loggable'
require 'components/utils/fd'

if __FILE__ == $0
  fd = Component::FdComponent.instance

  fd.install
end
