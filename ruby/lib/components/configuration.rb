require "singleton"
require "tmpdir"

module Components
  class Configuration

    include Singleton

    attr_accessor :home, :local, :bin, :tmp, :bashrc, :bash_profile, :bash_completions, :zshrc, :zsh_profile,
                  :zsh_completions, :man1

    def initialize
      @home = Dir.home
      @local = Dir.home + "/.local"
      @bin = local + "/bin"
      @tmp = Dir.tmpdir + "/" + generateTimestamp
      @bashrc = File.join(home, ".bashrc")
      @bash_profile = File.join(home, ".bash_profile")
      @bash_completions = File.join(home, ".local", "share", "bash-completion", "completions")
      @zshrc = File.join(home, ".zshrc")
      @zsh_profile = File.join(home, ".zsh_profile")
      @zsh_completions = File.join(home, ".local", "share", "zsh", "site-functions")
      @man1 = File.join(home, ".local", "share", "man", "man1")

      FileUtils.mkdir_p(@tmp) unless Dir.exist?(@tmp)
    end

    def contract_path(path)
      if path.is_a?(String) && path.start_with?(@home)
        path.sub(@home, "$HOME")
      else
        path
      end
    end

    private

    def generateTimestamp
      Time.now.strftime("%Y%m%d_%H%M%S")
    end

  end
end
