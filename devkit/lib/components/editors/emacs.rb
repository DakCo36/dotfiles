# frozen_string_literal: true

require "singleton"
require "fileutils"
require "components/installable_component"
require "components/configuration"
require "components/prerequisites/curl"
require "components/prerequisites/tar"
require "components/editors/treesitter"

module Component
  class EmacsComponent < InstallableComponent

    TARGET_VERSION = "30.2"
    DOWNLOAD_URL = "https://ftp.gnu.org/gnu/emacs/emacs-#{TARGET_VERSION}.tar.xz"

    depends_on Component::CurlComponent
    depends_on Component::TarComponent
    depends_on Component::TreesitterComponent

    # Checks if emacs is available.
    #
    # @return [Boolean] true if available, false otherwise
    def available?
      system("emacs", "--version", out: File::NULL, err: File::NULL)
    end

    # Returns the current emacs version.
    #
    # @return [String, nil] Version string (e.g., "30.1")
    def version
      output, status = Open3.capture2("emacs", "--version")
      return nil unless status.success?

      # example: GNU Emacs 30.1
      match = output.match(/GNU Emacs ([\d.]+)/)
      match ? match[1] : nil
    rescue Errno::ENOENT
      nil
    end

    # Checks if emacs is installed locally.
    #
    # @return [Boolean] true if installed, false otherwise
    def installed?
      local_emacs_path = File.join(config.bin, "emacs")
      is_in_path = ENV["PATH"]
                   &.to_s
                   &.split(":")
                   &.any? { |path| path == config.bin }

      if is_in_path && File.exist?(local_emacs_path) && File.executable?(local_emacs_path)
        logger.info("Emacs is installed locally at #{local_emacs_path}")
        return true
      end

      logger.info("Emacs is not installed")
      false
    end

    # Returns the latest version (hardcoded for now).
    #
    # @return [String] TARGET_VERSION
    def latest_version
      TARGET_VERSION
    end

    protected

    def perform_install
      logger.info("Installing Emacs version #{TARGET_VERSION}")
      curl.download(DOWNLOAD_URL, tmp_file_path)
      logger.info("Extracting #{tmp_file_path} to #{tmp_dir_path}")
      runCmd("tar", "-xf", tmp_file_path, "-C", File.dirname(tmp_file_path))
      configure_and_make
    end

    def post_install
      append_to_zshrc
    end

    private

    # @return [String]
    def tmp_file_path
      File.join(config.tmp, "emacs-#{TARGET_VERSION}.tar.xz")
    end

    # @return [String]
    def tmp_dir_path
      File.join(config.tmp, "emacs-#{TARGET_VERSION}")
    end

    def configure_and_make
      logger.info("Configuring Emacs")
      withDir(tmp_dir_path) do
        configure_args = [
          "./configure",
          "--prefix", config.local,
          "--with-gnutls=ifavailable",
          "--with-tree-sitter"
        ]
        unless x_dev_available?
          logger.info("X development libraries not found, building without X support")
          configure_args << "--without-x"
        end
        env = build_env
        runCmd(*configure_args, env: env, showStdout: true)
        runCmd("make", "-j", make_jobs.to_s, env: env)
        runCmd("make", "install", env: env)
      end
      logger.info("Emacs installed successfully.")
    end

    def x_dev_available?
      system("pkg-config", "--exists", "x11", out: File::NULL, err: File::NULL)
    end

    def build_env
      local_pkgconfig = File.join(config.local, "lib", "pkgconfig")
      local_include = File.join(config.local, "include")
      local_lib = File.join(config.local, "lib")

      existing_pkg = ENV.fetch("PKG_CONFIG_PATH", "")
      existing_cflags = ENV.fetch("CFLAGS", "")
      existing_ldflags = ENV.fetch("LDFLAGS", "")
      existing_ld_library_path = ENV.fetch("LD_LIBRARY_PATH", "")

      {
        "PKG_CONFIG_PATH" => existing_pkg.empty? ? local_pkgconfig : "#{local_pkgconfig}:#{existing_pkg}",
        "CFLAGS" => "-I#{local_include} #{existing_cflags}".strip,
        "LDFLAGS" => "-L#{local_lib} #{existing_ldflags}".strip,
        "LD_LIBRARY_PATH" => existing_ld_library_path.empty? ? local_lib : "#{local_lib}:#{existing_ld_library_path}"
      }
    end

    def make_jobs
      require "etc"
      jobs = Etc.nprocessors / 2
      [jobs, 1].max
    end

    VTERM_MARKER = "INSIDE_EMACS"

    def append_to_zshrc
      zshrc_path = File.join(config.home, ".zshrc")
      unless File.exist?(zshrc_path)
        logger.warn(".zshrc not found, skipping vterm shell configuration")
        return
      end

      content = File.read(zshrc_path)
      if content.include?(VTERM_MARKER)
        logger.debug("vterm P10k override already configured in .zshrc, skipping")
        return
      end

      File.open(zshrc_path, "a") do |f|
        f.puts ""
        f.puts '# Emacs vterm - disable P10k right prompt and gap line'
        f.puts 'if [[ "$INSIDE_EMACS" = "vterm" ]]; then'
        f.puts "  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=()"
        f.puts "  typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_CHAR=' '"
        f.puts "fi"
      end
      logger.info("Added vterm P10k override to .zshrc")
    end

  end
end
