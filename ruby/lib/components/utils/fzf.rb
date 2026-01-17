require 'singleton'
require 'components/base'
require 'components/configuration'
require 'mixins/installable'
require 'components/tools/github'
require 'components/tools/curl'
require 'components/tools/tar'
require 'mixins/loggable'

module Component
  class FzfComponent < BaseComponent
    prepend Installable

    # Asset 패턴: fzf-{version}-linux_amd64.tar.gz
    TARGET_ASSET_PATTERN = "fzf-.*-linux_amd64\\.tar\\.gz"
    OWNER = "junegunn"
    REPO = "fzf"

    CONFIG = Components::Configuration.instance
    TMP_ASSET_PATH = File.join(CONFIG.tmp, "fzf-assets.tar.gz")
    TMP_DIR_PATH = File.join(CONFIG.tmp, "fzf-assets")

    depends_on Component::CurlComponent
    depends_on Component::GithubComponent
    depends_on Component::TarComponent

    def available?
      system('fzf', '--version', out: File::NULL, err: File::NULL)
    end

    def version
      output, status = Open3.capture2('fzf', '--version')
      # fzf outputs "0.57.0 (fc7630a)" format
      output.split[0] if status.success?
    rescue Errno::ENOENT
      nil
    end

    def installed?
      available? && version != nil
    end

    def install
      if installed?
        logger.info('fzf already installed.')
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

      # fzf tarball contains only the fzf binary at root level (no subdirectory)
      tar.extract(TMP_ASSET_PATH, TMP_DIR_PATH, 0)
      runCmd('cp', File.join(TMP_DIR_PATH, 'fzf'), File.join(CONFIG.bin, 'fzf'))

      setup_shell_integration

      logger.info('fzf installed successfully.')
    end

    private

    def setup_shell_integration
      # fzf 0.48.0+ supports --zsh, --bash flags for shell integration
      # Add shell integration source to .zshrc if not present
      zshrc_path = File.join(CONFIG.home, '.zshrc')
      
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
      
      File.open(zshrc_path, 'a') do |file|
        file.write(integration_line)
      end
    end
  end
end
