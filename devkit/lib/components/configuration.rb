require "singleton"
require "tmpdir"
require "toml-rb"
require "rbconfig"

module Components
  class Configuration

    include Singleton

    # Immutable configuration data for each component
    # All fields are optional with sensible defaults
    # Includes both component-specific settings and global paths
    ComponentConfig = Data.define(
      # Component-specific settings (from TOML)
      :enabled,
      :source,
      :version,
      :owner,
      :repo,
      :branch,
      :resources,
      :fallback_version,
      # Global settings (always available)
      :arch,
      :os,
      :home,
      :local,
      :bin,
      :tmp,
      :bashrc,
      :bash_profile,
      :bash_completions,
      :zshrc,
      :zprofile,
      :zsh_completions,
      :man1
    ) do
      def initialize(
        enabled: true,
        source:,
        version:,
        owner: nil,
        repo: nil,
        branch: nil,
        resources: nil,
        fallback_version: nil,
        arch: nil,
        os: nil,
        home: nil,
        local: nil,
        bin: nil,
        tmp: nil,
        bashrc: nil,
        bash_profile: nil,
        bash_completions: nil,
        zshrc: nil,
        zprofile: nil,
        zsh_completions: nil,
        man1: nil
      )
        super
      end

      # Contracts absolute path to use $HOME
      def contract_path(path)
        if path.is_a?(String) && path.start_with?(home)
          path.sub(home, "$HOME")
        else
          path
        end
      end
    end

    attr_accessor :home, :local, :bin, :tmp, :bashrc, :bash_profile, :bash_completions, :zshrc, :zprofile,
                  :zsh_completions, :man1
    attr_reader :arch, :os

    def initialize
      @arch = RbConfig::CONFIG["host_cpu"]
      @os = RbConfig::CONFIG["host_os"]
      @home = Dir.home
      @local = Dir.home + "/.local"
      @bin = local + "/bin"
      @tmp = Dir.tmpdir + "/" + generateTimestamp
      @bashrc = File.join(home, ".bashrc")
      @bash_profile = File.join(home, ".bash_profile")
      @bash_completions = File.join(home, ".local", "share", "bash-completion", "completions")
      @zshrc = File.join(home, ".zshrc")
      @zprofile = File.join(home, ".zprofile")
      @zsh_completions = File.join(home, ".local", "share", "zsh", "site-functions")
      @man1 = File.join(home, ".local", "share", "man", "man1")

      FileUtils.mkdir_p(@tmp) unless Dir.exist?(@tmp)
    end

    # Returns the entire manifest (TOML configuration), cached after first load
    def manifest
      @manifest ||= load_manifest
    end

    # Returns the configuration for a specific component by name
    # @param name [String, Symbol] component name (e.g., "fzf", "neovim")
    # @return [ComponentConfig] component configuration data object with global paths included
    def component_config(name)
      data = manifest[name.to_s] || {}
      return ComponentConfig.new(enabled: false, source: "none", version: "none", **global_paths) if data.empty?

      ComponentConfig.new(**data.transform_keys(&:to_sym), **global_paths)
    end

    private

    def global_paths
      {
        arch: @arch,
        os: @os,
        home: @home,
        local: @local,
        bin: @bin,
        tmp: @tmp,
        bashrc: @bashrc,
        bash_profile: @bash_profile,
        bash_completions: @bash_completions,
        zshrc: @zshrc,
        zprofile: @zprofile,
        zsh_completions: @zsh_completions,
        man1: @man1
      }
    end

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
