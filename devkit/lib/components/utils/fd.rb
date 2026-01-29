require "singleton"
require "components/base"
require "mixins/installable"
require "components/tools/github"
require "components/tools/curl"
require "components/tools/tar"
require "mixins/loggable"

module Component
  class FdComponent < BaseComponent

    prepend Installable

    OWNER = "sharkdp"
    REPO = "fd"

    depends_on Component::CurlComponent
    depends_on Component::GithubComponent
    depends_on Component::TarComponent

    # Checks if fd is available.
    #
    # @return [Boolean] true if available, false otherwise
    def available?
      system("fd", "--version", out: File::NULL, err: File::NULL)
    end

    # Returns the current fd version.
    #
    # @return [String, nil] Version string (e.g., "10.3.0") or nil if not installed
    def version
      output, status = Open3.capture2("fd", "--version")
      output.split[1] if status.success?
    rescue Errno::ENOENT
      nil
    end

    # Checks if fd is installed.
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
      logger.warn("Failed to get latest version for fd: #{e.message}")
      nil
    end

    # Installs fd (skips if already installed).
    #
    # @return [void]
    def install
      if installed?
        logger.info("fd already installed.")
        return
      end
      install!
    end

    # Force installs fd.
    #
    # @return [void]
    def install!
      tag = github.get_latest_release_tag(OWNER, REPO)
      logger.info("Latest release tag: #{tag}")
      url = github.get_latest_release_asset_download_url(OWNER, REPO, target_asset_pattern)
      logger.info("Downloading asset from: #{url}")
      curl.download(url, tmp_asset_path)

      tar.extract(tmp_asset_path, tmp_dir_path, 1)
      runCmd("cp", File.join(tmp_dir_path, "fd"), File.join(config.bin, "fd"))

      setup_man_page
      setup_completions

      logger.info("fd installed successfully.")
    end

    private

    # Returns the asset pattern for the current architecture.
    #
    # @return [String] Regex pattern for the target asset
    def target_asset_pattern
      arch = config.arch
      os = config.os

      if os.include?("darwin")
        if arch == "arm64"
          "fd-v.*-aarch64-apple-darwin\\.tar\\.gz"
        else
          "fd-v.*-x86_64-apple-darwin\\.tar\\.gz"
        end
      else
        if arch.include?("x86_64") || arch.include?("amd64")
          "fd-v.*-x86_64-unknown-linux-musl\\.tar\\.gz"
        elsif arch == "arm64" || arch.include?("aarch64")
          "fd-v.*-aarch64-unknown-linux-musl\\.tar\\.gz"
        else
          raise "Unsupported architecture: #{arch} on #{os}"
        end
      end
    end

    # @return [String]
    def tmp_asset_path
      File.join(config.tmp, "fd-assets.tar.gz")
    end

    # @return [String]
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
