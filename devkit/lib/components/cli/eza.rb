# frozen_string_literal: true

require "singleton"
require "components/installable_component"
require "components/configuration"
require "components/language/rust"
require "components/tools/github"
require "components/tools/curl"
require "components/tools/tar"
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

    # Checks if eza is available.
    #
    # @return [Boolean] true if available, false otherwise
    def available?
      # Try direct first, then via mise (cargo installs to ~/.cargo/bin)
      system("eza", "--version", out: File::NULL, err: File::NULL) ||
        system("mise", "exec", "rust", "--", "eza", "--version", out: File::NULL, err: File::NULL)
    end

    # Returns the current eza version.
    #
    # @return [String, nil] Version string (e.g., "0.23.4") or nil
    def version
      output = nil
      status = nil

      # Try direct first (eza in PATH)
      begin
        output, status = Open3.capture2("eza", "--version")
        logger.debug("Direct eza --version: status=#{status.success?}, output=#{output.strip}")
      rescue Errno::ENOENT
        logger.debug("Direct eza not found in PATH")
        status = nil
      end

      # Fallback to mise exec (cargo installs to ~/.cargo/bin)
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

      # example: eza - A modern alternative to ls (v0.23.4 [+git])
      match = output.match(/v([\d.]+)/)
      match ? match[1] : nil
    end

    # Checks if eza is installed.
    #
    # @return [Boolean] true if installed, false otherwise
    def installed?
      available? && !version.nil?
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

    # Installs eza (skips if already installed).
    #
    # @return [void]
    def install
      if installed?
        logger.info("eza #{version} is already installed.")
        return
      end
      install!
    end

    # Force installs eza via cargo, then downloads completions and man pages.
    #
    # @return [void]
    def install!
      # 1. Get target version (try latest, fallback to config)
      target_ver = latest_version
      unless target_ver
        if config.fallback_version
          logger.warn("GitHub API failed, using fallback version: #{config.fallback_version}")
          target_ver = config.fallback_version
        else
          logger.error("Failed to get eza version. Set fallback_version in config.")
          return
        end
      end

      # 2. Install specific version via cargo
      logger.info("Installing eza v#{target_ver} via cargo...")
      runCmd("mise", "exec", "rust", "--", "cargo", "install", "eza@#{target_ver}", showStdout: true)

      # 3. Download completions and man pages for that version
      logger.info("Downloading eza completions and man pages for v#{target_ver}...")
      download_completions(target_ver)
      download_man_pages(target_ver)

      logger.info("eza #{target_ver} installed successfully with completions and man pages.")
    end

    def rollback
      raise "Not implemented"
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

      # Actual structure: target/completions-{ver}/_eza, target/completions-{ver}/eza
      completions_dir = File.join(extract_path, "target", "completions-#{ver}")

      # Setup zsh completions
      FileUtils.mkdir_p(config.zsh_completions)
      zsh_src = File.join(completions_dir, "_eza")
      runCmd("cp", zsh_src, File.join(config.zsh_completions, "_eza")) if File.exist?(zsh_src)

      # Setup bash completions
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

      # Actual structure: target/man-{ver}/*.1, target/man-{ver}/*.5
      man_dir = File.join(extract_path, "target", "man-#{ver}")

      # Setup man1 pages (eza.1)
      FileUtils.mkdir_p(config.man1)
      Dir.glob(File.join(man_dir, "*.1")).each do |man_file|
        runCmd("cp", man_file, File.join(config.man1, File.basename(man_file)))
      end

      # Setup man5 pages (eza_colors.5, eza_colors-explanation.5)
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
