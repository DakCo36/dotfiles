require "singleton"
require "components/installable_component"
require "components/configuration"
require "components/tools/github"
require "components/tools/curl"
require "components/tools/tar"
require "mixins/loggable"

module Component
  class BatComponent < InstallableComponent

    OWNER = "sharkdp"
    REPO = "bat"

    depends_on Component::CurlComponent
    depends_on Component::GithubComponent
    depends_on Component::TarComponent

    # Checks if bat is available.
    #
    # @return [Boolean] true if available, false otherwise
    def available?
      system("bat", "--version", out: File::NULL, err: File::NULL)
    end

    # Returns the current bat version.
    #
    # @return [String, nil] Version string (e.g., "0.21.0") or nil if not installed
    def version
      output, status = Open3.capture2("bat", "--version")
      output.split[1] if status.success? # example) bat 0.21.0 (405edf)
    rescue Errno::ENOENT
      nil
    end

    # Checks if bat is installed.
    #
    # @return [Boolean] true if installed, false otherwise
    def installed?
      available? && !version.nil?
    end

    # Returns the latest version.
    #
    # @return [String, nil] Version string or nil on failure
    def latest_version
      tag = github.get_latest_release_tag(config.owner, config.repo)
      tag&.gsub(/^v/, "")
    rescue StandardError => e
      logger.warn("Failed to get latest version for bat: #{e.message}")
      nil
    end

    # Installs bat (skips if already installed).
    #
    # @return [void]
    def install
      if installed?
        logger.info("bat already installed.")
        return
      end
      install!
    end

    # Force installs bat.
    #
    # @return [void]
    def install!
      tag, url = resolve_version_and_url
      logger.info("Installing version: #{tag}")
      logger.info("Downloading asset from: #{url}")
      curl.download(url, tmp_asset_path)

      tar.extract(tmp_asset_path, tmp_dir_path, 1)
      runCmd("cp", File.join(tmp_dir_path, "bat"), File.join(config.bin, "bat"))

      setup_man_page
      setup_completions

      logger.info("Bat installed successfully.")
    end

    private

    # Resolves version and download URL with fallback support.
    #
    # @return [Array<String, String>] [tag, url]
    def resolve_version_and_url
      component_config = config.component_config("bat") || {}
      version = component_config["version"]

      # If specific version configured, use it directly (no API call)
      if version && version != "latest"
        tag = "v#{version}"
        asset_name = build_asset_name(tag)
        url = github.build_release_asset_url(OWNER, REPO, tag, asset_name)
        return [tag, url]
      end

      # version = "latest" - try API
      tag = github.get_latest_release_tag(OWNER, REPO)
      url = github.get_latest_release_asset_download_url(OWNER, REPO, target_asset_pattern)
      [tag, url]
    rescue StandardError => e
      # API failed - use fallback version
      fallback = component_config["fallback_version"]
      raise "API failed and no fallback_version configured: #{e.message}" unless fallback

      tag = "v#{fallback}"
      asset_name = build_asset_name(tag)
      url = github.build_release_asset_url(OWNER, REPO, tag, asset_name)
      logger.warn("API failed, using fallback version: #{tag}")
      [tag, url]
    end

    # Builds asset filename for a given version tag.
    #
    # @param tag [String] Version tag (e.g., "v0.24.0")
    # @return [String] Asset filename
    def build_asset_name(tag)
      arch = config.arch
      os = config.os

      if os.include?("darwin")
        arch_str = arch == "arm64" ? "aarch64-apple-darwin" : "x86_64-apple-darwin"
      else
        if arch.include?("x86_64") || arch.include?("amd64")
          arch_str = "x86_64-unknown-linux-musl"
        elsif arch == "arm64" || arch.include?("aarch64")
          arch_str = "aarch64-unknown-linux-gnu"
        else
          raise "Unsupported architecture: #{arch} on #{os}"
        end
      end

      "bat-#{tag}-#{arch_str}.tar.gz"
    end

    # Returns the asset pattern for the current architecture.
    #
    # @return [String] Regex pattern for the target asset
    def target_asset_pattern
      arch = config.arch
      os = config.os

      if os.include?("darwin")
        # macOS - bat provides universal binary
        if arch == "arm64"
          "bat-.*-aarch64-apple-darwin\\.tar\\.gz"
        else
          "bat-.*-x86_64-apple-darwin\\.tar\.gz"
        end
      else
        # Linux
        if arch.include?("x86_64") || arch.include?("amd64")
          "bat-.*-x86_64-unknown-linux-musl\\.tar\\.gz"
        elsif arch == "arm64" || arch.include?("aarch64")
          "bat-.*-aarch64-unknown-linux-musl\\.tar\\.gz"
        else
          raise "Unsupported architecture: #{arch} on #{os}"
        end
      end
    end

    # @return [String]
    def tmp_asset_path
      File.join(config.tmp, "bat-assets.tar.gz")
    end

    # @return [String]
    def tmp_dir_path
      File.join(config.tmp, "bat-assets")
    end

    def setup_man_page
      FileUtils.mkdir_p(config.man1)
      runCmd("cp", File.join(tmp_dir_path, "bat.1"), File.join(config.man1, "bat.1"))
    end

    def setup_completions
      FileUtils.mkdir_p(config.zsh_completions)
      runCmd("cp", File.join(tmp_dir_path, "autocomplete", "bat.zsh"), File.join(config.zsh_completions, "_bat"))

      FileUtils.mkdir_p(config.bash_completions)
      runCmd("cp", File.join(tmp_dir_path, "autocomplete", "bat.bash"), File.join(config.bash_completions, "bat"))
    end

  end
end
