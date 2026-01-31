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

    def get_latest_release_asset_download_url(owner, repo, asset_pattern)
      regex = Regexp.new(asset_pattern)
      begin
        url = JSON.parse(get_latest_release(owner, repo))["assets"].find do |asset|
          asset["name"] =~ regex
        end["browser_download_url"]
        logger.debug("Found asset: #{url}")
        url
      rescue JSON::ParserError
        logger.error("Failed to parse JSON response: #{owner}/#{repo}")
        raise "Failed to parse JSON response"
      end
    end

    # Builds a release asset URL directly without API call.
    # Useful as fallback when rate limited.
    #
    # @param owner [String] Repository owner
    # @param repo [String] Repository name
    # @param tag [String] Release tag (e.g., "v0.24.0")
    # @param asset_name [String] Asset filename (e.g., "bat-v0.24.0-x86_64-unknown-linux-musl.tar.gz")
    # @return [String] Direct download URL
    def build_release_asset_url(owner, repo, tag, asset_name)
      "https://github.com/#{owner}/#{repo}/releases/download/#{tag}/#{asset_name}"
    end

    private

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
