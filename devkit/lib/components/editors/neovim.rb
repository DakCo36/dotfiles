require "singleton"
require "fileutils"
require "components/installable_component"
require "components/configuration"
require "components/prerequisites/github"
require "components/prerequisites/curl"
require "components/prerequisites/tar"
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

    # Returns the currently installed neovim version.
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

    # Checks if neovim is installed.
    #
    # @return [Boolean] true if installed
    def installed?
      !version.nil?
    end

    # Returns the latest version from GitHub releases.
    #
    # @return [String, nil] latest version or nil on failure
    def latest_version
      tag = github.get_latest_release_tag(config.owner, config.repo)
      tag&.gsub(/^v/, "")
    rescue StandardError => e
      logger.warn("Failed to get latest version for neovim: #{e.message}")
      nil
    end


    # neovim uses v prefix for tags (e.g., v0.10.0)
    #
    # @param ver [String] version string
    # @return [String] GitHub tag
    def version_tag(ver)
      ver == "latest" ? "latest" : "v#{ver}"
    end

    protected

    # Downloads and extracts neovim binary from GitHub releases.
    #
    # @return [void]
    def perform_install
      target_ver = resolve_version
      fallback_ver = config.fallback_version ? version_tag(config.fallback_version) : nil

      github.download_asset(
        owner: config.owner,
        repo: config.repo,
        version: version_tag(target_ver),
        fallback_version: fallback_ver,
        asset_pattern: asset_pattern,
        fallback_asset: fallback_ver ? asset_filename(fallback_ver) : nil,
        destination: tmp_asset_path
      )

      tar.extract(tmp_asset_path, config.local, 1)
      logger.info("Neovim binary installed to #{config.local}")
    end

    # Sets up vim-plug, pynvim, and installs plugins.
    # Config files (init.vim, .vimrc) are handled by install_resources via TOML.
    #
    # @return [void]
    def post_install
      install_vim_plug
      install_pynvim
      install_plugins
      logger.info("Neovim installed successfully.")
    end

    private

    def asset_pattern
      if config.arch == "aarch64"
        "nvim-linux-arm64\\.tar\\.gz"
      else
        "nvim-linux-x86_64\\.tar\\.gz"
      end
    end

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

  end
end
