require "singleton"
require "fileutils"
require "components/base"
require "mixins/installable"
require "components/tools/github"
require "components/tools/curl"
require "components/tools/tar"
require "components/language/python"
require "components/language/node"

module Component
  class NeovimComponent < BaseComponent

    prepend Installable

    OWNER = "neovim"
    REPO = "neovim"
    TARGET_ASSET_PATTERN = "nvim-linux-x86_64\\.tar\\.gz"
    CONFIG_DIR = File.join(RESOURCES_ROOT, "neovim")
    VIM_PLUG_URL = "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"

    depends_on Component::CurlComponent
    depends_on Component::GithubComponent
    depends_on Component::TarComponent
    depends_on Component::PythonComponent
    depends_on Component::NodeComponent

    # nvim 명령어가 PATH에서 사용 가능한지 확인합니다.
    #
    # @return [Boolean] 사용 가능하면 true, 아니면 false
    def available?
      system("nvim", "--version", out: File::NULL, err: File::NULL)
    end

    # 현재 설치된 neovim 버전을 반환합니다.
    #
    # @return [String, nil] 버전 문자열 (예: "0.10.0") 또는 nil
    def version
      output, status = Open3.capture2("nvim", "--version")
      return nil unless status.success?

      match = output.match(/NVIM v(\d+\.\d+\.\d+)/)
      match[1] if match
    rescue Errno::ENOENT
      nil
    end

    # neovim이 설치되어 있는지 확인합니다.
    #
    # @return [Boolean] 설치되어 있으면 true, 아니면 false
    def installed?
      available? && !version.nil?
    end

    # GitHub 릴리스에서 최신 버전을 반환합니다.
    #
    # @return [String, nil] 버전 문자열 또는 실패 시 nil
    def latest_version
      tag = github.get_latest_release_tag(OWNER, REPO)
      tag&.gsub(/^v/, "")
    rescue StandardError => e
      logger.warn("Failed to get latest version for neovim: #{e.message}")
      nil
    end

    # neovim을 설치합니다 (이미 설치되어 있으면 스킵).
    #
    # @return [void]
    def install
      if installed?
        logger.info("Neovim already installed.")
        return
      end
      install!
    end

    # neovim을 강제로 설치합니다.
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

    # @return [String]
    def tmp_asset_path
      File.join(config.tmp, "nvim-linux64.tar.gz")
    end

    def install_neovim_binary
      tag = github.get_latest_release_tag(OWNER, REPO)
      logger.info("Latest release tag: #{tag}")

      url = github.get_latest_release_asset_download_url(OWNER, REPO, TARGET_ASSET_PATTERN)
      logger.info("Downloading neovim from: #{url}")

      curl.download(url, tmp_asset_path)
      tar.extract(tmp_asset_path, config.local, 1)

      logger.info("Neovim binary installed to #{config.local}")
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

    # @param file_path [String] 백업할 파일 경로
    def backup_if_exists(file_path)
      return unless File.exist?(file_path)

      backup_path = "#{file_path}.backup_#{Time.now.strftime("%Y%m%d%H%M%S")}"
      logger.info("Backing up #{file_path} to #{backup_path}")
      FileUtils.cp(file_path, backup_path)
    end

  end
end
