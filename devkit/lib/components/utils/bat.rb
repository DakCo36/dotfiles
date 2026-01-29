require "singleton"
require "components/base"
require "mixins/installable"
require "components/tools/github"
require "components/tools/curl"
require "components/tools/tar"
require "mixins/loggable"

module Component
  class BatComponent < BaseComponent

    prepend Installable

    TARGET_ASSET_PATTERN = ".*x86_64.*linux-musl\\.tar\\.gz"
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
      tag = github.get_latest_release_tag(OWNER, REPO)
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
      tag = github.get_latest_release_tag(OWNER, REPO)
      logger.info("Latest release tag: #{tag}")
      url = github.get_latest_release_asset_download_url(OWNER, REPO, TARGET_ASSET_PATTERN)
      logger.info("Downloading asset from: #{url}")
      curl.download(url, tmp_asset_path)

      tar.extract(tmp_asset_path, tmp_dir_path, 1)
      runCmd("cp", File.join(tmp_dir_path, "bat"), File.join(config.bin, "bat"))

      setup_man_page
      setup_completions

      logger.info("Bat installed successfully.")
    end

    private

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
