#!/usr/bin/env ruby
require_relative "../bin_helper"
require "mixins/loggable"
require "components/cli/fzf"

if __FILE__ == $0
  fzf = Component::FzfComponent.instance

  fzf.install
end
