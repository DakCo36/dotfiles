require "fileutils"
require "components/installable_component"
require "components/configuration"
require "components/prerequisites/github"
require "components/prerequisites/curl"

module Component
  class NerdFontsComponent < InstallableComponent

    VERSION_FILE_NAME = ".version"
    FONT_NAME = "Meslo"

    depends_on Component::CurlComponent
    depends_on Component::GithubComponent

    def installed?
      Dir.exist?(fonts_dir) && Dir.glob(File.join(fonts_dir, "*.ttf")).any?
    end

    def version
      version_file = File.join(fonts_dir, VERSION_FILE_NAME)
      return nil unless File.exist?(version_file)

      File.read(version_file).strip
    rescue StandardError
      nil
    end

    def latest_version
      tag = github.get_latest_release_tag(config.owner, config.repo)
      tag&.gsub(/^v/, "")
    rescue StandardError => e
      logger.warn("Failed to get latest version for nerd-fonts: #{e.message}")
      nil
    end

    def version_tag(ver)
      ver == "latest" ? "latest" : "v#{ver}"
    end

    protected

    def pre_install
      FileUtils.rm_rf(fonts_dir) if Dir.exist?(fonts_dir)
      FileUtils.mkdir_p(fonts_dir)
    end

    def perform_install
      target_ver = resolve_version
      logger.info("Installing Nerd Fonts (#{FONT_NAME}) v#{target_ver}")

      asset = "#{FONT_NAME}.zip"
      url = "https://github.com/#{config.owner}/#{config.repo}/releases/download/#{version_tag(target_ver)}/#{asset}"

      curl.download(url, tmp_zip_path)
      extract_fonts
      write_version_file(target_ver)
    end

    def post_install
      refresh_font_cache
    end

    private

    def fonts_base_dir
      File.join(config.home, ".local", "share", "fonts")
    end

    def fonts_dir
      File.join(fonts_base_dir, "NerdFonts")
    end

    def tmp_zip_path
      File.join(config.tmp, "#{FONT_NAME}.zip")
    end

    def extract_fonts
      runCmd("unzip", "-o", tmp_zip_path, "-d", fonts_dir)
      logger.info("Extracted fonts to #{config.contract_path(fonts_dir)}")
    end

    def write_version_file(ver)
      File.write(File.join(fonts_dir, VERSION_FILE_NAME), ver)
    end

    def refresh_font_cache
      runCmd("fc-cache", "-fv", fonts_base_dir)
      logger.info("Font cache refreshed")
    rescue StandardError => e
      logger.warn("Failed to refresh font cache: #{e.message}")
    end

    def config_key
      "nerd-fonts"
    end

  end
end
