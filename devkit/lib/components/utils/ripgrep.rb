require "singleton"
require "components/base"
require "mixins/installable"
require "components/tools/github"
require "components/tools/curl"
require "components/tools/tar"
require "mixins/loggable"

module Component
  class RipgrepComponent < BaseComponent

    prepend Installable

    TARGET_ASSET_PATTERN = "ripgrep-.*-x86_64-unknown-linux-musl\\.tar\\.gz"
    OWNER = "BurntSushi"
    REPO = "ripgrep"

    depends_on Component::CurlComponent
    depends_on Component::GithubComponent
    depends_on Component::TarComponent

    # ripgrep 실행 가능 여부를 확인합니다.
    #
    # @return [Boolean] 실행 가능하면 true, 아니면 false
    def available?
      system("rg", "--version", out: File::NULL, err: File::NULL)
    end

    # 현재 설치된 ripgrep 버전을 반환합니다.
    #
    # @return [String, nil] 버전 문자열 (예: "14.1.0") 또는 설치되지 않은 경우 nil
    def version
      output, status = Open3.capture2("rg", "--version")
      # ripgrep outputs "ripgrep 14.1.0" format
      output.split[1] if status.success?
    rescue Errno::ENOENT
      nil
    end

    # ripgrep이 설치되어 있는지 확인합니다.
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
      logger.warn("Failed to get latest version for ripgrep: #{e.message}")
      nil
    end

    # ripgrep을 설치합니다 (이미 설치되어 있으면 스킵).
    #
    # @return [void]
    def install
      if installed?
        logger.info("ripgrep already installed.")
        return
      end
      install!
    end

    # ripgrep을 강제로 설치합니다.
    #
    # @return [void]
    def install!
      tag = github.get_latest_release_tag(OWNER, REPO)
      logger.info("Latest release tag: #{tag}")
      url = github.get_latest_release_asset_download_url(OWNER, REPO, TARGET_ASSET_PATTERN)
      logger.info("Downloading asset from: #{url}")
      curl.download(url, tmp_asset_path)

      tar.extract(tmp_asset_path, tmp_dir_path, 1)
      runCmd("cp", File.join(tmp_dir_path, "rg"), File.join(config.bin, "rg"))

      setup_man_page
      setup_completions

      logger.info("ripgrep installed successfully.")
    end

    private

    # @return [String]
    def tmp_asset_path
      File.join(config.tmp, "ripgrep-assets.tar.gz")
    end

    # @return [String]
    def tmp_dir_path
      File.join(config.tmp, "ripgrep-assets")
    end

    def setup_man_page
      FileUtils.mkdir_p(config.man1)
      runCmd("cp", File.join(tmp_dir_path, "doc", "rg.1"), File.join(config.man1, "rg.1"))
    end

    def setup_completions
      # zsh completions
      FileUtils.mkdir_p(config.zsh_completions)
      runCmd("cp", File.join(tmp_dir_path, "complete", "_rg"), File.join(config.zsh_completions, "_rg"))

      # bash completions
      FileUtils.mkdir_p(config.bash_completions)
      runCmd("cp", File.join(tmp_dir_path, "complete", "rg.bash"), File.join(config.bash_completions, "rg"))
    end

  end
end
