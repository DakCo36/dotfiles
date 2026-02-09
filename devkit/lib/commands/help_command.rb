require "optparse"
require "commands/utils/registry"

module Commands
  class HelpCommand

    def initialize
      @registry = Commands::Registry.instance
    end

    def execute
      puts option_parser
    end

    def parse_options!(args)
      option_parser.parse!(args)
    rescue OptionParser::InvalidOption => e
      puts "오류: #{e.message}"
      puts option_parser
      exit 1
    end

    def option_parser
      registry = @registry
      @option_parser ||= OptionParser.new do |opts|
        opts.banner = "dotfiles CLI - 컴포넌트 설치 및 관리 도구\n\n" \
                      "사용법: ruby bin/cli.rb <command> [options] [components...]\n\n" \
                      "명령어:\n  " \
                      "install   컴포넌트를 설치합니다\n  " \
                      "update    설치된 컴포넌트를 업데이트합니다\n  " \
                      "help      이 도움말을 표시합니다\n\n" \
                      "옵션:"

        opts.on("-y", "--yes", "확인 없이 바로 실행합니다") {}
        opts.on("-n", "--dry-run", "설치하지 않고 계획만 표시합니다") {}
        opts.on("-f", "--force", "이미 설치된 컴포넌트도 재설치합니다") {}
        opts.on("-h", "--help", "도움말을 표시합니다") { puts opts; exit }

        opts.separator ""
        opts.separator "예시:"
        opts.separator "  ruby bin/cli.rb install              # 모든 미설치 컴포넌트 설치"
        opts.separator "  ruby bin/cli.rb install --yes        # 확인 없이 설치"
        opts.separator "  ruby bin/cli.rb install --dry-run    # 설치 계획만 확인"
        opts.separator "  ruby bin/cli.rb install bat fzf      # bat, fzf만 설치"
        opts.separator "  ruby bin/cli.rb install --force      # 모든 컴포넌트 재설치"
        opts.separator "  ruby bin/cli.rb install --force bat  # bat 재설치"
        opts.separator "  ruby bin/cli.rb update               # 설치된 컴포넌트 업데이트"
        opts.separator "  ruby bin/cli.rb update --dry-run     # 업데이트 계획만 확인"
        opts.separator ""
        opts.separator "사용 가능한 컴포넌트:"
        opts.separator "  #{registry.component_names.join(", ")}"
      end
    end

  end
end
