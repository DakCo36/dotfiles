require "singleton"
require "components/installable_component"
require "components/configuration"
require "components/tools/github"
require "components/tools/curl"
require "components/tools/tar"
require "mixins/loggable"

module Component
  class FzfComponent < InstallableComponent

    depends_on Component::ZshBinaryComponent
    depends_on Component::CurlComponent
    depends_on Component::GithubComponent
    depends_on Component::TarComponent

    def available?
      system("fzf", "--version", out: File::NULL, err: File::NULL)
    end

    def version
      output, status = Open3.capture2("fzf", "--version")
      # fzf outputs "0.57.0 (fc7630a)" format
      output.split[0] if status.success?
    rescue Errno::ENOENT
      nil
    end

    def installed?
      available? && !version.nil?
    end

    def latest_version
      tag = github.get_latest_release_tag(config.owner, config.repo)
      tag&.gsub(/^v/, "")
    rescue StandardError => e
      logger.warn("Failed to get latest version for fzf: #{e.message}")
      nil
    end

    def install
      if installed?
        logger.info("fzf already installed.")
        return
      end
      install!
    end

    def install!
      fallback_ver = config.fallback_version ? version_tag(config.fallback_version) : nil
      github.download_asset(
        owner: config.owner,
        repo: config.repo,
        version: version_tag(config.version),
        fallback_version: fallback_ver,
        asset_pattern: asset_pattern,
        fallback_asset: fallback_ver ? asset_filename(fallback_ver) : nil,
        destination: tmp_asset_path
      )

      # fzf tarball contains only the fzf binary at root level (no subdirectory)
      tar.extract(tmp_asset_path, tmp_dir_path, 0)
      runCmd("cp", File.join(tmp_dir_path, "fzf"), File.join(config.bin, "fzf"))

      setup_shell_integration

      logger.info("fzf installed successfully.")
    end

    # fzf uses v prefix for tags (e.g., v0.57.0)
    def version_tag(ver)
      ver == "latest" ? "latest" : "v#{ver}"
    end

    private

    # Returns asset pattern based on architecture (regex for API search).
    # fzf naming: fzf-X.Y.Z-linux_{arch}.tar.gz
    def asset_pattern
      "fzf-.*-linux_#{arch_name}\\.tar\\.gz"
    end

    # Returns exact asset filename for direct download.
    # fzf uses version without v prefix in filename (e.g., fzf-0.57.0-linux_arm64.tar.gz)
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
      # fzf 0.48.0+ supports --zsh, --bash flags for shell integration
      # Add shell integration source to .zshrc if not present
      zshrc_path = config.zshrc

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
