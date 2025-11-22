#!/usr/bin/env ruby
require_relative 'bin_helper'
require 'mixins/loggable'
require 'components/shell/zsh_binary'

if __FILE__ == $0
  zsh = Component::ZshBinaryComponent.instance
  zsh.install

  ohmyzsh = Component::OhMyZshComponent.instance
  ohmyzsh.install
end
