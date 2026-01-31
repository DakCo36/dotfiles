require "components/base"
require "mixins/configurable"
require "mixins/installable"

module Component
  # Base class for components that can be installed and managed via devkit.
  #
  # InstallableComponent provides the foundation for all devkit-managed
  # packages (e.g., fzf, neovim, zsh). They:
  # - Have install! method for installation
  # - Use Configurable mixin for reading devkit.toml settings
  # - Use Installable mixin for dependency management
  # - Can check upgradability and perform updates
  #
  class InstallableComponent < BaseComponent

    include Configurable
    prepend Installable

    # Checks if the component is installed.
    #
    # @return [Boolean] true if installed
    # @raise [NotImplementedError] if not implemented by subclass
    def installed?
      raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
    end

    # Performs the actual installation of the component.
    #
    # @raise [NotImplementedError] if not implemented by subclass
    def install!
      raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
    end

    # Returns the latest available version.
    #
    # @return [String, nil] latest version string or nil on failure
    # @raise [NotImplementedError] if not implemented by subclass
    def latest_version
      raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
    end

    # 버전 문자열을 GitHub 태그 형식으로 변환합니다.
    # 기본적으로 그대로 반환하며, 서브클래스에서 오버라이드 가능합니다.
    #
    # @param ver [String] 버전 문자열
    # @return [String] GitHub 릴리스 태그
    def version_tag(ver)
      ver
    end

    # Checks if a newer version is available.
    #
    # @return [Boolean] true if upgradable
    def upgradable?
      return false unless installed?

      current = version
      latest = latest_version
      return false if current.nil? || latest.nil?

      current_clean = current.to_s.gsub(/^v/, "")
      latest_clean = latest.to_s.gsub(/^v/, "")

      begin
        Gem::Version.new(latest_clean) > Gem::Version.new(current_clean)
      rescue ArgumentError
        latest_clean != current_clean
      end
    end

    # Updates the component if a newer version is available.
    def update
      if upgradable?
        logger.info("Updating #{self.class.name}...")
        install!
      else
        logger.info("#{self.class.name} is already up to date.")
      end
    end

  end
end
