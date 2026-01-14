require 'singleton'
require 'components/base'
require 'components/configuration'
require 'mixins/installable'
require 'components/tools/github'
require 'components/tools/curl'
require 'components/tools/tar'
require 'mixins/loggable'

module Component
  class FastfetchComponent < BaseComponent
    prepend Installable

    # Asset 패턴: fastfetch-linux-amd64.tar.gz
    TARGET_ASSET_PATTERN = "fastfetch-linux-amd64\\.tar\\.gz$"
    OWNER = "fastfetch-cli"
    REPO = "fastfetch"

    CONFIG = Components::Configuration.instance
    TMP_ASSET_PATH = File.join(CONFIG.tmp, "fastfetch-assets.tar.gz")
    TMP_DIR_PATH = File.join(CONFIG.tmp, "fastfetch-assets")

    EXTRACTED_BIN_PATH = File.join(TMP_DIR_PATH, 'usr', 'bin')
    EXTRACTED_MAN_PATH = File.join(TMP_DIR_PATH, 'usr', 'share', 'man', 'man1')
    EXTRACTED_BASH_COMPLETION_PATH = File.join(TMP_DIR_PATH, 'usr', 'share', 'bash-completion', 'completions')
    EXTRACTED_ZSH_COMPLETION_PATH = File.join(TMP_DIR_PATH, 'usr', 'share', 'zsh', 'site-functions')

    depends_on Component::CurlComponent
    depends_on Component::GithubComponent
    depends_on Component::TarComponent

    def available?
      system('fastfetch', '--version', out: File::NULL, err: File::NULL)
    end

    def version
      output, status = Open3.capture2('fastfetch', '--version')
      output.split[1] if status.success?
    rescue Errno::ENOENT
      nil
    end

    def installed?
      available? && version != nil
    end

    def install
      if installed?
        logger.info('fastfetch already installed.')
        return
      end
      install!
    end

    def install!
      tag = github.get_latest_release_tag(OWNER, REPO)
      logger.info("Latest release tag: #{tag}")
      url = github.get_latest_release_asset_download_url(OWNER, REPO, TARGET_ASSET_PATTERN)
      logger.info("Downloading asset from: #{url}")
      curl.download(url, TMP_ASSET_PATH)

      tar.extract(TMP_ASSET_PATH, TMP_DIR_PATH, 1)

      runCmd('cp', File.join(EXTRACTED_BIN_PATH, 'fastfetch'), File.join(CONFIG.bin, 'fastfetch'))
      runCmd('cp', File.join(EXTRACTED_BIN_PATH, 'flashfetch'), File.join(CONFIG.bin, 'flashfetch'))

      setup_man_page
      setup_completions

      logger.info('fastfetch installed successfully.')
    end

    private

    def setup_man_page
      FileUtils.mkdir_p(CONFIG.man1)
      runCmd('cp', File.join(EXTRACTED_MAN_PATH, 'fastfetch.1'), File.join(CONFIG.man1, 'fastfetch.1'))
    end

    def setup_completions
      # zsh completions
      FileUtils.mkdir_p(CONFIG.zsh_completions)
      runCmd('cp', File.join(EXTRACTED_ZSH_COMPLETION_PATH, '_fastfetch'), File.join(CONFIG.zsh_completions, '_fastfetch'))

      # bash completions
      FileUtils.mkdir_p(CONFIG.bash_completions)
      runCmd('cp', File.join(EXTRACTED_BASH_COMPLETION_PATH, 'fastfetch'), File.join(CONFIG.bash_completions, 'fastfetch'))
    end
  end
end
