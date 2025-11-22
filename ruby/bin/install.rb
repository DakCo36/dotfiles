#!/usr/bin/env ruby
require_relative 'bin_helper'
require 'mixins/loggable'
require 'components/shell/zsh_binary'
require 'components/shell/oh_my_zsh'
require 'components/shell/powerlevel10k'

if __FILE__ == $0
  zsh = Component::ZshBinaryComponent.instance
  zsh.install

  ohmyzsh = Component::OhMyZshComponent.instance
  ohmyzsh.install

  powerlevel10k = Component::Powerlevel10kComponent.instance
  powerlevel10k.install
end
