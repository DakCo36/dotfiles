#!/usr/bin/env ruby
require_relative "../bin_helper"
require "mixins/loggable"
require "components/shell/zsh_binary"

if __FILE__ == $0
  zsh = Component::ZshBinaryComponent.instance

  installed = zsh.installed?
  puts installed

  zsh.install unless installed

end
