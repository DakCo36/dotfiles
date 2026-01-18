require "singleton"
require "fileutils"
require "components/base"
require "components/configuration"
require "mixins/installable"
require "components/tools/github"
require "components/tools/curl"
require "components/tools/tar"
require "components/language/python"

module Component
  class NeovimComponent < BaseComponent

    prepend Installable

    OWNER = "neovim"
    REPO = "neovim"
    TARGET_ASSET_PATTERN = "nvim-linux-x86_64\\.tar\\.gz"

    CONFIG = Components::Configuration.instance
    TMP_ASSET_PATH = File.join(CONFIG.tmp, "nvim-linux64.tar.gz")
    CONFIG_DIR = File.join(RESOURCES_ROOT, "neovim")

    VIM_PLUG_URL = "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"

    depends_on Component::CurlComponent
    depends_on Component::GithubComponent
    depends_on Component::TarComponent
    depends_on Component::PythonComponent

    # Checks if nvim command is available in PATH
    #
    # @return [Boolean] true if nvim is available
    def available?
      system("nvim", "--version", out: File::NULL, err: File::NULL)
    end

    # Returns the currently installed neovim version
    #
    # @return [String, nil] version string (e.g. "0.10.0") or nil if not installed
    def version
      output, status = Open3.capture2("nvim", "--version")
      return nil unless status.success?

      match = output.match(/NVIM v(\d+\.\d+\.\d+)/)
      match[1] if match
    rescue Errno::ENOENT
      nil
    end

    # Checks if neovim is installed
    #
    # @return [Boolean] true if installed
    def installed?
      available? && !version.nil?
    end

    # Returns the latest version from GitHub releases
    #
    # @return [String, nil] latest version or nil on failure
    def latest_version
      tag = github.get_latest_release_tag(OWNER, REPO)
      tag&.gsub(/^v/, "")
    rescue StandardError => e
      logger.warn("Failed to get latest version for neovim: #{e.message}")
      nil
    end

    # Installs neovim if not already installed
    def install
      if installed?
        logger.info("Neovim already installed.")
        return
      end
      install!
    end

    # Forces installation of neovim
    def install!
      install_neovim_binary
      install_vim_plug
      install_pynvim
      copy_config_files

      logger.info("Neovim installed successfully.")
    end

    private

    # Downloads and extracts neovim binary from GitHub releases
    def install_neovim_binary
      tag = github.get_latest_release_tag(OWNER, REPO)
      logger.info("Latest release tag: #{tag}")

      url = github.get_latest_release_asset_download_url(OWNER, REPO, TARGET_ASSET_PATTERN)
      logger.info("Downloading neovim from: #{url}")

      curl.download(url, TMP_ASSET_PATH)
      tar.extract(TMP_ASSET_PATH, CONFIG.local, 1)

      logger.info("Neovim binary installed to #{CONFIG.local}")
    end

    # Installs vim-plug plugin manager
    def install_vim_plug
      plug_path = File.join(CONFIG.home, ".vim", "autoload", "plug.vim")

      if File.exist?(plug_path)
        logger.info("vim-plug already installed, skipping")
        return
      end

      logger.info("Installing vim-plug...")
      FileUtils.mkdir_p(File.dirname(plug_path))
      curl.download(VIM_PLUG_URL, plug_path)
      logger.info("vim-plug installed to #{plug_path}")
    end

    # Installs pynvim Python package for neovim integration
    def install_pynvim
      logger.info("Installing pynvim...")
      runCmd("python", "-m", "pip", "install", "pynvim")
      logger.info("pynvim installed successfully")
    end

    # Copies init.vim and .vimrc to home directory
    def copy_config_files
      copy_init_vim
      copy_vimrc
    end

    # Copies init.vim to ~/.config/nvim/init.vim
    def copy_init_vim
      source = File.join(CONFIG_DIR, "init.vim")
      dest_dir = File.join(CONFIG.home, ".config", "nvim")
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

    # Copies .vimrc to ~/.vimrc
    def copy_vimrc
      source = File.join(CONFIG_DIR, ".vimrc")
      dest = File.join(CONFIG.home, ".vimrc")

      unless File.exist?(source)
        logger.error("Source file #{source} not found")
        raise "Source file #{source} not found"
      end

      backup_if_exists(dest)
      FileUtils.cp(source, dest)
      logger.info("Copied .vimrc to #{dest}")
    end

    # Creates a backup of the file if it exists
    # @param file_path [String] path to file
    def backup_if_exists(file_path)
      return unless File.exist?(file_path)

      backup_path = "#{file_path}.backup_#{Time.now.strftime("%Y%m%d%H%M%S")}"
      logger.info("Backing up #{file_path} to #{backup_path}")
      FileUtils.cp(file_path, backup_path)
    end

  end
end
