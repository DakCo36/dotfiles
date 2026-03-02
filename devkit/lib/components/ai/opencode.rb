require "components/installable_component"
require "components/configuration"

module Component
  class OpencodeComponent < InstallableComponent

    depends_on Component::CurlComponent
    depends_on Component::GithubComponent

    # Returns the current opencode version.
    #
    # @return [String, nil] version string (e.g., "1.2.15") or nil
    def version
      output, status = Open3.capture2("opencode", "--version")
      output.split[1] if status.success?
    rescue Errno::ENOENT
      nil
    end

    def latest_version
      return "1.2.15"
    end

    # Checks if fastfetch is installed.
    #
    # @return [Boolean]
    def installed?
      !version.nil?
    end

    protected

    # Downloads and extracts fastfetch binary from GitHub releases.
    #
    # @return [void]
    def perform_install
      runCmd("mise", "use", "-g", "github:#{config.owner}/#{config.repo}@#{config.version}")
    end
  end
end
