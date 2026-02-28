# frozen_string_literal: true

require "singleton"
require "fileutils"
require "components/installable_component"
require "components/configuration"
require "components/prerequisites/curl"
require "components/prerequisites/git"

module Component
  class TreesitterComponent < InstallableComponent

    TARGET_VERSION = "0.24.7"
    REPO_URL = "https://github.com/tree-sitter/tree-sitter.git"

    depends_on Component::GitComponent

    def version
      lib_path = File.join(config.local, "lib", "libtree-sitter.so")
      return nil unless File.exist?(lib_path)

      pc_path = File.join(config.local, "lib", "pkgconfig", "tree-sitter.pc")
      return nil unless File.exist?(pc_path)

      content = File.read(pc_path)
      match = content.match(/^Version:\s*(.+)$/)
      match ? match[1].strip : nil
    rescue StandardError
      nil
    end

    def installed?
      ver = version
      return false unless ver

      logger.info("tree-sitter #{ver} is installed locally")
      true
    end

    def latest_version
      TARGET_VERSION
    end

    protected

    def perform_install
      logger.info("Installing tree-sitter v#{TARGET_VERSION}")
      clone_source
      build_and_install
    end

    def post_install
      set_ld_library_path
    end

    private

    def clone_dir
      File.join(config.tmp, "tree-sitter")
    end

    def clone_source
      if Dir.exist?(clone_dir)
        logger.info("tree-sitter source already exists, pulling latest")
        withDir(clone_dir) do
          runCmd("git", "checkout", "v#{TARGET_VERSION}")
        end
      else
        runCmd("git", "clone", "--depth", "1", "--branch", "v#{TARGET_VERSION}", REPO_URL, clone_dir)
      end
    end

    def build_and_install
      withDir(clone_dir) do
        runCmd("make", "-j", make_jobs.to_s)
        runCmd("make", "install", "PREFIX=#{config.local}")
      end
      logger.info("tree-sitter v#{TARGET_VERSION} installed to #{config.local}")
    end

    LD_LIBRARY_MARKER = "LD_LIBRARY_PATH"

    def set_ld_library_path
      zprofile_path = config.zprofile
      FileUtils.touch(zprofile_path) unless File.exist?(zprofile_path)

      content = File.read(zprofile_path)
      if content.include?(LD_LIBRARY_MARKER)
        logger.info("LD_LIBRARY_PATH already configured in .zprofile, skipping")
        return
      end

      File.open(zprofile_path, "a") do |f|
        f.puts ""
        f.puts '# tree-sitter local library path'
        f.puts 'export LD_LIBRARY_PATH="$HOME/.local/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"'
      end
      logger.info("Added LD_LIBRARY_PATH to .zprofile")
    end

    def make_jobs
      require "etc"
      jobs = Etc.nprocessors / 2
      [jobs, 1].max
    end

  end
end
