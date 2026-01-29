require "singleton"
require "components/base"
require "mixins/installable"
require "components/tools/github"
require "components/tools/curl"
require "components/tools/tar"
require "mixins/loggable"

module Component
  class RipgrepComponent < BaseComponent

    prepend Installable

    TARGET_ASSET_PATTERN = "ripgrep-.*-x86_64-unknown-linux-musl\\.tar\\.gz"
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
      tag = github.get_latest_release_tag(OWNER, REPO)
      logger.info("Latest release tag: #{tag}")
      url = github.get_latest_release_asset_download_url(OWNER, REPO, TARGET_ASSET_PATTERN)
      logger.info("Downloading asset from: #{url}")
      curl.download(url, tmp_asset_path)

      tar.extract(tmp_asset_path, tmp_dir_path, 1)
      runCmd("cp", File.join(tmp_dir_path, "rg"), File.join(config.bin, "rg"))

      setup_man_page
      setup_completions

      logger.info("ripgrep installed successfully.")
    end

    private

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
