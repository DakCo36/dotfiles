#!/usr/bin/env ruby
require_relative '../bin_helper'
require 'mixins/loggable'
require 'components/shell/zsh'

if __FILE__ == $0
  zsh = Component::ZshComponent.new

  installed = zsh.installed?
  puts installed

  if !installed
    zsh.install
  end

end
