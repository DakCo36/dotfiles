#!/usr/bin/env ruby
require_relative 'bin_helper'
require 'mixins/loggable'
require 'components/shell/zsh_binary'
require 'components/shell/oh_my_zsh'
require 'components/shell/powerlevel10k'
require 'components/shell/zgenom'
require 'components/utils/bat'
require 'components/utils/fastfetch'
require 'components/utils/fd'
require 'components/utils/ripgrep'
require 'components/utils/fzf'

if __FILE__ == $0
  zsh = Component::ZshBinaryComponent.instance
  zsh.install

  ohmyzsh = Component::OhMyZshComponent.instance
  ohmyzsh.install

  powerlevel10k = Component::Powerlevel10kComponent.instance
  powerlevel10k.install

  zgenom = Component::ZgenomComponent.instance
  zgenom.install

  bat = Component::BatComponent.instance
  bat.install

  fastfetch = Component::FastfetchComponent.instance
  fastfetch.install

  fd = Component::FdComponent.instance
  fd.install

  ripgrep = Component::RipgrepComponent.instance
  ripgrep.install

  fzf = Component::FzfComponent.instance
  fzf.install
end
