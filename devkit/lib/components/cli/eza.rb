# frozen_string_literal: true

require "singleton"
require "components/installable_component"
require "components/configuration"
require "components/language/rust"
require "components/prerequisites/github"
require "components/prerequisites/curl"
require "components/prerequisites/tar"
require "mixins/loggable"

module Component
  class EzaComponent < InstallableComponent

    depends_on Component::ZshBinaryComponent
    depends_on Component::RustComponent
    depends_on Component::CurlComponent
    depends_on Component::GithubComponent
    depends_on Component::TarComponent

    GITHUB_OWNER = "eza-community"
    GITHUB_REPO = "eza"

    # Returns the current eza version.
    #
    # @return [String, nil] Version string (e.g., "0.23.4") or nil
    def version
      output = nil
      status = nil

      begin
        output, status = Open3.capture2("eza", "--version")
        logger.debug("Direct eza --version: status=#{status.success?}, output=#{output.strip}")
      rescue Errno::ENOENT
        logger.debug("Direct eza not found in PATH")
        status = nil
      end

      unless status&.success?
        begin
          output, status = Open3.capture2("mise", "exec", "rust", "--", "eza", "--version")
          logger.debug("Mise exec eza --version: status=#{status.success?}, output=#{output.strip}")
        rescue Errno::ENOENT => e
          logger.debug("Mise exec failed: #{e.message}")
          return nil
        end
      end

      return nil unless status&.success?

      match = output.match(/v([\d.]+)/)
      match ? match[1] : nil
    end

    # Checks if eza is installed.
    #
    # @return [Boolean] true if installed, false otherwise
    def installed?
      !version.nil?
    end

    # Returns the latest version from GitHub.
    #
    # @return [String, nil] version string or nil
    def latest_version
      tag = github.get_latest_release_tag(GITHUB_OWNER, GITHUB_REPO)
      tag&.gsub(/^v/, "")
    rescue StandardError => e
      logger.warn("Failed to get latest version for eza: #{e.message}")
      nil
    end

    protected

    # Installs eza binary via cargo.
    #
    # @return [void]
    def perform_install
      @target_ver = resolve_version
      logger.info("Installing eza v#{@target_ver} via cargo...")
      runCmd("mise", "exec", "rust", "--", "cargo", "install", "eza@#{@target_ver}", showStdout: true)
    end

    # Downloads completions and man pages for installed version.
    #
    # @return [void]
    def post_install
      ver = @target_ver || version || config.fallback_version
      logger.info("Downloading eza completions and man pages for v#{ver}...")
      download_completions(ver)
      download_man_pages(ver)
      logger.info("eza #{ver} installed successfully with completions and man pages.")
    end

    private

    # Downloads and installs shell completions from GitHub releases.
    #
    # @param ver [String] version string (e.g., "0.23.4")
    def download_completions(ver)
      asset_url = "https://github.com/#{GITHUB_OWNER}/#{GITHUB_REPO}/releases/download/v#{ver}/completions-#{ver}.tar.gz"
      tmp_path = File.join(config.tmp, "eza-completions.tar.gz")
      extract_path = File.join(config.tmp, "eza-completions")

      curl.download(asset_url, tmp_path)
      tar.extract(tmp_path, extract_path, 0)

      completions_dir = File.join(extract_path, "target", "completions-#{ver}")

      FileUtils.mkdir_p(config.zsh_completions)
      zsh_src = File.join(completions_dir, "_eza")
      runCmd("cp", zsh_src, File.join(config.zsh_completions, "_eza")) if File.exist?(zsh_src)

      FileUtils.mkdir_p(config.bash_completions)
      bash_src = File.join(completions_dir, "eza")
      runCmd("cp", bash_src, File.join(config.bash_completions, "eza")) if File.exist?(bash_src)

      logger.info("eza completions installed.")
    rescue StandardError => e
      logger.warn("Failed to download eza completions: #{e.message}")
    end

    # Downloads and installs man pages from GitHub releases.
    #
    # @param ver [String] version string (e.g., "0.23.4")
    def download_man_pages(ver)
      asset_url = "https://github.com/#{GITHUB_OWNER}/#{GITHUB_REPO}/releases/download/v#{ver}/man-#{ver}.tar.gz"
      tmp_path = File.join(config.tmp, "eza-man.tar.gz")
      extract_path = File.join(config.tmp, "eza-man")

      curl.download(asset_url, tmp_path)
      tar.extract(tmp_path, extract_path, 0)

      man_dir = File.join(extract_path, "target", "man-#{ver}")

      FileUtils.mkdir_p(config.man1)
      Dir.glob(File.join(man_dir, "*.1")).each do |man_file|
        runCmd("cp", man_file, File.join(config.man1, File.basename(man_file)))
      end

      man5_path = File.join(config.local, "share", "man", "man5")
      FileUtils.mkdir_p(man5_path)
      Dir.glob(File.join(man_dir, "*.5")).each do |man_file|
        runCmd("cp", man_file, File.join(man5_path, File.basename(man_file)))
      end

      logger.info("eza man pages installed.")
    rescue StandardError => e
      logger.warn("Failed to download eza man pages: #{e.message}")
    end

  end
end
