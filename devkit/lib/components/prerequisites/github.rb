require "open3"
require "components/required_component"
require "components/prerequisites/curl"
require "json"

module Component
  class GithubComponent < RequiredComponent

    RELEASE_BASE_URL = "https://api.github.com/repos/%s/%s/releases/latest"
    DIRECT_DOWNLOAD_URL = "https://github.com/%s/%s/releases/download/%s/%s"

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

    # Downloads an asset from GitHub releases.
    #
    # @param owner [String] repository owner
    # @param repo [String] repository name
    # @param version [String] version ("latest" or tag, e.g., "v0.57.0")
    # @param asset_pattern [String] asset pattern (regex)
    # @param destination [String] download destination path
    # @param fallback_version [String, nil] version to use if primary fails
    # @param fallback_asset [String, nil] exact asset filename for fallback (bypasses API)
    def download_asset(owner:, repo:, version:, asset_pattern:, destination:, fallback_version: nil, fallback_asset: nil)
      url = resolve_asset_url(owner, repo, version, asset_pattern, fallback_version, fallback_asset)
      logger.info("Downloading asset from: #{url}")
      @curl.download(url, destination)
    end

    private

    # Resolves asset URL based on version. Falls back to direct URL on API failure.
    # @return [String]
    def resolve_asset_url(owner, repo, version, asset_pattern, fallback_version, fallback_asset)
      if version == "latest"
        get_latest_release_asset_url(owner, repo, asset_pattern)
      else
        get_specific_release_asset_url(owner, repo, version, asset_pattern)
      end
    rescue StandardError => e
      raise unless fallback_version

      logger.warn("Failed to get asset for #{owner}/#{repo}: #{e.message}")
      logger.warn("Using fallback version: #{fallback_version}")

      # If fallback_asset is provided, use direct download URL (no API call)
      if fallback_asset
        direct_download_url(owner, repo, fallback_version, fallback_asset)
      else
        # Try API first, fall back to direct URL construction if that also fails
        begin
          get_specific_release_asset_url(owner, repo, fallback_version, asset_pattern)
        rescue StandardError => fallback_error
          logger.warn("Fallback API call also failed: #{fallback_error.message}")
          logger.warn("Attempting direct download URL construction")
          construct_direct_url_from_pattern(owner, repo, fallback_version, asset_pattern)
        end
      end
    end

    # Returns asset URL for the latest release.
    # @return [String]
    def get_latest_release_asset_url(owner, repo, asset_pattern)
      regex = Regexp.new(asset_pattern)
      release = JSON.parse(get_latest_release(owner, repo))

      # Check for API error responses (rate limit, not found, etc.)
      if release["message"]
        raise "GitHub API error for #{owner}/#{repo}: #{release["message"]}"
      end

      assets = release["assets"]
      raise "No assets found for #{owner}/#{repo}" if assets.nil? || assets.empty?

      asset = assets.find { |a| a["name"] =~ regex }
      raise "No asset matching pattern '#{asset_pattern}' for #{owner}/#{repo}" unless asset

      url = asset["browser_download_url"]
      logger.debug("Found asset: #{url}")
      url
    end

    # Returns asset URL for a specific version.
    # @return [String]
    def get_specific_release_asset_url(owner, repo, version, asset_pattern)
      regex = Regexp.new(asset_pattern)
      release_url = format("https://api.github.com/repos/%s/%s/releases/tags/%s", owner, repo, version)
      response = @curl.get(release_url)
      release = JSON.parse(response)

      # Check for API error responses (rate limit, not found, etc.)
      if release["message"]
        raise "GitHub API error for #{owner}/#{repo}: #{release["message"]}"
      end

      assets = release["assets"]
      raise "No assets found for #{owner}/#{repo} version #{version}" if assets.nil? || assets.empty?

      asset = assets.find { |a| a["name"] =~ regex }
      raise "No asset matching pattern '#{asset_pattern}' for #{owner}/#{repo} version #{version}" unless asset

      url = asset["browser_download_url"]
      logger.debug("Found asset for version #{version}: #{url}")
      url
    end

    # Constructs direct download URL (bypasses API)
    # @return [String]
    def direct_download_url(owner, repo, version, asset_filename)
      url = format(DIRECT_DOWNLOAD_URL, owner, repo, version, asset_filename)
      logger.info("Using direct download URL: #{url}")
      url
    end

    # Constructs direct URL by converting regex pattern to actual filename
    # Replaces common wildcards with version string
    # @return [String]
    def construct_direct_url_from_pattern(owner, repo, version, asset_pattern)
      # Remove regex escapes and replace .* with version (without v prefix if present)
      version_num = version.sub(/^v/, "")
      filename = asset_pattern
                   .gsub("\\.", ".")
                   .gsub(".*", version_num)
                   .gsub("$", "")
      url = format(DIRECT_DOWNLOAD_URL, owner, repo, version, filename)
      logger.info("Constructed direct download URL: #{url}")
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
