require "singleton"
require "components/installable_component"
require "components/configuration"
require "components/prerequisites/github"
require "components/prerequisites/curl"
require "components/prerequisites/tar"
require "mixins/loggable"

module Component
  class RipgrepComponent < InstallableComponent

    depends_on Component::ZshBinaryComponent
    depends_on Component::CurlComponent
    depends_on Component::GithubComponent
    depends_on Component::TarComponent

    # Returns the current ripgrep version.
    #
    # @return [String, nil] version string (e.g., "14.1.0") or nil
    def version
      output, status = Open3.capture2("rg", "--version")
      output.split[1] if status.success?
    rescue Errno::ENOENT
      nil
    end

    # Checks if ripgrep is installed.
    #
    # @return [Boolean]
    def installed?
      !version.nil?
    end

    # Returns the latest available version from GitHub.
    #
    # @return [String, nil] version string or nil
    def latest_version
      tag = github.get_latest_release_tag(config.owner, config.repo)
      tag&.gsub(/^v/, "")
    rescue StandardError => e
      logger.warn("Failed to get latest version for ripgrep: #{e.message}")
      nil
    end


    # ripgrep does not use v prefix for tags (e.g., 14.1.0)
    #
    # @param ver [String] version string
    # @return [String] GitHub tag
    def version_tag(ver)
      ver == "latest" ? "latest" : ver
    end

    protected

    # Downloads and extracts ripgrep binary from GitHub releases.
    #
    # @return [void]
    def perform_install
      target_ver = resolve_version
      fallback_ver = config.fallback_version

      github.download_asset(
        owner: config.owner,
        repo: config.repo,
        version: version_tag(target_ver),
        fallback_version: fallback_ver,
        asset_pattern: asset_pattern,
        fallback_asset: fallback_ver ? asset_filename(fallback_ver) : nil,
        destination: tmp_asset_path
      )

      tar.extract(tmp_asset_path, tmp_dir_path, 1)
      runCmd("cp", File.join(tmp_dir_path, "rg"), File.join(config.bin, "rg"))
      logger.info("ripgrep installed successfully.")
    end

    # Sets up man pages and shell completions.
    #
    # @return [void]
    def post_install
      setup_man_page
      setup_completions
    end

    private

    def asset_pattern
      if config.arch == "aarch64"
        "ripgrep-.*-aarch64-unknown-linux-gnu\\.tar\\.gz"
      else
        "ripgrep-.*-x86_64-unknown-linux-musl\\.tar\\.gz"
      end
    end

    def asset_filename(version)
      if config.arch == "aarch64"
        "ripgrep-#{version}-aarch64-unknown-linux-gnu.tar.gz"
      else
        "ripgrep-#{version}-x86_64-unknown-linux-musl.tar.gz"
      end
    end

    def tmp_asset_path
      File.join(config.tmp, "ripgrep-assets.tar.gz")
    end

    def tmp_dir_path
      File.join(config.tmp, "ripgrep-assets")
    end

    def setup_man_page
      FileUtils.mkdir_p(config.man1)
      runCmd("cp", File.join(tmp_dir_path, "doc", "rg.1"), File.join(config.man1, "rg.1"))
    end

    def setup_completions
      FileUtils.mkdir_p(config.zsh_completions)
      runCmd("cp", File.join(tmp_dir_path, "complete", "_rg"), File.join(config.zsh_completions, "_rg"))

      FileUtils.mkdir_p(config.bash_completions)
      runCmd("cp", File.join(tmp_dir_path, "complete", "rg.bash"), File.join(config.bash_completions, "rg"))
    end

  end
end
