# Oh My Posh 컴포넌트 구현 메모

## 작성 배경
- `Component::OhMyPoshComponent`를 추가해 Ubuntu/Linux 환경에서 Oh My Posh 프롬프트를 설치하는 기능을 Ruby 설치기 내부에 넣었습니다.
- 기존 Shell 컴포넌트(예: Oh My Zsh, Powerlevel10k 등)와 동일하게 `Installable` 믹스를 활용하는 설치 가능 컴포넌트 패턴을 따릅니다.

## 주요 파일
- `ruby/lib/components/shell/oh_my_posh.rb`: 설치 로직과 경로 정의를 포함한 컴포넌트 본체.
- `ruby/data/oh_my_posh/default.omp.json`: 기본 테마를 제공하는 샘플 자산.
- `ruby/spec/lib/components/shell/oh_my_posh_spec.rb`: 가용성/설치 여부/설치 흐름을 검증하는 RSpec.
- `ruby/README.md`: Linux 전용 지원과 바이너리·테마 배치 위치를 안내.

## 동작 방식
1. **설치 여부 판단**
   - 바이너리가 `$HOME/.local/bin/oh-my-posh`에 존재하고 실행 권한이 있으면 `available?`이 참입니다.
   - `available?`가 참이고 기본 테마(`$HOME/.poshthemes/default.omp.json`)가 있으면 `installed?`가 참입니다.
2. **설치 흐름 (`install`)**
   - 이미 설치되어 있으면 로그만 남기고 종료합니다.
   - 미설치 시 `install!`를 호출해 실제 작업을 수행합니다.
3. **실제 설치 (`install!`)**
   - `$HOME/.local/bin`을 준비한 후, GitHub 릴리스의 최신 Linux AMD64 바이너리를 `curl`로 임시 파일에 내려받습니다.
   - 임시 바이너리를 실행 가능하도록 이동/권한 부여합니다.
   - `ruby/data/oh_my_posh/default.omp.json`에 있는 기본 테마를 `$HOME/.poshthemes` 하위에 복사합니다.
   - 실패 시 예외를 로깅하고 재전파하며, 마지막에 임시 바이너리를 정리합니다.

## 테스트
- `ruby/spec/lib/components/shell/oh_my_posh_spec.rb`에서 가용성/설치 여부/설치 절차를 모의 객체로 검증합니다.
- 로컬 환경에서 실행할 때는 `bundle exec rspec`으로 테스트를 수행할 수 있습니다.

## 제약 및 메모
- 현재 구현은 Ubuntu/Linux(amd64) 다운로드만 다루며 Windows 설치는 범위에 포함하지 않았습니다.
- 테마 파일이 없으면 설치가 실패하도록 방어 로직이 포함되어 있습니다.
