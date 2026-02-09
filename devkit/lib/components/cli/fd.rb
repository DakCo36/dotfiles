require "singleton"
require "components/installable_component"
require "components/configuration"
require "components/prerequisites/github"
require "components/prerequisites/curl"
require "components/prerequisites/tar"
require "mixins/loggable"

module Component
  class FdComponent < InstallableComponent

    depends_on Component::ZshBinaryComponent
    depends_on Component::CurlComponent
    depends_on Component::GithubComponent
    depends_on Component::TarComponent

    # Returns the current fd version.
    #
    # @return [String, nil] version string (e.g., "10.2.0") or nil
    def version
      output, status = Open3.capture2("fd", "--version")
      output.split[1] if status.success?
    rescue Errno::ENOENT
      nil
    end

    # Checks if fd is installed.
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
      logger.warn("Failed to get latest version for fd: #{e.message}")
      nil
    end


    # fd uses v prefix for tags (e.g., v10.2.0)
    #
    # @param ver [String] version string
    # @return [String] GitHub tag
    def version_tag(ver)
      ver == "latest" ? "latest" : "v#{ver}"
    end

    protected

    # Downloads and extracts fd binary from GitHub releases.
    #
    # @return [void]
    def perform_install
      target_ver = resolve_version
      fallback_ver = config.fallback_version ? version_tag(config.fallback_version) : nil

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
      runCmd("cp", File.join(tmp_dir_path, "fd"), File.join(config.bin, "fd"))
      logger.info("fd installed successfully.")
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
      "fd-v.*-#{arch_name}-unknown-linux-musl\\.tar\\.gz"
    end

    def asset_filename(version)
      "fd-#{version}-#{arch_name}-unknown-linux-musl.tar.gz"
    end

    def arch_name
      config.arch == "aarch64" ? "aarch64" : "x86_64"
    end

    def tmp_asset_path
      File.join(config.tmp, "fd-assets.tar.gz")
    end

    def tmp_dir_path
      File.join(config.tmp, "fd-assets")
    end

    def setup_man_page
      FileUtils.mkdir_p(config.man1)
      runCmd("cp", File.join(tmp_dir_path, "fd.1"), File.join(config.man1, "fd.1"))
    end

    def setup_completions
      FileUtils.mkdir_p(config.zsh_completions)
      runCmd("cp", File.join(tmp_dir_path, "autocomplete", "_fd"), File.join(config.zsh_completions, "_fd"))

      FileUtils.mkdir_p(config.bash_completions)
      runCmd("cp", File.join(tmp_dir_path, "autocomplete", "fd.bash"), File.join(config.bash_completions, "fd"))
    end

  end
end
