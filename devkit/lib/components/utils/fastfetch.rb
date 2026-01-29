require "singleton"
require "components/base"
require "mixins/installable"
require "components/tools/github"
require "components/tools/curl"
require "components/tools/tar"
require "mixins/loggable"

module Component
  class FastfetchComponent < BaseComponent

    prepend Installable

    # Asset 패턴: fastfetch-linux-amd64.tar.gz
    TARGET_ASSET_PATTERN = "fastfetch-linux-amd64\\.tar\\.gz$"
    OWNER = "fastfetch-cli"
    REPO = "fastfetch"

    depends_on Component::CurlComponent
    depends_on Component::GithubComponent
    depends_on Component::TarComponent

    # fastfetch 실행 가능 여부를 확인합니다.
    #
    # @return [Boolean] 실행 가능하면 true, 아니면 false
    def available?
      system("fastfetch", "--version", out: File::NULL, err: File::NULL)
    end

    # 현재 설치된 fastfetch 버전을 반환합니다.
    #
    # @return [String, nil] 버전 문자열 (예: "2.57.1") 또는 설치되지 않은 경우 nil
    def version
      output, status = Open3.capture2("fastfetch", "--version")
      output.split[1] if status.success?
    rescue Errno::ENOENT
      nil
    end

    # fastfetch가 설치되어 있는지 확인합니다.
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
      logger.warn("Failed to get latest version for fastfetch: #{e.message}")
      nil
    end

    # fastfetch를 설치합니다 (이미 설치되어 있으면 스킵).
    #
    # @return [void]
    def install
      if installed?
        logger.info("fastfetch already installed.")
        return
      end
      install!
    end

    # fastfetch를 강제로 설치합니다.
    #
    # @return [void]
    def install!
      tag = github.get_latest_release_tag(OWNER, REPO)
      logger.info("Latest release tag: #{tag}")
      url = github.get_latest_release_asset_download_url(OWNER, REPO, TARGET_ASSET_PATTERN)
      logger.info("Downloading asset from: #{url}")
      curl.download(url, tmp_asset_path)

      tar.extract(tmp_asset_path, tmp_dir_path, 1)

      runCmd("cp", File.join(extracted_bin_path, "fastfetch"), File.join(config.bin, "fastfetch"))
      runCmd("cp", File.join(extracted_bin_path, "flashfetch"), File.join(config.bin, "flashfetch"))

      setup_man_page
      setup_completions

      logger.info("fastfetch installed successfully.")
    end

    private

    # @return [String]
    def tmp_asset_path
      File.join(config.tmp, "fastfetch-assets.tar.gz")
    end

    # @return [String]
    def tmp_dir_path
      File.join(config.tmp, "fastfetch-assets")
    end

    # @return [String]
    def extracted_bin_path
      File.join(tmp_dir_path, "usr", "bin")
    end

    # @return [String]
    def extracted_man_path
      File.join(tmp_dir_path, "usr", "share", "man", "man1")
    end

    # @return [String]
    def extracted_bash_completion_path
      File.join(tmp_dir_path, "usr", "share", "bash-completion", "completions")
    end

    # @return [String]
    def extracted_zsh_completion_path
      File.join(tmp_dir_path, "usr", "share", "zsh", "site-functions")
    end

    def setup_man_page
      FileUtils.mkdir_p(config.man1)
      runCmd("cp", File.join(extracted_man_path, "fastfetch.1"), File.join(config.man1, "fastfetch.1"))
    end

    def setup_completions
      # zsh completions
      FileUtils.mkdir_p(config.zsh_completions)
      runCmd("cp", File.join(extracted_zsh_completion_path, "_fastfetch"),
             File.join(config.zsh_completions, "_fastfetch"))

      # bash completions
      FileUtils.mkdir_p(config.bash_completions)
      runCmd("cp", File.join(extracted_bash_completion_path, "fastfetch"),
             File.join(config.bash_completions, "fastfetch"))
    end

  end
end
