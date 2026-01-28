require "singleton"
require "tmpdir"
require "toml-rb"

module Components
  class Configuration

    include Singleton

    attr_accessor :home, :local, :bin, :tmp, :bashrc, :bash_profile, :bash_completions, :zshrc, :zsh_profile,
                  :zsh_completions, :man1

    def initialize
      @home = Dir.home
      @local = Dir.home + "/.local"
      @bin = local + "/bin"
      @tmp = Dir.tmpdir + "/" + generateTimestamp
      @bashrc = File.join(home, ".bashrc")
      @bash_profile = File.join(home, ".bash_profile")
      @bash_completions = File.join(home, ".local", "share", "bash-completion", "completions")
      @zshrc = File.join(home, ".zshrc")
      @zsh_profile = File.join(home, ".zsh_profile")
      @zsh_completions = File.join(home, ".local", "share", "zsh", "site-functions")
      @man1 = File.join(home, ".local", "share", "man", "man1")

      FileUtils.mkdir_p(@tmp) unless Dir.exist?(@tmp)
    end

    def contract_path(path)
      if path.is_a?(String) && path.start_with?(@home)
        path.sub(@home, "$HOME")
      else
        path
      end
    end

    # Returns the entire manifest (TOML configuration), cached after first load
    def manifest
      @manifest ||= load_manifest
    end

    # Returns the configuration for a specific component by name
    # @param name [String, Symbol] component name (e.g., "fzf", "neovim")
    # @return [Hash] component configuration or empty hash if not found
    def component_config(name)
      manifest[name.to_s] || {}
    end

    private

    def generateTimestamp
      Time.now.strftime("%Y%m%d_%H%M%S")
    end

    def load_manifest
      config_path = File.join(File.dirname(__FILE__), "..", "..", "config", "devkit.toml")

      unless File.exist?(config_path)
        raise "Manifest file not found: #{config_path}. This file is required."
      end

      TomlRB.load_file(config_path)
    rescue TomlRB::ParseError => e
      raise "Failed to parse manifest: #{e.message}"
    end

  end
end
