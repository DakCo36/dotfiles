#!/usr/bin/env ruby

require_relative "bin_helper"
require "optparse"
require "mixins/loggable"

require "commands/install_command"
require "commands/update_command"
require "commands/help_command"

module CLI
  class Runner

    include Loggable

    def initialize
      @auto_yes = false
      @dry_run = false
      @force = false
    end

    def run(args)
      parse_options!(args)

      command = args.shift || "help"

      case command
      when "install"
        Commands::InstallCommand.new(
          auto_yes: @auto_yes, dry_run: @dry_run, force: @force
        ).execute(args)
      when "update"
        Commands::UpdateCommand.new(
          auto_yes: @auto_yes, dry_run: @dry_run
        ).execute(args)
      when "help", "-h", "--help"
        Commands::HelpCommand.new.execute
      else
        logger.error("알 수 없는 명령어: #{command}")
        Commands::HelpCommand.new.execute
        exit 1
      end
    end

    private

    def parse_options!(args)
      parser = OptionParser.new do |opts|
        opts.on("-y", "--yes") { @auto_yes = true }
        opts.on("-n", "--dry-run") { @dry_run = true }
        opts.on("-f", "--force") { @force = true }
        opts.on("-h", "--help") { args.unshift("help") }
      end
      parser.parse!(args)
    rescue OptionParser::InvalidOption => e
      logger.error("오류: #{e.message}")
      Commands::HelpCommand.new.execute
      exit 1
    end

  end
end

CLI::Runner.new.run(ARGV) if __FILE__ == $0