#!/usr/bin/env ruby
require_relative '../bin_helper'
require 'components/fetch/git'
require 'fileutils'

if __FILE__ == $0
  git = Component::GitComponent.instance

  if git.available?
    puts "Git is installed. Version: #{git.version}"
  else
    puts "Git is not installed."
  end

  url = 'https://github.com/dakco36/dotfiles.git'
  destination = '/tmp/dotfiles'
  FileUtils.rm_rf(destination) if File.exist?(destination)
  git.clone(url, destination)
end
