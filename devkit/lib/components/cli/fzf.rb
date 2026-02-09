require "singleton"
require "components/installable_component"
require "components/configuration"
require "components/prerequisites/github"
require "components/prerequisites/curl"
require "components/prerequisites/tar"
require "mixins/loggable"

module Component
  class FzfComponent < InstallableComponent

    depends_on Component::ZshBinaryComponent
    depends_on Component::CurlComponent
    depends_on Component::GithubComponent
    depends_on Component::TarComponent

    # Returns the current fzf version.
    #
    # @return [String, nil] version string (e.g., "0.57.0") or nil
    def version
      output, status = Open3.capture2("fzf", "--version")
      output.split[0] if status.success?
    rescue Errno::ENOENT
      nil
    end

    # Checks if fzf is installed.
    #
    # @return [Boolean]
    def installed?
      !version.nil?
    end

    # Returns the latest available version from GitHub.
    #
    # @return [String, nil] version string or nil
    def latest_version
      tag = github.get_latest_release_tag(config.owner, config.repo)
      tag&.gsub(/^v/, "")
    rescue StandardError => e
      logger.warn("Failed to get latest version for fzf: #{e.message}")
      nil
    end


    # fzf uses v prefix for tags (e.g., v0.57.0)
    #
    # @param ver [String] version string
    # @return [String] GitHub tag
    def version_tag(ver)
      ver == "latest" ? "latest" : "v#{ver}"
    end

    protected

    # Downloads and extracts fzf binary from GitHub releases.
    #
    # @return [void]
    def perform_install
      target_ver = resolve_version
      fallback_ver = config.fallback_version ? version_tag(config.fallback_version) : nil

      github.download_asset(
        owner: config.owner,
        repo: config.repo,
        version: version_tag(target_ver),
        fallback_version: fallback_ver,
        asset_pattern: asset_pattern,
        fallback_asset: fallback_ver ? asset_filename(fallback_ver) : nil,
        destination: tmp_asset_path
      )

      tar.extract(tmp_asset_path, tmp_dir_path, 0)
      runCmd("cp", File.join(tmp_dir_path, "fzf"), File.join(config.bin, "fzf"))
      logger.info("fzf installed successfully.")
    end

    # Sets up fzf shell integration in .zshrc.
    #
    # @return [void]
    def post_install
      setup_shell_integration
    end

    private

    def asset_pattern
      "fzf-.*-linux_#{arch_name}\\.tar\\.gz"
    end

    def asset_filename(version)
      ver = version.sub(/^v/, "")
      "fzf-#{ver}-linux_#{arch_name}.tar.gz"
    end

    def arch_name
      config.arch == "aarch64" ? "arm64" : "amd64"
    end

    def tmp_asset_path
      File.join(config.tmp, "fzf-assets.tar.gz")
    end

    def tmp_dir_path
      File.join(config.tmp, "fzf-assets")
    end

    def setup_shell_integration
      zshrc_path = config.zshrc

      return unless File.exist?(zshrc_path)

      zshrc_content = File.read(zshrc_path)
      fzf_integration_pattern = /source.*fzf.*zsh|fzf --zsh|eval.*fzf/

      if zshrc_content.match?(fzf_integration_pattern)
        logger.info("fzf shell integration already exists in .zshrc, skipping")
        return
      end

      logger.info("Adding fzf shell integration to .zshrc")
      integration_line = "\n# fzf shell integration\neval \"$(fzf --zsh)\"\n"

      File.open(zshrc_path, "a") do |file|
        file.write(integration_line)
      end
    end

  end
end
