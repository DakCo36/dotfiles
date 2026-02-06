require "singleton"
require "components/installable_component"
require "components/configuration"
require "components/tools/github"
require "components/tools/curl"
require "components/tools/tar"
require "mixins/loggable"

module Component
  class RipgrepComponent < InstallableComponent

    depends_on Component::ZshBinaryComponent
    depends_on Component::CurlComponent
    depends_on Component::GithubComponent
    depends_on Component::TarComponent

    def available?
      system("rg", "--version", out: File::NULL, err: File::NULL)
    end

    def version
      output, status = Open3.capture2("rg", "--version")
      # ripgrep outputs "ripgrep 14.1.0" format
      output.split[1] if status.success?
    rescue Errno::ENOENT
      nil
    end

    def installed?
      available? && !version.nil?
    end

    # Fetches latest release tag from GitHub and returns the version
    def latest_version
      tag = github.get_latest_release_tag(config.owner, config.repo)
      # Extract numeric version from tag (e.g., 14.1.0)
      tag&.gsub(/^v/, "")
    rescue StandardError => e
      logger.warn("Failed to get latest version for ripgrep: #{e.message}")
      nil
    end

    def install
      if installed?
        logger.info("ripgrep already installed.")
        return
      end
      install!
    end

    def install!
      fallback_ver = config.fallback_version ? version_tag(config.fallback_version) : nil
      github.download_asset(
        owner: config.owner,
        repo: config.repo,
        version: version_tag(config.version),
        fallback_version: fallback_ver,
        asset_pattern: asset_pattern,
        fallback_asset: fallback_ver ? asset_filename(fallback_ver) : nil,
        destination: tmp_asset_path
      )

      tar.extract(tmp_asset_path, tmp_dir_path, 1)
      runCmd("cp", File.join(tmp_dir_path, "rg"), File.join(config.bin, "rg"))

      setup_man_page
      setup_completions

      logger.info("ripgrep installed successfully.")
    end

    # ripgrep does not use v prefix for tags (e.g., 14.1.0)
    def version_tag(ver)
      ver == "latest" ? "latest" : ver
    end

    private

    # Returns asset pattern based on architecture (regex for API search).
    # x86_64: ripgrep-X.Y.Z-x86_64-unknown-linux-musl.tar.gz
    # aarch64: ripgrep-X.Y.Z-aarch64-unknown-linux-gnu.tar.gz
    def asset_pattern
      if config.arch == "aarch64"
        "ripgrep-.*-aarch64-unknown-linux-gnu\\.tar\\.gz"
      else
        "ripgrep-.*-x86_64-unknown-linux-musl\\.tar\\.gz"
      end
    end

    # Returns exact asset filename for direct download.
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
      # zsh completions
      FileUtils.mkdir_p(config.zsh_completions)
      runCmd("cp", File.join(tmp_dir_path, "complete", "_rg"), File.join(config.zsh_completions, "_rg"))

      # bash completions
      FileUtils.mkdir_p(config.bash_completions)
      runCmd("cp", File.join(tmp_dir_path, "complete", "rg.bash"), File.join(config.bash_completions, "rg"))
    end

  end
end
