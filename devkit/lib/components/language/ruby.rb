# frozen_string_literal: true

require "singleton"
require "components/installable_component"
require "components/configuration"
require "mixins/loggable"

module Component
  class RubyComponent < InstallableComponent

    # Fixed ruby version to use
    TARGET_VERSION = "4.0.1"

    # Return the current ruby version.
    # 
    # @return [String, nil] version string (e.g. "4.0.6") or nil
    def version
      output, status = Open3.capture2("mise", "current", "ruby")
      return nil unless status.success?

      output.strip.split.last
    rescue Errno::ENOENT
      nil
    end

    # Check if ruby is installed
    # 
    # @return [Boolean] true if installed, false otherwise
    def installed?
      !version.nil?
    end

    # Returns the latest version (uses fixed version)
    # 
    # @return [String] RUBY_VERSION
    def latest_version
      TARGET_VERSION
    end

    protected

    # Installs ruby via mise
    # 
    # @return [void]
    def perform_install
      logger.info("Installing ruby #{TARGET_VERSION} via mise...")

      Bundler.with_unbundled_env do
        runCmd("mise", "use", "--global", "ruby@#{TARGET_VERSION}")
      end

      logger.info("ruby #{TARGET_VERSION} installed successfully via mise.")
    end

    # After installing ruby, install axilliary tools
    # 
    # @return [void]
    def post_install
      install_ruby_lsp
    end

    # Install ruby-lsp
    #
    # @return [void]
    def install_ruby_lsp
      logger.info("Installing ruby-lsp via gem...")
      Bundler.with_unbundled_env do
        runCmd("gem", "install", "ruby-lsp")
      end
      logger.info("Installed ruby-lsp.")
    end
  end
end