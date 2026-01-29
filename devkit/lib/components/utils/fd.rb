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

    TARGET_ASSET_PATTERN = "fd-v.*-x86_64-unknown-linux-musl\\.tar\\.gz"
    OWNER = "sharkdp"
    REPO = "fd"

    depends_on Component::CurlComponent
    depends_on Component::GithubComponent
    depends_on Component::TarComponent

    # fd 실행 가능 여부를 확인합니다.
    #
    # @return [Boolean] 실행 가능하면 true, 아니면 false
    def available?
      system("fd", "--version", out: File::NULL, err: File::NULL)
    end

    # 현재 설치된 fd 버전을 반환합니다.
    #
    # @return [String, nil] 버전 문자열 (예: "10.3.0") 또는 설치되지 않은 경우 nil
    def version
      output, status = Open3.capture2("fd", "--version")
      output.split[1] if status.success?
    rescue Errno::ENOENT
      nil
    end

    # fd가 설치되어 있는지 확인합니다.
    #
    # @return [Boolean] 설치되어 있으면 true, 아니면 false
    def installed?
      available? && !version.nil?
    end

    # 최신 버전을 반환합니다.
    #
    # @return [String, nil] 버전 문자열 또는 실패 시 nil
    def latest_version
      tag = github.get_latest_release_tag(OWNER, REPO)
      tag&.gsub(/^v/, "")
    rescue StandardError => e
      logger.warn("Failed to get latest version for fd: #{e.message}")
      nil
    end

    # fd를 설치합니다 (이미 설치되어 있으면 스킵).
    #
    # @return [void]
    def install
      if installed?
        logger.info("fd already installed.")
        return
      end
      install!
    end

    # fd를 강제로 설치합니다.
    #
    # @return [void]
    def install!
      tag = github.get_latest_release_tag(OWNER, REPO)
      logger.info("Latest release tag: #{tag}")
      url = github.get_latest_release_asset_download_url(OWNER, REPO, TARGET_ASSET_PATTERN)
      logger.info("Downloading asset from: #{url}")
      curl.download(url, tmp_asset_path)

      tar.extract(tmp_asset_path, tmp_dir_path, 1)
      runCmd("cp", File.join(tmp_dir_path, "fd"), File.join(config.bin, "fd"))

      setup_man_page
      setup_completions

      logger.info("fd installed successfully.")
    end

    private

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
