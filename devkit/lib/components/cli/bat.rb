require "singleton"
require "components/installable_component"
require "components/configuration"
require "components/tools/github"
require "components/tools/curl"
require "components/tools/tar"
require "mixins/loggable"

module Component
  class BatComponent < InstallableComponent

    TARGET_ASSET_PATTERN = ".*x86_64.*linux-musl\\.tar\\.gz"

    CONFIG = Components::Configuration.instance
    TMP_ASSET_PATH = File.join(CONFIG.tmp, "bat-assets.tar.gz")
    TMP_DIR_PATH = File.join(CONFIG.tmp, "bat-assets")

    depends_on Component::CurlComponent
    depends_on Component::GithubComponent
    depends_on Component::TarComponent

    def available?
      system("bat", "--version", out: File::NULL, err: File::NULL)
    end

    def version
      output, status = Open3.capture2("bat", "--version")
      output.split[1] if status.success? # example) bat 0.21.0 (405edf)
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
      logger.warn("Failed to get latest version for bat: #{e.message}")
      nil
    end

    def install
      if installed?
        logger.info("bat already installed.")
        return
      end
      install!
    end

    def install!
      github.download_asset(
        owner: config.owner,
        repo: config.repo,
        version: version_tag(config.version),
        fallback_version: config.fallback_version ? version_tag(config.fallback_version) : nil,
        asset_pattern: TARGET_ASSET_PATTERN,
        destination: TMP_ASSET_PATH
      )

      tar.extract(TMP_ASSET_PATH, TMP_DIR_PATH, 1)
      runCmd("cp", File.join(TMP_DIR_PATH, "bat"), File.join(CONFIG.bin, "bat"))

      setup_man_page
      setup_completions

      logger.info("Bat installed successfully.")
    end

    # bat은 v 접두사 태그 사용 (예: v0.24.0)
    def version_tag(ver)
      ver == "latest" ? "latest" : "v#{ver}"
    end

    private

    def setup_man_page
      FileUtils.mkdir_p(CONFIG.man1)
      runCmd("cp", File.join(TMP_DIR_PATH, "bat.1"), File.join(CONFIG.man1, "bat.1"))
    end

    def setup_completions
      FileUtils.mkdir_p(CONFIG.zsh_completions)
      runCmd("cp", File.join(TMP_DIR_PATH, "autocomplete", "bat.zsh"), File.join(CONFIG.zsh_completions, "_bat"))

      FileUtils.mkdir_p(CONFIG.bash_completions)
      runCmd("cp", File.join(TMP_DIR_PATH, "autocomplete", "bat.bash"), File.join(CONFIG.bash_completions, "bat"))
    end

  end
end
