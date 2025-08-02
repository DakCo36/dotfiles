#!/usr/bin/env ruby
require_relative '../bin_helper'
require 'components/fetch/git'

if __FILE__ == $0
  git = Component::GitComponent.new

  if git.exists?
    puts "Git is installed. Version: #{git.version}"
  else
    puts "Git is not installed."
  end

  url = 'https://github.com/dakco36/dotfiles.git'
  destination = '/tmp/dotfiles'
  
  git.clone(url, destination)
end
