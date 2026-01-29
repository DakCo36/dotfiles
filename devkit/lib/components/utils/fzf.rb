require "singleton"
require "components/base"
require "mixins/installable"
require "components/tools/github"
require "components/tools/curl"
require "components/tools/tar"
require "mixins/loggable"

module Component
  class FzfComponent < BaseComponent

    prepend Installable

    OWNER = "junegunn"
    REPO = "fzf"

    depends_on Component::CurlComponent
    depends_on Component::GithubComponent
    depends_on Component::TarComponent

    # Checks if fzf is available.
    #
    # @return [Boolean] true if available, false otherwise
    def available?
      system("fzf", "--version", out: File::NULL, err: File::NULL)
    end

    # Returns the current fzf version.
    #
    # @return [String, nil] Version string (e.g., "0.57.0") or nil if not installed
    def version
      output, status = Open3.capture2("fzf", "--version")
      # fzf outputs "0.57.0 (fc7630a)" format
      output.split[0] if status.success?
    rescue Errno::ENOENT
      nil
    end

    # Checks if fzf is installed.
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
      logger.warn("Failed to get latest version for fzf: #{e.message}")
      nil
    end

    # Installs fzf (skips if already installed).
    #
    # @return [void]
    def install
      if installed?
        logger.info("fzf already installed.")
        return
      end
      install!
    end

    # Force installs fzf.
    #
    # @return [void]
    def install!
      tag, url = resolve_version_and_url
      logger.info("Installing version: #{tag}")
      logger.info("Downloading asset from: #{url}")
      curl.download(url, tmp_asset_path)

      # fzf tarball contains only the fzf binary at root level (no subdirectory)
      tar.extract(tmp_asset_path, tmp_dir_path, 0)
      runCmd("cp", File.join(tmp_dir_path, "fzf"), File.join(config.bin, "fzf"))

      setup_shell_integration

      logger.info("fzf installed successfully.")
    end

    private

    def resolve_version_and_url
      component_config = config.component_config("fzf") || {}
      version = component_config["version"]

      if version && version != "latest"
        # GitHub tag uses v prefix, asset filename doesn't
        tag = "v#{version}"
        asset_name = build_asset_name(version)
        url = github.build_release_asset_url(OWNER, REPO, tag, asset_name)
        return [tag, url]
      end

      tag = github.get_latest_release_tag(OWNER, REPO)
      url = github.get_latest_release_asset_download_url(OWNER, REPO, target_asset_pattern)
      [tag, url]
    rescue StandardError => e
      fallback = component_config["fallback_version"]
      raise "API failed and no fallback_version configured: #{e.message}" unless fallback

      tag = "v#{fallback}"
      asset_name = build_asset_name(fallback)
      url = github.build_release_asset_url(OWNER, REPO, tag, asset_name)
      logger.warn("API failed, using fallback version: #{tag}")
      [tag, url]
    end

    def build_asset_name(tag)
      arch = config.arch
      os = config.os

      if os.include?("darwin")
        arch_str = arch == "arm64" ? "darwin_arm64" : "darwin_amd64"
      else
        arch_str = (arch == "arm64" || arch.include?("aarch64")) ? "linux_arm64" : "linux_amd64"
      end

      "fzf-#{tag}-#{arch_str}.tar.gz"
    end

    # Returns the asset pattern for the current architecture.
    #
    # @return [String] Regex pattern for the target asset
    def target_asset_pattern
      arch = config.arch
      os = config.os

      if os.include?("darwin")
        if arch == "arm64"
          "fzf-.*-darwin_arm64\\.tar\\.gz"
        else
          "fzf-.*-darwin_amd64\\.tar\\.gz"
        end
      else
        if arch.include?("x86_64") || arch.include?("amd64")
          "fzf-.*-linux_amd64\\.tar\\.gz"
        elsif arch == "arm64" || arch.include?("aarch64")
          "fzf-.*-linux_arm64\\.tar\\.gz"
        else
          raise "Unsupported architecture: #{arch} on #{os}"
        end
      end
    end

    # @return [String]
    def tmp_asset_path
      File.join(config.tmp, "fzf-assets.tar.gz")
    end

    # @return [String]
    def tmp_dir_path
      File.join(config.tmp, "fzf-assets")
    end

    def setup_shell_integration
      # fzf 0.48.0+ supports --zsh, --bash flags for shell integration
      # Add shell integration source to .zshrc if not present
      zshrc_path = File.join(config.home, ".zshrc")

      return unless File.exist?(zshrc_path)

      zshrc_content = File.read(zshrc_path)
      fzf_integration_pattern = /source.*fzf.*zsh|fzf --zsh|eval.*fzf/

      if zshrc_content.match?(fzf_integration_pattern)
        logger.info("fzf shell integration already exists in .zshrc, skipping")
        return
      end

      logger.info("Adding fzf shell integration to .zshrc")
      # Use the new --zsh flag for fzf 0.48.0+
      integration_line = "\n# fzf shell integration\neval \"$(fzf --zsh)\"\n"

      File.open(zshrc_path, "a") do |file|
        file.write(integration_line)
      end
    end

  end
end
