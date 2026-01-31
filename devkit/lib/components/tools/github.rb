require "open3"
require "components/required_tool"
require "components/tools/curl"
require "json"

module Component
  class GithubComponent < RequiredTool

    RELEASE_BASE_URL = "https://api.github.com/repos/%s/%s/releases/latest"

    def initialize
      super
      @curl = CurlComponent.instance
      @release_cache = {}
    end

    def available?
      @curl.available?
    end

    def get_latest_release_tag(owner, repo)
      JSON.parse(get_latest_release(owner, repo))["tag_name"]
    rescue JSON::ParserError
      logger.error("Failed to parse JSON response: #{owner}/#{repo}")
      raise "Failed to parse JSON response"
    end

    # GitHub 릴리스에서 에셋을 다운로드합니다.
    #
    # @param owner [String] 저장소 소유자
    # @param repo [String] 저장소 이름
    # @param version [String] 버전 ("latest" 또는 태그, 예: "v0.57.0")
    # @param asset_pattern [String] 에셋 패턴 (정규식)
    # @param destination [String] 저장 경로
    # @param fallback_version [String, nil] 실패 시 사용할 버전
    def download_asset(owner:, repo:, version:, asset_pattern:, destination:, fallback_version: nil)
      url = resolve_asset_url(owner, repo, version, asset_pattern, fallback_version)
      logger.info("Downloading asset from: #{url}")
      @curl.download(url, destination)
    end

    private

    # 버전에 따라 에셋 URL 결정 → latest면 API 호출, 실패 시 fallback
    # @return [String]
    def resolve_asset_url(owner, repo, version, asset_pattern, fallback_version)
      if version == "latest"
        get_latest_release_asset_url(owner, repo, asset_pattern)
      else
        get_specific_release_asset_url(owner, repo, version, asset_pattern)
      end
    rescue StandardError => e
      raise unless fallback_version

      logger.warn("Failed to get asset for #{owner}/#{repo}: #{e.message}")
      logger.warn("Using fallback version: #{fallback_version}")
      get_specific_release_asset_url(owner, repo, fallback_version, asset_pattern)
    end

    # 최신 릴리스의 에셋 URL 반환
    # @return [String]
    def get_latest_release_asset_url(owner, repo, asset_pattern)
      regex = Regexp.new(asset_pattern)
      url = JSON.parse(get_latest_release(owner, repo))["assets"].find do |asset|
        asset["name"] =~ regex
      end["browser_download_url"]
      logger.debug("Found asset: #{url}")
      url
    end

    # 특정 버전의 에셋 URL 반환
    # @return [String]
    def get_specific_release_asset_url(owner, repo, version, asset_pattern)
      regex = Regexp.new(asset_pattern)
      release_url = format("https://api.github.com/repos/%s/%s/releases/tags/%s", owner, repo, version)
      response = @curl.get(release_url)

      url = JSON.parse(response)["assets"].find do |asset|
        asset["name"] =~ regex
      end["browser_download_url"]
      logger.debug("Found asset for version #{version}: #{url}")
      url
    end

    def get_latest_release_url(owner, repo)
      format(RELEASE_BASE_URL, owner, repo)
    end

    def get_latest_release(owner, repo)
      key = "#{owner}/#{repo}"
      @release_cache[key] ||= @curl.get(get_latest_release_url(owner, repo))
      @release_cache[key]
    end

  end
end
