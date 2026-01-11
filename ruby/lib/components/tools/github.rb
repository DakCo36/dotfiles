require 'open3'
require 'components/base'
require 'components/tools/curl'
require 'json'

module Component
  class GithubComponent < BaseComponent
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
      begin
        JSON.parse(get_latest_release(owner, repo))["tag_name"]
      rescue JSON::ParserError
        logger.error("Failed to parse JSON response: #{owner}/#{repo}")
        raise "Failed to parse JSON response"
      end
    end

    def get_latest_release_asset_download_url(owner, repo, asset_pattern)
      regex = Regexp.new(asset_pattern)
      begin
        url = JSON.parse(get_latest_release(owner, repo))["assets"].find { |asset| 
          asset["name"] =~ regex
        }["browser_download_url"]
        logger.debug("Found asset: #{url}")
        return url
      rescue JSON::ParserError
        logger.error("Failed to parse JSON response: #{owner}/#{repo}")
        raise "Failed to parse JSON response"
      end
    end

    private
    def get_latest_release_url(owner, repo)
      RELEASE_BASE_URL % [owner, repo]
    end

    def get_latest_release(owner, repo)
      key = "#{owner}/#{repo}"
      @release_cache[key] ||= @curl.get(get_latest_release_url(owner, repo))
      @release_cache[key]
    end
  end
end

# RELEASE_BASE_URL = "https://api.github.com/repos/%s/%s/releases/latest"

# def get_release_url(owner, repo)
#   RELEASE_BASE_URL % [owner, repo]
# end
