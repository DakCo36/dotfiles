require "fileutils"
require "components/base"
require "mixins/configurable"
require "mixins/installable"

module Component
  class InstallableComponent < BaseComponent

    include Configurable
    prepend Installable

    DEVKIT_ROOT = File.expand_path("../..", __dir__)
    RESOURCES_ROOT = File.join(DEVKIT_ROOT, "resources")

    # Checks if the component is installed.
    #
    # @return [Boolean] true if installed
    # @raise [NotImplementedError] if not implemented by subclass
    def installed?
      raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
    end

    # Installs the component (skips if already installed).
    #
    # @return [void]
    def install
      if installed?
        logger.info("#{display_name} already installed.")
        return
      end
      install!
    end

    # Performs installation using the template method pattern.
    # Calls: pre_install → perform_install → install_resources → post_install
    #
    # @return [void]
    def install!
      pre_install
      perform_install
      install_resources
      post_install
    end

    # Returns the latest available version.
    #
    # @return [String, nil] latest version string or nil on failure
    # @raise [NotImplementedError] if not implemented by subclass
    def latest_version
      raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
    end

    # Converts a version string to the GitHub release tag format.
    # Defaults to passthrough; subclasses may override (e.g., adding "v" prefix).
    #
    # @param ver [String] version string
    # @return [String] GitHub release tag
    def version_tag(ver)
      ver
    end

    # Checks if a newer version is available.
    #
    # @return [Boolean] true if upgradable
    def upgradable?
      return false unless installed?

      current = version
      latest = latest_version
      return false if current.nil? || latest.nil?

      current_clean = current.to_s.gsub(/^v/, "")
      latest_clean = latest.to_s.gsub(/^v/, "")

      begin
        Gem::Version.new(latest_clean) > Gem::Version.new(current_clean)
      rescue ArgumentError
        latest_clean != current_clean
      end
    end

    # Updates the component if a newer version is available.
    #
    # @return [void]
    def update
      if upgradable?
        logger.info("Updating #{self.class.name}...")
        install!
      else
        logger.info("#{self.class.name} is already up to date.")
      end
    end

    protected

    # Hook called before installation. Override for cleanup or backup.
    #
    # @return [void]
    def pre_install; end

    # Performs the core installation logic.
    #
    # @return [void]
    # @raise [NotImplementedError] if not implemented by subclass
    def perform_install
      raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
    end

    # Hook called after installation and resource setup. Override for configuration.
    #
    # @return [void]
    def post_install; end

    # Resolves component's target version with fallback logic.
    # @return [String] resolved version
    def resolve_version
      ver = latest_version
      return ver if ver

      if config.fallback_version
        logger.warn("Failed to get latest version, using fallback: #{config.fallback_version}")
        config.fallback_version
      else
        raise "Failed to resolve version for #{display_name}. Set fallback_version in config."
      end
    end

    private

    # Processes TOML-defined resources (local copy, GitHub release download).
    # @return [void]
    def install_resources
      return unless config.resources

      config.resources.each do |res|
        case res["type"]
        when "local"
          install_local_resource(res)
        when "github_release"
          install_github_release_resource(res)
        end
      end
    end

    # Copies a local resource file to its destination.
    # @param res [Hash] resource definition from TOML
    def install_local_resource(res)
      src = File.join(DEVKIT_ROOT, res["source"])
      dest = File.expand_path(res["destination"].sub("~", config.home))
      FileUtils.mkdir_p(File.dirname(dest))
      FileUtils.cp(src, dest)
      logger.info("Copied #{res["source"]} → #{config.contract_path(dest)}")
    end

    # Downloads a GitHub release asset and copies it to its destination.
    # @param res [Hash] resource definition from TOML
    def install_github_release_resource(res)
      owner = res["owner"]
      repo = res["repo"]
      asset = res["asset"]
      dest = File.expand_path(res["destination"].sub("~", config.home))
      ver = resolve_version

      url = "https://github.com/#{owner}/#{repo}/releases/download/#{version_tag(ver)}/#{asset}"
      tmp_path = File.join(config.tmp, asset)

      curl.download(url, tmp_path)
      FileUtils.mkdir_p(File.dirname(dest))
      FileUtils.cp(tmp_path, dest)
      logger.info("Downloaded #{asset} → #{config.contract_path(dest)}")
    rescue StandardError => e
      logger.warn("Failed to install resource #{asset}: #{e.message}")
    end

  end
end
