require "singleton"
require "components/installable_component"
require "components/configuration"
require "components/tools/github"
require "components/tools/curl"
require "components/tools/tar"
require "mixins/loggable"

module Component
  class FastfetchComponent < InstallableComponent

    OWNER = "fastfetch-cli"
    REPO = "fastfetch"

    depends_on Component::CurlComponent
    depends_on Component::GithubComponent
    depends_on Component::TarComponent

    # Checks if fastfetch is available.
    #
    # @return [Boolean] true if available, false otherwise
    def available?
      system("fastfetch", "--version", out: File::NULL, err: File::NULL)
    end

    # Returns the current fastfetch version.
    #
    # @return [String, nil] Version string (e.g., "2.57.1") or nil if not installed
    def version
      output, status = Open3.capture2("fastfetch", "--version")
      output.split[1] if status.success?
    rescue Errno::ENOENT
      nil
    end

    # Checks if fastfetch is installed.
    #
    # @return [Boolean] true if installed, false otherwise
    def installed?
      available? && !version.nil?
    end

    # Returns the latest version.
    #
    # @return [String, nil] Version string or nil on failure
    def latest_version
<<<<<<< HEAD
      tag = github.get_latest_release_tag(OWNER, REPO)
=======
      tag = github.get_latest_release_tag(config.owner, config.repo)
      # 태그에서 'v' 접두사 제거 (예: 2.31.0)
>>>>>>> 0c48187 (refactor: use config.owner/repo instead of hardcoded constants)
      tag&.gsub(/^v/, "")
    rescue StandardError => e
      logger.warn("Failed to get latest version for fastfetch: #{e.message}")
      nil
    end

    # Installs fastfetch (skips if already installed).
    #
    # @return [void]
    def install
      if installed?
        logger.info("fastfetch already installed.")
        return
      end
      install!
    end

    # Force installs fastfetch.
    #
    # @return [void]
    def install!
      tag, url = resolve_version_and_url
      logger.info("Installing version: #{tag}")
      logger.info("Downloading asset from: #{url}")
      curl.download(url, tmp_asset_path)

      tar.extract(tmp_asset_path, tmp_dir_path, 1)

      runCmd("cp", File.join(extracted_bin_path, "fastfetch"), File.join(config.bin, "fastfetch"))
      runCmd("cp", File.join(extracted_bin_path, "flashfetch"), File.join(config.bin, "flashfetch"))

      setup_man_page
      setup_completions

      logger.info("fastfetch installed successfully.")
    end

    private

    def resolve_version_and_url
      component_config = config.component_config("fastfetch") || {}
      version = component_config["version"]

      if version && version != "latest"
        tag = version
        asset_name = build_asset_name
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
      asset_name = build_asset_name
      url = github.build_release_asset_url(OWNER, REPO, tag, asset_name)
      logger.warn("API failed, using fallback version: #{tag}")
      [tag, url]
    end

    def build_asset_name
      arch = config.arch
      os = config.os

      if os.include?("darwin")
        arch_str = arch == "arm64" ? "macos-aarch64" : "macos-amd64"
      else
        arch_str = (arch == "arm64" || arch.include?("aarch64")) ? "linux-aarch64" : "linux-amd64"
      end

      "fastfetch-#{arch_str}.tar.gz"
    end

    # Returns the asset pattern for the current architecture.
    #
    # @return [String] Regex pattern for the target asset
    def target_asset_pattern
      arch = config.arch
      os = config.os

      if os.include?("darwin")
        if arch == "arm64"
          "fastfetch-macos-aarch64\\.tar\\.gz"
        else
          "fastfetch-macos-amd64\\.tar\\.gz"
        end
      else
        if arch.include?("x86_64") || arch.include?("amd64")
          "fastfetch-linux-amd64\\.tar\\.gz$"
        elsif arch == "arm64" || arch.include?("aarch64")
          "fastfetch-linux-aarch64\\.tar\\.gz$"
        else
          raise "Unsupported architecture: #{arch} on #{os}"
        end
      end
    end

    # @return [String]
    def tmp_asset_path
      File.join(config.tmp, "fastfetch-assets.tar.gz")
    end

    # @return [String]
    def tmp_dir_path
      File.join(config.tmp, "fastfetch-assets")
    end

    # @return [String]
    def extracted_bin_path
      File.join(tmp_dir_path, "usr", "bin")
    end

    # @return [String]
    def extracted_man_path
      File.join(tmp_dir_path, "usr", "share", "man", "man1")
    end

    # @return [String]
    def extracted_bash_completion_path
      File.join(tmp_dir_path, "usr", "share", "bash-completion", "completions")
    end

    # @return [String]
    def extracted_zsh_completion_path
      File.join(tmp_dir_path, "usr", "share", "zsh", "site-functions")
    end

    def setup_man_page
      FileUtils.mkdir_p(config.man1)
      runCmd("cp", File.join(extracted_man_path, "fastfetch.1"), File.join(config.man1, "fastfetch.1"))
    end

    def setup_completions
      # zsh completions
      FileUtils.mkdir_p(config.zsh_completions)
      runCmd("cp", File.join(extracted_zsh_completion_path, "_fastfetch"),
             File.join(config.zsh_completions, "_fastfetch"))

      # bash completions
      FileUtils.mkdir_p(config.bash_completions)
      runCmd("cp", File.join(extracted_bash_completion_path, "fastfetch"),
             File.join(config.bash_completions, "fastfetch"))
    end

  end
end
