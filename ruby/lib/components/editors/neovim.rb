require 'singleton'
require 'components/base'
require 'components/configuration'
require 'mixins/installable'
require 'components/tools/github'
require 'components/tools/curl'
require 'components/tools/tar'
require 'mixins/loggable'

module Component
  class NeovimComponent < BaseComponent
    prepend Installable

    # GitHub 저장소 정보
    OWNER = "neovim"
    REPO = "neovim"

    # Asset 패턴: nvim-linux-x86_64.tar.gz (최신 버전 형식)
    # 참고: 이전 버전은 nvim-linux64.tar.gz 형식이었음
    # arm64 버전이 먼저 매칭되지 않도록 x86_64를 명시
    TARGET_ASSET_PATTERN = "nvim-linux-x86_64\\.tar\\.gz$"

    # 설정 및 임시 경로
    CONFIG = Components::Configuration.instance
    TMP_ASSET_PATH = File.join(CONFIG.tmp, "nvim-assets.tar.gz")
    TMP_DIR_PATH = File.join(CONFIG.tmp, "nvim-assets")

    # 압축 해제 후 바이너리 경로 (tar --strip 1 후의 구조)
    EXTRACTED_BIN_PATH = File.join(TMP_DIR_PATH, 'bin')
    EXTRACTED_LIB_PATH = File.join(TMP_DIR_PATH, 'lib')
    EXTRACTED_SHARE_PATH = File.join(TMP_DIR_PATH, 'share')
    EXTRACTED_MAN_PATH = File.join(TMP_DIR_PATH, 'man', 'man1')

    # vim-plug 설치 경로
    VIM_PLUG_URL = "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
    VIM_AUTOLOAD_PATH = File.join(CONFIG.home, '.vim', 'autoload')
    NVIM_AUTOLOAD_PATH = File.join(CONFIG.home, '.local', 'share', 'nvim', 'site', 'autoload')

    depends_on Component::CurlComponent
    depends_on Component::GithubComponent
    depends_on Component::TarComponent

    def available?
      system('nvim', '--version', out: File::NULL, err: File::NULL)
    end

    def version
      output, status = Open3.capture2('nvim', '--version')
      # "NVIM v0.10.0" 형식에서 버전 추출
      if status.success?
        match = output.match(/NVIM v([0-9]+\.[0-9]+\.[0-9]+)/)
        match[1] if match
      end
    rescue Errno::ENOENT
      nil
    end

    def installed?
      available? && version != nil
    end

    def install
      if installed?
        logger.info("neovim already installed. (version: #{version})")
        return
      end
      install!
    end

    def install!
      install_neovim
      install_vim_plug
      logger.info('neovim installed successfully.')
    end

    private

    # Neovim 바이너리 설치
    def install_neovim
      tag = github.get_latest_release_tag(OWNER, REPO)
      logger.info("Latest release tag: #{tag}")

      url = github.get_latest_release_asset_download_url(OWNER, REPO, TARGET_ASSET_PATTERN)
      logger.info("Downloading asset from: #{url}")

      curl.download(url, TMP_ASSET_PATH)
      tar.extract(TMP_ASSET_PATH, TMP_DIR_PATH, 1)

      copy_binaries
      copy_libraries
      copy_share_files
      setup_man_page
    end

    def copy_binaries
      FileUtils.mkdir_p(CONFIG.bin)
      runCmd('cp', File.join(EXTRACTED_BIN_PATH, 'nvim'), File.join(CONFIG.bin, 'nvim'))
    end

    def copy_libraries
      # lib/nvim 디렉토리 전체 복사
      src_lib = File.join(EXTRACTED_LIB_PATH, 'nvim')
      dest_lib = File.join(CONFIG.local, 'lib', 'nvim')

      if Dir.exist?(src_lib)
        FileUtils.mkdir_p(dest_lib)
        FileUtils.cp_r(Dir.glob("#{src_lib}/*"), dest_lib)
        logger.info("Copied nvim libraries to #{CONFIG.contract_path(dest_lib)}")
      end
    end

    def copy_share_files
      # share/nvim 디렉토리 전체 복사 (런타임 파일들)
      src_share = File.join(EXTRACTED_SHARE_PATH, 'nvim')
      dest_share = File.join(CONFIG.local, 'share', 'nvim')

      if Dir.exist?(src_share)
        FileUtils.mkdir_p(dest_share)
        FileUtils.cp_r(Dir.glob("#{src_share}/*"), dest_share)
        logger.info("Copied nvim runtime files to #{CONFIG.contract_path(dest_share)}")
      end
    end

    def setup_man_page
      FileUtils.mkdir_p(CONFIG.man1)

      # man 페이지가 있는 경우에만 복사
      man_file = File.join(EXTRACTED_MAN_PATH, 'nvim.1')
      if File.exist?(man_file)
        runCmd('cp', man_file, File.join(CONFIG.man1, 'nvim.1'))
        logger.info("Installed nvim man page")
      end
    end

    # vim-plug 플러그인 매니저 설치
    def install_vim_plug
      logger.info("Installing vim-plug plugin manager...")

      # Vim용 autoload 디렉토리 생성 및 설치
      FileUtils.mkdir_p(VIM_AUTOLOAD_PATH)
      curl.download(VIM_PLUG_URL, File.join(VIM_AUTOLOAD_PATH, 'plug.vim'))
      logger.info("Installed vim-plug to #{CONFIG.contract_path(VIM_AUTOLOAD_PATH)}")

      # Neovim용 autoload 디렉토리 생성 및 설치
      FileUtils.mkdir_p(NVIM_AUTOLOAD_PATH)
      curl.download(VIM_PLUG_URL, File.join(NVIM_AUTOLOAD_PATH, 'plug.vim'))
      logger.info("Installed vim-plug to #{CONFIG.contract_path(NVIM_AUTOLOAD_PATH)}")
    end
  end
end
