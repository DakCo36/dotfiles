#!/usr/bin/env ruby
require_relative '../bin_helper'
require 'mixins/loggable'
require 'components/editors/neovim'

if __FILE__ == $0
  neovim = Component::NeovimComponent.instance

  neovim.install
end
