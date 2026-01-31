require "singleton"
require "components/installable_component"
require "components/configuration"
require "components/tools/github"
require "components/tools/curl"
require "components/tools/tar"
require "mixins/loggable"

module Component
  class RipgrepComponent < InstallableComponent

    OWNER = "BurntSushi"
    REPO = "ripgrep"

    depends_on Component::CurlComponent
    depends_on Component::GithubComponent
    depends_on Component::TarComponent

    # Checks if ripgrep is available.
    #
    # @return [Boolean] true if available, false otherwise
    def available?
      system("rg", "--version", out: File::NULL, err: File::NULL)
    end

    # Returns the current ripgrep version.
    #
    # @return [String, nil] Version string (e.g., "14.1.0") or nil if not installed
    def version
      output, status = Open3.capture2("rg", "--version")
      # ripgrep outputs "ripgrep 14.1.0" format
      output.split[1] if status.success?
    rescue Errno::ENOENT
      nil
    end

    # Checks if ripgrep is installed.
    #
    # @return [Boolean] true if installed, false otherwise
    def installed?
      available? && !version.nil?
    end

    # Returns the latest version.
    #
    # @return [String, nil] Version string or nil on failure
    def latest_version
      tag = github.get_latest_release_tag(OWNER, REPO)
      tag&.gsub(/^v/, "")
    rescue StandardError => e
      logger.warn("Failed to get latest version for ripgrep: #{e.message}")
      nil
    end

    # Installs ripgrep (skips if already installed).
    #
    # @return [void]
    def install
      if installed?
        logger.info("ripgrep already installed.")
        return
      end
      install!
    end

    # Force installs ripgrep.
    #
    # @return [void]
    def install!
      tag, url = resolve_version_and_url
      logger.info("Installing version: #{tag}")
      logger.info("Downloading asset from: #{url}")
      curl.download(url, tmp_asset_path)

      tar.extract(tmp_asset_path, tmp_dir_path, 1)
      runCmd("cp", File.join(tmp_dir_path, "rg"), File.join(config.bin, "rg"))

      setup_man_page
      setup_completions

      logger.info("ripgrep installed successfully.")
    end

    private

    def resolve_version_and_url
      component_config = config.component_config("ripgrep") || {}
      version = component_config["version"]

      if version && version != "latest"
        tag = version  # ripgrep uses plain version without 'v' prefix
        asset_name = build_asset_name(tag)
        url = github.build_release_asset_url(OWNER, REPO, tag, asset_name)
        return [tag, url]
      end

      tag = github.get_latest_release_tag(OWNER, REPO)
      url = github.get_latest_release_asset_download_url(OWNER, REPO, target_asset_pattern)
      [tag, url]
    rescue StandardError => e
      fallback = component_config["fallback_version"]
      raise "API failed and no fallback_version configured: #{e.message}" unless fallback

      tag = fallback
      asset_name = build_asset_name(tag)
      url = github.build_release_asset_url(OWNER, REPO, tag, asset_name)
      logger.warn("API failed, using fallback version: #{tag}")
      [tag, url]
    end

    def build_asset_name(tag)
      arch = config.arch
      os = config.os

      if os.include?("darwin")
        arch_str = arch == "arm64" ? "aarch64-apple-darwin" : "x86_64-apple-darwin"
      else
        # Linux: x86_64 uses musl, arm64 uses gnu
        if arch.include?("x86_64") || arch.include?("amd64")
          arch_str = "x86_64-unknown-linux-musl"
        elsif arch == "arm64" || arch.include?("aarch64")
          arch_str = "aarch64-unknown-linux-gnu"
        else
          raise "Unsupported architecture: #{arch} on #{os}"
        end
      end

      "ripgrep-#{tag}-#{arch_str}.tar.gz"
    end

    # Returns the asset pattern for the current architecture.
    #
    # @return [String] Regex pattern for the target asset
    def target_asset_pattern
      arch = config.arch
      os = config.os

      if os.include?("darwin")
        if arch == "arm64"
          "ripgrep-.*-aarch64-apple-darwin\\.tar\\.gz"
        else
          "ripgrep-.*-x86_64-apple-darwin\\.tar\\.gz"
        end
      else
        # Linux: x86_64 uses musl, arm64 uses gnu (no musl available for arm64)
        if arch.include?("x86_64") || arch.include?("amd64")
          "ripgrep-.*-x86_64-unknown-linux-musl\\.tar\\.gz"
        elsif arch == "arm64" || arch.include?("aarch64")
          "ripgrep-.*-aarch64-unknown-linux-gnu\\.tar\\.gz"
        else
          raise "Unsupported architecture: #{arch} on #{os}"
        end
      end
    end

    # @return [String]
    def tmp_asset_path
      File.join(config.tmp, "ripgrep-assets.tar.gz")
    end

    # @return [String]
    def tmp_dir_path
      File.join(config.tmp, "ripgrep-assets")
    end

    def setup_man_page
      FileUtils.mkdir_p(config.man1)
      runCmd("cp", File.join(tmp_dir_path, "doc", "rg.1"), File.join(config.man1, "rg.1"))
    end

    def setup_completions
      # zsh completions
      FileUtils.mkdir_p(config.zsh_completions)
      runCmd("cp", File.join(tmp_dir_path, "complete", "_rg"), File.join(config.zsh_completions, "_rg"))

      # bash completions
      FileUtils.mkdir_p(config.bash_completions)
      runCmd("cp", File.join(tmp_dir_path, "complete", "rg.bash"), File.join(config.bash_completions, "rg"))
    end

  end
end
