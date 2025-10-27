#!/usr/bin/env ruby
require_relative '../bin_helper'
require 'mixins/loggable'
require 'components/shell/oh_my_zsh'

if __FILE__ == $0
  ohmyzsh = Component::OhMyZshComponent.instance

  ohmyzsh.install
end
