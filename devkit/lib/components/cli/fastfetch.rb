require "singleton"
require "components/installable_component"
require "components/configuration"
require "components/prerequisites/github"
require "components/prerequisites/curl"
require "components/prerequisites/tar"
require "mixins/loggable"

module Component
  class FastfetchComponent < InstallableComponent

    depends_on Component::ZshBinaryComponent
    depends_on Component::CurlComponent
    depends_on Component::GithubComponent
    depends_on Component::TarComponent

    # Returns the current fastfetch version.
    #
    # @return [String, nil] version string (e.g., "2.31.0") or nil
    def version
      output, status = Open3.capture2("fastfetch", "--version")
      output.split[1] if status.success?
    rescue Errno::ENOENT
      nil
    end

    # Checks if fastfetch is installed.
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
      logger.warn("Failed to get latest version for fastfetch: #{e.message}")
      nil
    end


    protected

    # Downloads and extracts fastfetch binary from GitHub releases.
    #
    # @return [void]
    def perform_install
      target_ver = resolve_version
      fallback_ver = config.fallback_version

      github.download_asset(
        owner: config.owner,
        repo: config.repo,
        version: target_ver,
        fallback_version: fallback_ver,
        asset_pattern: asset_pattern,
        fallback_asset: fallback_ver ? asset_filename(fallback_ver) : nil,
        destination: tmp_asset_path
      )

      tar.extract(tmp_asset_path, tmp_dir_path, 1)
      runCmd("cp", File.join(extracted_bin_path, "fastfetch"), File.join(config.bin, "fastfetch"))
      runCmd("cp", File.join(extracted_bin_path, "flashfetch"), File.join(config.bin, "flashfetch"))
      logger.info("fastfetch installed successfully.")
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
      "fastfetch-linux-#{arch_name}\\.tar\\.gz$"
    end

    def asset_filename(version)
      "fastfetch-linux-#{arch_name}.tar.gz"
    end

    def arch_name
      config.arch == "aarch64" ? "aarch64" : "amd64"
    end

    def tmp_asset_path
      File.join(config.tmp, "fastfetch-assets.tar.gz")
    end

    def tmp_dir_path
      File.join(config.tmp, "fastfetch-assets")
    end

    def extracted_bin_path
      File.join(tmp_dir_path, "usr", "bin")
    end

    def extracted_man_path
      File.join(tmp_dir_path, "usr", "share", "man", "man1")
    end

    def extracted_bash_completion_path
      File.join(tmp_dir_path, "usr", "share", "bash-completion", "completions")
    end

    def extracted_zsh_completion_path
      File.join(tmp_dir_path, "usr", "share", "zsh", "site-functions")
    end

    def setup_man_page
      FileUtils.mkdir_p(config.man1)
      runCmd("cp", File.join(extracted_man_path, "fastfetch.1"), File.join(config.man1, "fastfetch.1"))
    end

    def setup_completions
      FileUtils.mkdir_p(config.zsh_completions)
      runCmd("cp", File.join(extracted_zsh_completion_path, "_fastfetch"),
             File.join(config.zsh_completions, "_fastfetch"))

      FileUtils.mkdir_p(config.bash_completions)
      runCmd("cp", File.join(extracted_bash_completion_path, "fastfetch"),
             File.join(config.bash_completions, "fastfetch"))
    end

  end
end
