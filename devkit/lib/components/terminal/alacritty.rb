# frozen_string_literal: true

require "singleton"
require "components/installable_component"
require "components/configuration"
require "components/language/rust"
require "components/tools/github"
require "components/tools/curl"
require "mixins/loggable"

module Component
  class AlacrittyComponent < InstallableComponent

    depends_on Component::ZshBinaryComponent
    depends_on Component::RustComponent
    depends_on Component::CurlComponent
    depends_on Component::GithubComponent

    GITHUB_OWNER = "alacritty"
    GITHUB_REPO = "alacritty"

    # Checks if alacritty is available.
    #
    # @return [Boolean] true if available, false otherwise
    def available?
      system("alacritty", "--version", out: File::NULL, err: File::NULL) ||
        system("mise", "exec", "rust", "--", "alacritty", "--version", out: File::NULL, err: File::NULL)
    end

    # Returns the current alacritty version.
    #
    # @return [String, nil] Version string (e.g., "0.16.1") or nil
    def version
      output = nil
      status = nil

      # Try direct first (alacritty in PATH)
      begin
        output, status = Open3.capture2("alacritty", "--version")
        logger.debug("Direct alacritty --version: status=#{status.success?}, output=#{output.strip}")
      rescue Errno::ENOENT
        logger.debug("Direct alacritty not found in PATH")
        status = nil
      end

      # Fallback to mise exec
      unless status&.success?
        begin
          output, status = Open3.capture2("mise", "exec", "rust", "--", "alacritty", "--version")
          logger.debug("Mise exec alacritty --version: status=#{status.success?}, output=#{output.strip}")
        rescue Errno::ENOENT => e
          logger.debug("Mise exec failed: #{e.message}")
          return nil
        end
      end

      return nil unless status&.success?

      # example: alacritty 0.16.1 (a]b2c3d4)
      match = output.match(/alacritty\s+([\d.]+)/)
      match ? match[1] : nil
    end

    # Checks if alacritty is installed.
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
      logger.warn("Failed to get latest version for alacritty: #{e.message}")
      nil
    end

    # Installs alacritty (skips if already installed).
    #
    # @return [void]
    def install
      if installed?
        logger.info("alacritty #{version} is already installed.")
        return
      end
      install!
    end

    # Force installs alacritty via cargo, then downloads extra assets.
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
          logger.error("Failed to get alacritty version. Set fallback_version in config.")
          return
        end
      end

      # 2. Install specific version via cargo
      logger.info("Installing alacritty v#{target_ver} via cargo...")
      runCmd("mise", "exec", "rust", "--", "cargo", "install", "alacritty@#{target_ver}", showStdout: true)

      # 3. Symlink cargo binary to ~/.local/bin/ so desktop environments can find it
      create_symlink

      # 4. Download and install extra assets from GitHub releases
      logger.info("Setting up alacritty extras for v#{target_ver}...")
      download_terminfo(target_ver)
      download_icon(target_ver)
      download_desktop_entry(target_ver)
      download_man_pages(target_ver)
      download_completions(target_ver)

      logger.info("alacritty #{target_ver} installed successfully with all extras.")
    end

    def rollback
      raise "Not implemented"
    end

    private

    # Downloads and installs terminfo from GitHub releases.
    # Uses `tic` without sudo to install to ~/.terminfo/
    #
    # @param ver [String] version string (e.g., "0.16.1")
    def download_terminfo(ver)
      asset_url = release_asset_url(ver, "alacritty.info")
      tmp_path = File.join(config.tmp, "alacritty.info")

      curl.download(asset_url, tmp_path)

      # tic without sudo installs to ~/.terminfo/
      runCmd("tic", "-xe", "alacritty,alacritty-direct", tmp_path)

      logger.info("alacritty terminfo installed.")
    rescue StandardError => e
      logger.warn("Failed to install alacritty terminfo: #{e.message}")
    end

    # Downloads and installs icon (SVG) to user-local icons directory.
    #
    # @param ver [String] version string
    def download_icon(ver)
      asset_url = release_asset_url(ver, "Alacritty.svg")
      icons_dir = File.join(config.home, ".local", "share", "icons", "hicolor", "scalable", "apps")
      FileUtils.mkdir_p(icons_dir)

      tmp_path = File.join(config.tmp, "Alacritty.svg")
      curl.download(asset_url, tmp_path)
      runCmd("cp", tmp_path, File.join(icons_dir, "Alacritty.svg"))

      logger.info("alacritty icon installed.")
    rescue StandardError => e
      logger.warn("Failed to install alacritty icon: #{e.message}")
    end

    # Creates a symlink from ~/.cargo/bin/alacritty to ~/.local/bin/alacritty
    # so that desktop environments (GNOME, KDE) can find the binary via TryExec.
    def create_symlink
      cargo_bin = File.join(config.home, ".cargo", "bin", "alacritty")
      local_bin = File.join(config.bin, "alacritty")

      unless File.exist?(cargo_bin)
        logger.warn("cargo binary not found at #{cargo_bin}, skipping symlink")
        return
      end

      FileUtils.mkdir_p(config.bin)
      FileUtils.ln_sf(cargo_bin, local_bin)
      logger.info("Symlinked #{cargo_bin} -> #{local_bin}")
    rescue StandardError => e
      logger.warn("Failed to create alacritty symlink: #{e.message}")
    end

    # Downloads and installs desktop entry to user-local applications directory.
    #
    # @param ver [String] version string
    def download_desktop_entry(ver)
      asset_url = release_asset_url(ver, "Alacritty.desktop")
      apps_dir = File.join(config.home, ".local", "share", "applications")
      FileUtils.mkdir_p(apps_dir)

      tmp_path = File.join(config.tmp, "Alacritty.desktop")
      curl.download(asset_url, tmp_path)
      runCmd("cp", tmp_path, File.join(apps_dir, "Alacritty.desktop"))

      # Update desktop database so GNOME/KDE picks up the new entry
      update_desktop_database(apps_dir)

      logger.info("alacritty desktop entry installed.")
    rescue StandardError => e
      logger.warn("Failed to install alacritty desktop entry: #{e.message}")
    end

    # Updates the desktop database. Logs a warning if the command is not available.
    def update_desktop_database(apps_dir)
      if system("which", "update-desktop-database", out: File::NULL, err: File::NULL)
        runCmd("update-desktop-database", apps_dir)
        logger.info("Desktop database updated.")
      else
        logger.warn("update-desktop-database not found, skipping. App may not appear until re-login.")
      end
    rescue StandardError => e
      logger.warn("Failed to update desktop database: #{e.message}")
    end

    # Downloads and installs man pages from GitHub releases.
    # Section 1: alacritty.1.gz, alacritty-msg.1.gz (commands)
    # Section 5: alacritty.5.gz, alacritty-bindings.5.gz (config file formats)
    #
    # @param ver [String] version string
    def download_man_pages(ver)
      # Man section 1 pages (commands)
      man1_pages = ["alacritty.1.gz", "alacritty-msg.1.gz"]
      FileUtils.mkdir_p(config.man1)

      man1_pages.each do |page|
        asset_url = release_asset_url(ver, page)
        tmp_path = File.join(config.tmp, page)
        curl.download(asset_url, tmp_path)
        runCmd("cp", tmp_path, File.join(config.man1, page))
      end

      # Man section 5 pages (file formats / config)
      man5_pages = ["alacritty.5.gz", "alacritty-bindings.5.gz"]
      man5_dir = File.join(config.local, "share", "man", "man5")
      FileUtils.mkdir_p(man5_dir)

      man5_pages.each do |page|
        asset_url = release_asset_url(ver, page)
        tmp_path = File.join(config.tmp, page)
        curl.download(asset_url, tmp_path)
        runCmd("cp", tmp_path, File.join(man5_dir, page))
      end

      logger.info("alacritty man pages installed (man1 + man5).")
    rescue StandardError => e
      logger.warn("Failed to download alacritty man pages: #{e.message}")
    end

    # Downloads and installs zsh completion from GitHub releases.
    #
    # @param ver [String] version string
    def download_completions(ver)
      asset_url = release_asset_url(ver, "_alacritty")
      tmp_path = File.join(config.tmp, "_alacritty")

      curl.download(asset_url, tmp_path)

      FileUtils.mkdir_p(config.zsh_completions)
      runCmd("cp", tmp_path, File.join(config.zsh_completions, "_alacritty"))

      logger.info("alacritty zsh completion installed.")
    rescue StandardError => e
      logger.warn("Failed to download alacritty completions: #{e.message}")
    end

    # Constructs a GitHub release asset URL.
    #
    # @param ver [String] version string (e.g., "0.16.1")
    # @param asset_name [String] asset filename
    # @return [String] full download URL
    def release_asset_url(ver, asset_name)
      "https://github.com/#{GITHUB_OWNER}/#{GITHUB_REPO}/releases/download/v#{ver}/#{asset_name}"
    end

  end
end
