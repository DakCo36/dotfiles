require 'singleton'
require 'components/base'
require 'components/configuration'
require 'mixins/installable'
require 'components/tools/github'
require 'components/tools/curl'
require 'components/tools/tar'
require 'mixins/loggable'

module Component
  class BatComponent < BaseComponent
    prepend Installable

    TARGET_ASSET_PATTERN = ".*x86_64.*linux-musl\\.tar\\.gz"
    OWNER = "sharkdp"
    REPO = "bat"

    CONFIG = Components::Configuration.instance
    TMP_ASSET_PATH = File.join(CONFIG.tmp, "bat-assets.tar.gz")
    TMP_DIR_PATH = File.join(CONFIG.tmp, "bat-assets")

    depends_on Component::CurlComponent
    depends_on Component::GithubComponent
    depends_on Component::TarComponent
 
    def available?
      system('bat', '--version', out: File::NULL, err: File::NULL)
    end

    def version
      output = `bat --version 2>&1`
      output.split[1] if $?.success? # example) bat 0.21.0 (405edf)
    rescue Errno::ENOENT
      nil
    end

    def installed?
      available? && version != nil
    end

    def install
      if installed?
        logger.info('bat already installed.')
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
      runCmd('cp', File.join(TMP_DIR_PATH, 'bat'), File.join(CONFIG.bin, 'bat'))

      setup_man_page
      setup_completions

      logger.info('Bat installed successfully.')
    end

    private
    def setup_man_page
      FileUtils.mkdir_p(CONFIG.man1)
      runCmd('cp', File.join(TMP_DIR_PATH, 'bat.1'), File.join(CONFIG.man1, 'bat.1'))
    end

    def setup_completions
      FileUtils.mkdir_p(CONFIG.zsh_completions)
      runCmd('cp', File.join(TMP_DIR_PATH, 'autocomplete', 'bat.zsh'), File.join(CONFIG.zsh_completions, '_bat'))

      FileUtils.mkdir_p(CONFIG.bash_completions)
      runCmd('cp', File.join(TMP_DIR_PATH, 'autocomplete', 'bat.bash'), File.join(CONFIG.bash_completions, 'bat'))
    end
  end
end
