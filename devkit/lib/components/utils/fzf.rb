require "singleton"
require "components/base"
require "mixins/installable"
require "components/tools/github"
require "components/tools/curl"
require "components/tools/tar"
require "mixins/loggable"

module Component
  class FzfComponent < BaseComponent

    prepend Installable

    # Asset 패턴: fzf-{version}-linux_amd64.tar.gz
    TARGET_ASSET_PATTERN = "fzf-.*-linux_amd64\\.tar\\.gz"
    OWNER = "junegunn"
    REPO = "fzf"

    depends_on Component::CurlComponent
    depends_on Component::GithubComponent
    depends_on Component::TarComponent

    # fzf 실행 가능 여부를 확인합니다.
    #
    # @return [Boolean] 실행 가능하면 true, 아니면 false
    def available?
      system("fzf", "--version", out: File::NULL, err: File::NULL)
    end

    # 현재 설치된 fzf 버전을 반환합니다.
    #
    # @return [String, nil] 버전 문자열 (예: "0.57.0") 또는 설치되지 않은 경우 nil
    def version
      output, status = Open3.capture2("fzf", "--version")
      # fzf outputs "0.57.0 (fc7630a)" format
      output.split[0] if status.success?
    rescue Errno::ENOENT
      nil
    end

    # fzf가 설치되어 있는지 확인합니다.
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
      logger.warn("Failed to get latest version for fzf: #{e.message}")
      nil
    end

    # fzf를 설치합니다 (이미 설치되어 있으면 스킵).
    #
    # @return [void]
    def install
      if installed?
        logger.info("fzf already installed.")
        return
      end
      install!
    end

    # fzf를 강제로 설치합니다.
    #
    # @return [void]
    def install!
      tag = github.get_latest_release_tag(OWNER, REPO)
      logger.info("Latest release tag: #{tag}")
      url = github.get_latest_release_asset_download_url(OWNER, REPO, TARGET_ASSET_PATTERN)
      logger.info("Downloading asset from: #{url}")
      curl.download(url, tmp_asset_path)

      # fzf tarball contains only the fzf binary at root level (no subdirectory)
      tar.extract(tmp_asset_path, tmp_dir_path, 0)
      runCmd("cp", File.join(tmp_dir_path, "fzf"), File.join(config.bin, "fzf"))

      setup_shell_integration

      logger.info("fzf installed successfully.")
    end

    private

    # @return [String]
    def tmp_asset_path
      File.join(config.tmp, "fzf-assets.tar.gz")
    end

    # @return [String]
    def tmp_dir_path
      File.join(config.tmp, "fzf-assets")
    end

    def setup_shell_integration
      # fzf 0.48.0+ supports --zsh, --bash flags for shell integration
      # Add shell integration source to .zshrc if not present
      zshrc_path = File.join(config.home, ".zshrc")

      return unless File.exist?(zshrc_path)

      zshrc_content = File.read(zshrc_path)
      fzf_integration_pattern = /source.*fzf.*zsh|fzf --zsh|eval.*fzf/

      if zshrc_content.match?(fzf_integration_pattern)
        logger.info("fzf shell integration already exists in .zshrc, skipping")
        return
      end

      logger.info("Adding fzf shell integration to .zshrc")
      # Use the new --zsh flag for fzf 0.48.0+
      integration_line = "\n# fzf shell integration\neval \"$(fzf --zsh)\"\n"

      File.open(zshrc_path, "a") do |file|
        file.write(integration_line)
      end
    end

  end
end
