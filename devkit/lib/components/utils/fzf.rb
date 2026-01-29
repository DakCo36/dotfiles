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

    # Asset pattern: fzf-{version}-linux_amd64.tar.gz
    TARGET_ASSET_PATTERN = "fzf-.*-linux_amd64\\.tar\\.gz"
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
      tag = github.get_latest_release_tag(OWNER, REPO)
      logger.info("Latest release tag: #{tag}")
      url = github.get_latest_release_asset_download_url(OWNER, REPO, TARGET_ASSET_PATTERN)
      logger.info("Downloading asset from: #{url}")
      curl.download(url, tmp_asset_path)

      # fzf tarball contains only the fzf binary at root level (no subdirectory)
      tar.extract(tmp_asset_path, tmp_dir_path, 0)
      runCmd("cp", File.join(tmp_dir_path, "fzf"), File.join(config.bin, "fzf"))

      setup_shell_integration

      logger.info("fzf installed successfully.")
    end

    private

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
