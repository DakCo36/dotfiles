require "singleton"
require "fileutils"
require "components/installable_component"
require "components/configuration"
require "components/tools/github"
require "components/tools/curl"
require "components/tools/tar"
require "components/language/python"
require "components/language/node"

module Component
  class NeovimComponent < InstallableComponent

    OWNER = "neovim"
    REPO = "neovim"
    CONFIG_DIR = File.join(RESOURCES_ROOT, "neovim")
    VIM_PLUG_URL = "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"

    depends_on Component::CurlComponent
    depends_on Component::GithubComponent
    depends_on Component::TarComponent
    depends_on Component::PythonComponent
    depends_on Component::NodeComponent

    # Checks if nvim command is available in PATH.
    #
    # @return [Boolean] true if available, false otherwise
    def available?
      system("nvim", "--version", out: File::NULL, err: File::NULL)
    end

    # Returns the current neovim version.
    #
    # @return [String, nil] Version string (e.g., "0.10.0") or nil
    def version
      output, status = Open3.capture2("nvim", "--version")
      return nil unless status.success?

      match = output.match(/NVIM v(\d+\.\d+\.\d+)/)
      match[1] if match
    rescue Errno::ENOENT
      nil
    end

    # Checks if neovim is installed.
    #
    # @return [Boolean] true if installed, false otherwise
    def installed?
      available? && !version.nil?
    end

    # Returns the latest version from GitHub releases.
    #
    # @return [String, nil] Version string or nil on failure
    def latest_version
      tag = github.get_latest_release_tag(config.owner, config.repo)
      tag&.gsub(/^v/, "")
    rescue StandardError => e
      logger.warn("Failed to get latest version for neovim: #{e.message}")
      nil
    end

    # Installs neovim (skips if already installed).
    #
    # @return [void]
    def install
      if installed?
        logger.info("Neovim already installed.")
        return
      end
      install!
    end

    # Force installs neovim.
    #
    # @return [void]
    def install!
      install_neovim_binary
      install_vim_plug
      install_pynvim
      copy_config_files
      install_plugins

      logger.info("Neovim installed successfully.")
    end

    private

<<<<<<< HEAD
    # Returns the asset pattern for the current architecture.
    #
    # @return [String] Regex pattern for the target asset
    def target_asset_pattern
      arch = config.arch
      os = config.os

      if os.include?("darwin")
        # macOS
        if arch == "arm64"
          "nvim-macos-arm64\\.tar\\.gz"
        else
          "nvim-macos-x86_64\\.tar\\.gz"
        end
      else
        # Linux
        if arch.include?("x86_64") || arch.include?("amd64")
          "nvim-linux-x86_64\\.tar\\.gz"
        elsif arch == "arm64" || arch.include?("aarch64")
          "nvim-linux-arm64\\.tar\\.gz"
        else
          raise "Unsupported architecture: #{arch} on #{os}"
        end
      end
    end

    # @return [String]
    def tmp_asset_path
      filename = target_asset_pattern.gsub("\\", "")
      File.join(config.tmp, filename)
    end

    def install_neovim_binary
      tag, url = resolve_version_and_url
      logger.info("Installing version: #{tag}")
      logger.info("Downloading neovim from: #{url}")

      curl.download(url, tmp_asset_path)
      tar.extract(tmp_asset_path, config.local, 1)

      logger.info("Neovim binary installed to #{config.local}")
    end

    def resolve_version_and_url
      component_config = config.component_config("neovim") || {}
      version = component_config["version"]

      if version && version != "latest"
        tag = "v#{version}"
        asset_name = build_asset_name(tag)
        url = github.build_release_asset_url(OWNER, REPO, tag, asset_name)
        return [tag, url]
      end

      tag = github.get_latest_release_tag(OWNER, REPO)
      url = github.get_latest_release_asset_download_url(OWNER, REPO, target_asset_pattern)
      [tag, url]
    rescue StandardError => e
      fallback = component_config["fallback_version"]
      raise "API failed and no fallback_version configured: #{e.message}" unless fallback

      tag = "v#{fallback}"
      asset_name = build_asset_name(tag)
      url = github.build_release_asset_url(OWNER, REPO, tag, asset_name)
      logger.warn("API failed, using fallback version: #{tag}")
      [tag, url]
    end

    def build_asset_name(tag)
      arch = config.arch
      os = config.os

      if os.include?("darwin")
        arch_str = arch == "arm64" ? "macos-arm64" : "macos-x86_64"
      else
        arch_str = (arch == "arm64" || arch.include?("aarch64")) ? "linux-arm64" : "linux-x86_64"
      end

      "nvim-#{arch_str}.tar.gz"
=======
    # Downloads and extracts neovim binary from GitHub releases
    def install_neovim_binary
      tag = github.get_latest_release_tag(config.owner, config.repo)
      logger.info("Latest release tag: #{tag}")

      url = github.get_latest_release_asset_download_url(config.owner, config.repo, TARGET_ASSET_PATTERN)
      logger.info("Downloading neovim from: #{url}")

      curl.download(url, TMP_ASSET_PATH)
      tar.extract(TMP_ASSET_PATH, CONFIG.local, 1)

      logger.info("Neovim binary installed to #{CONFIG.local}")
>>>>>>> 0c48187 (refactor: use config.owner/repo instead of hardcoded constants)
    end

    def install_vim_plug
      plug_path = File.join(config.home, ".vim", "autoload", "plug.vim")

      if File.exist?(plug_path)
        logger.info("vim-plug already installed, skipping")
        return
      end

      logger.info("Installing vim-plug...")
      FileUtils.mkdir_p(File.dirname(plug_path))
      curl.download(VIM_PLUG_URL, plug_path)
      logger.info("vim-plug installed to #{plug_path}")
    end

    def install_pynvim
      logger.info("Installing pynvim...")
      runCmd("mise", "exec", "--", "python", "-m", "pip", "install", "pynvim")
      logger.info("pynvim installed successfully")
    end

    def install_plugins
      logger.info("Installing vim plugins via vim-plug...")
      runCmd("nvim", "--headless", "+PlugInstall", "+qall")
      logger.info("Vim plugins installed successfully")
    end

    def copy_config_files
      copy_init_vim
      copy_vimrc
    end

    def copy_init_vim
      source = File.join(CONFIG_DIR, "init.vim")
      dest_dir = File.join(config.home, ".config", "nvim")
      dest = File.join(dest_dir, "init.vim")

      unless File.exist?(source)
        logger.error("Source file #{source} not found")
        raise "Source file #{source} not found"
      end

      backup_if_exists(dest)
      FileUtils.mkdir_p(dest_dir)
      FileUtils.cp(source, dest)
      logger.info("Copied init.vim to #{dest}")
    end

    def copy_vimrc
      source = File.join(CONFIG_DIR, ".vimrc")
      dest = File.join(config.home, ".vimrc")

      unless File.exist?(source)
        logger.error("Source file #{source} not found")
        raise "Source file #{source} not found"
      end

      backup_if_exists(dest)
      FileUtils.cp(source, dest)
      logger.info("Copied .vimrc to #{dest}")
    end

    # @param file_path [String] File path to backup
    def backup_if_exists(file_path)
      return unless File.exist?(file_path)

      backup_path = "#{file_path}.backup_#{Time.now.strftime("%Y%m%d%H%M%S")}"
      logger.info("Backing up #{file_path} to #{backup_path}")
      FileUtils.cp(file_path, backup_path)
    end

  end
end
