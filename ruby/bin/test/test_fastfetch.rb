#!/usr/bin/env ruby
require_relative '../bin_helper'
require 'mixins/loggable'
require 'components/utils/fastfetch'

if __FILE__ == $0
  fastfetch = Component::FastfetchComponent.instance

  fastfetch.install
end
