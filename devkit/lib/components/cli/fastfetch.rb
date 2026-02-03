require "singleton"
require "components/installable_component"
require "components/configuration"
require "components/tools/github"
require "components/tools/curl"
require "components/tools/tar"
require "mixins/loggable"

module Component
  class FastfetchComponent < InstallableComponent

    depends_on Component::CurlComponent
    depends_on Component::GithubComponent
    depends_on Component::TarComponent

    def available?
      system("fastfetch", "--version", out: File::NULL, err: File::NULL)
    end

    def version
      output, status = Open3.capture2("fastfetch", "--version")
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
      # Remove 'v' prefix from tag (e.g., 2.31.0)
      tag&.gsub(/^v/, "")
    rescue StandardError => e
      logger.warn("Failed to get latest version for fastfetch: #{e.message}")
      nil
    end

    def install
      if installed?
        logger.info("fastfetch already installed.")
        return
      end
      install!
    end

    def install!
      fallback_ver = config.fallback_version
      github.download_asset(
        owner: config.owner,
        repo: config.repo,
        version: config.version,
        fallback_version: fallback_ver,
        asset_pattern: asset_pattern,
        fallback_asset: fallback_ver ? asset_filename(fallback_ver) : nil,
        destination: tmp_asset_path
      )

      tar.extract(tmp_asset_path, tmp_dir_path, 1)

      runCmd("cp", File.join(extracted_bin_path, "fastfetch"), File.join(config.bin, "fastfetch"))
      runCmd("cp", File.join(extracted_bin_path, "flashfetch"), File.join(config.bin, "flashfetch"))

      setup_man_page
      setup_completions

      logger.info("fastfetch installed successfully.")
    end

    private

    # Returns asset pattern based on architecture (regex for API search).
    # fastfetch naming: fastfetch-linux-{arch}.tar.gz
    def asset_pattern
      "fastfetch-linux-#{arch_name}\\.tar\\.gz$"
    end

    # Returns exact asset filename for direct download.
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
