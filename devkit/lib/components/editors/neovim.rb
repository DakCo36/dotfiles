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

    VIM_PLUG_URL = "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"

    depends_on Component::CurlComponent
    depends_on Component::GithubComponent
    depends_on Component::TarComponent
    depends_on Component::PythonComponent
    depends_on Component::NodeComponent

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
      tag = github.get_latest_release_tag(config.owner, config.repo)
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
      install_plugins

      logger.info("Neovim installed successfully.")
    end

    private

    # Returns asset pattern based on architecture (regex for API search).
    # neovim naming: nvim-linux-x86_64.tar.gz (x86_64) or nvim-linux-arm64.tar.gz (aarch64)
    def asset_pattern
      if config.arch == "aarch64"
        "nvim-linux-arm64\\.tar\\.gz"
      else
        "nvim-linux-x86_64\\.tar\\.gz"
      end
    end

    # Returns exact asset filename for direct download.
    def asset_filename(version)
      if config.arch == "aarch64"
        "nvim-linux-arm64.tar.gz"
      else
        "nvim-linux-x86_64.tar.gz"
      end
    end

    def tmp_asset_path
      File.join(config.tmp, "nvim-linux-x86_64.tar.gz")
    end

    def config_dir
      File.join(RESOURCES_ROOT, "neovim")
    end

    # Downloads and extracts neovim binary from GitHub releases
    def install_neovim_binary
      fallback_ver = config.fallback_version ? version_tag(config.fallback_version) : nil
      github.download_asset(
        owner: config.owner,
        repo: config.repo,
        version: version_tag(config.version),
        fallback_version: fallback_ver,
        asset_pattern: asset_pattern,
        fallback_asset: fallback_ver ? asset_filename(fallback_ver) : nil,
        destination: tmp_asset_path
      )

      tar.extract(tmp_asset_path, config.local, 1)

      logger.info("Neovim binary installed to #{config.local}")
    end

    # neovim uses v prefix for tags (e.g., v0.10.0)
    def version_tag(ver)
      ver == "latest" ? "latest" : "v#{ver}"
    end

    # Installs vim-plug plugin manager
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

    # Installs pynvim Python package for neovim integration
    def install_pynvim
      logger.info("Installing pynvim...")
      runCmd("mise", "exec", "--", "python", "-m", "pip", "install", "pynvim")
      logger.info("pynvim installed successfully")
    end

    # Installs vim plugins using vim-plug
    def install_plugins
      logger.info("Installing vim plugins via vim-plug...")
      runCmd("nvim", "--headless", "+PlugInstall", "+qall")
      logger.info("Vim plugins installed successfully")
    end

    # Copies init.vim and .vimrc to home directory
    def copy_config_files
      copy_init_vim
      copy_vimrc
    end

    # Copies init.vim to ~/.config/nvim/init.vim
    def copy_init_vim
      source = File.join(config_dir, "init.vim")
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

    # Copies .vimrc to ~/.vimrc
    def copy_vimrc
      source = File.join(config_dir, ".vimrc")
      dest = File.join(config.home, ".vimrc")

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
