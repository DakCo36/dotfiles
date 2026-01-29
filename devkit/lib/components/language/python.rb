# frozen_string_literal: true

require "singleton"
require "components/base"
require "mixins/installable"
require "mixins/loggable"

module Component
  class PythonComponent < BaseComponent

    prepend Installable

    # Fixed Python version to use
    PYTHON_VERSION = "3.12.8"

    # Python이 mise를 통해 사용 가능한지 확인합니다.
    #
    # @return [Boolean] 사용 가능하면 true, 아니면 false
    def available?
      system("mise", "which", "python", out: File::NULL, err: File::NULL)
    end

    # 현재 설치된 Python 버전을 반환합니다.
    #
    # @return [String, nil] 버전 문자열 (예: "3.12.8") 또는 nil
    def version
      output, status = Open3.capture2("mise", "current", "python")
      return nil unless status.success?

      output.strip.split.last
    rescue Errno::ENOENT
      nil
    end

    # Python이 설치되어 있는지 확인합니다.
    #
    # @return [Boolean] 설치되어 있으면 true, 아니면 false
    def installed?
      available? && !version.nil?
    end

    # 최신 버전을 반환합니다 (고정 버전 사용).
    #
    # @return [String] PYTHON_VERSION
    def latest_version
      PYTHON_VERSION
    end

    # Python을 설치합니다 (이미 설치되어 있으면 스킵).
    #
    # @return [void]
    def install
      if installed?
        logger.info("Python #{version} is already installed via mise.")
        return
      end
      install!
    end

    # Python을 mise를 통해 강제로 설치합니다.
    #
    # @return [void]
    def install!
      logger.info("Installing Python #{PYTHON_VERSION} via mise...")

      runCmd("mise", "use", "--global", "python@#{PYTHON_VERSION}")

      logger.info("Python #{PYTHON_VERSION} installed successfully via mise.")
    end

  end
end
