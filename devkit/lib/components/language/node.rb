# frozen_string_literal: true

require "singleton"
require "components/base"
require "mixins/installable"
require "mixins/loggable"

module Component
  class NodeComponent < BaseComponent

    prepend Installable

    # Fixed Node.js version to use (LTS Krypton)
    NODE_VERSION = "24.13.0"

    # Node.js가 mise를 통해 사용 가능한지 확인합니다.
    #
    # @return [Boolean] 사용 가능하면 true, 아니면 false
    def available?
      system("mise", "which", "node", out: File::NULL, err: File::NULL)
    end

    # 현재 설치된 Node.js 버전을 반환합니다.
    #
    # @return [String, nil] 버전 문자열 (예: "24.13.0") 또는 nil
    def version
      output, status = Open3.capture2("mise", "current", "node")
      return nil unless status.success?

      output.strip.split.last
    rescue Errno::ENOENT
      nil
    end

    # Node.js가 설치되어 있는지 확인합니다.
    #
    # @return [Boolean] 설치되어 있으면 true, 아니면 false
    def installed?
      available? && !version.nil?
    end

    # 최신 버전을 반환합니다 (고정 버전 사용).
    #
    # @return [String] NODE_VERSION
    def latest_version
      NODE_VERSION
    end

    # Node.js를 설치합니다 (이미 설치되어 있으면 스킵).
    #
    # @return [void]
    def install
      if installed?
        logger.info("Node.js #{version} is already installed via mise.")
        return
      end
      install!
    end

    # Node.js를 mise를 통해 강제로 설치합니다.
    #
    # @return [void]
    def install!
      logger.info("Installing Node.js #{NODE_VERSION} via mise...")

      runCmd("mise", "use", "--global", "node@#{NODE_VERSION}")

      logger.info("Node.js #{NODE_VERSION} installed successfully via mise.")
    end

  end
end
