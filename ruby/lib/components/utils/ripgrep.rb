require 'singleton'
require 'components/base'
require 'components/configuration'
require 'mixins/installable'
require 'components/tools/github'
require 'components/tools/curl'
require 'components/tools/tar'
require 'mixins/loggable'

module Component
  class RipgrepComponent < BaseComponent
    prepend Installable

    TARGET_ASSET_PATTERN = "ripgrep-.*-x86_64-unknown-linux-musl\\.tar\\.gz"
    OWNER = "BurntSushi"
    REPO = "ripgrep"

    CONFIG = Components::Configuration.instance
    TMP_ASSET_PATH = File.join(CONFIG.tmp, "ripgrep-assets.tar.gz")
    TMP_DIR_PATH = File.join(CONFIG.tmp, "ripgrep-assets")

    depends_on Component::CurlComponent
    depends_on Component::GithubComponent
    depends_on Component::TarComponent

    def available?
      system('rg', '--version', out: File::NULL, err: File::NULL)
    end

    def version
      output, status = Open3.capture2('rg', '--version')
      # ripgrep outputs "ripgrep 14.1.0" format
      output.split[1] if status.success?
    rescue Errno::ENOENT
      nil
    end

    def installed?
      available? && version != nil
    end

    def install
      if installed?
        logger.info('ripgrep already installed.')
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
      runCmd('cp', File.join(TMP_DIR_PATH, 'rg'), File.join(CONFIG.bin, 'rg'))

      setup_man_page
      setup_completions

      logger.info('ripgrep installed successfully.')
    end

    private

    def setup_man_page
      FileUtils.mkdir_p(CONFIG.man1)
      runCmd('cp', File.join(TMP_DIR_PATH, 'doc', 'rg.1'), File.join(CONFIG.man1, 'rg.1'))
    end

    def setup_completions
      # zsh completions
      FileUtils.mkdir_p(CONFIG.zsh_completions)
      runCmd('cp', File.join(TMP_DIR_PATH, 'complete', '_rg'), File.join(CONFIG.zsh_completions, '_rg'))

      # bash completions
      FileUtils.mkdir_p(CONFIG.bash_completions)
      runCmd('cp', File.join(TMP_DIR_PATH, 'complete', 'rg.bash'), File.join(CONFIG.bash_completions, 'rg'))
    end
  end
end
