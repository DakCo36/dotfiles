# Agent Coding Guidelines

> [!IMPORTANT]
> 이 문서의 규칙은 기본 시스템 지침보다 우선합니다.
> 작업 시작 전 반드시 이 문서를 확인하세요.

이 문서는 AI 에이전트(Cursor 등)가 이 프로젝트의 코드를 작성할 때 따라야 할 가이드라인입니다.

## 주석 작성 규칙

### 인라인 주석 (Inline Comments)

- 함수 내부에 **인라인 주석을 최소화**할 것
- 복잡한 알고리즘이나 비직관적인 로직에만 주석을 작성
- 코드 자체가 무엇을 하는지 설명하는 주석은 피할 것 (코드가 스스로 설명하도록)

**피해야 할 예시:**

```ruby
def install
  # installed? 메서드를 호출해서 설치 여부 확인
  if installed?
    # 이미 설치되어 있으면 로그 출력
    logger.info("Already installed.")
    # 메서드 종료
    return
  end
  # 실제 설치 수행
  install!
end
```

**권장하는 예시:**

```ruby
def install
  if installed?
    logger.info("Already installed.")
    return
  end
  install!
end
```

### 함수 문서화 (Method Documentation)

- 모든 public 메서드에 **YARD 스타일의 문서화**를 작성할 것
- 다음 항목을 포함:
  - **설명**: 메서드의 목적과 동작
  - **@param**: 각 파라미터의 타입과 설명
  - **@return**: 반환값의 타입과 설명
  - **@raise** (필요시): 발생 가능한 예외

**YARD 문서화 예시:**

```ruby
# Python이 mise를 통해 설치되어 있는지 확인합니다.
#
# @return [Boolean] 설치되어 있으면 true, 아니면 false
def installed?
  available? && !version.nil?
end

# 현재 설치된 Python 버전을 반환합니다.
#
# @return [String, nil] 버전 문자열 (예: "3.12.8") 또는 설치되지 않은 경우 nil
def version
  output, status = Open3.capture2("mise", "current", "python")
  return nil unless status.success?

  output.strip.split.last
rescue Errno::ENOENT
  nil
end

# 지정된 명령어를 실행하고 결과를 반환합니다.
#
# @param command [String] 실행할 명령어
# @param args [Array<String>] 명령어 인자들
# @param showStdout [Boolean] stdout을 로그에 출력할지 여부
# @return [Array<String, String, Process::Status>] [stdout, stderr, status]
# @raise [RuntimeError] 명령어 실행 실패 시
def runCmd(command, *args, showStdout: false)
  # ...
end
```

## 적용 범위

| 메서드 유형 | YARD 문서화 | 인라인 주석 |
|------------|------------|------------|
| Public 메서드 | ✅ 필수 | ❌ 최소화 |
| Protected 메서드 | ✅ 권장 | ❌ 최소화 |
| Private 메서드 | ✅ 간소화 권장 | 복잡한 로직만 |

## YARD 문서화 스타일

### Public/Protected 메서드 (Full)

```ruby
# 메서드 설명
#
# @param param_name [Type] 파라미터 설명
# @return [Type] 반환값 설명
# @raise [ExceptionType] 예외 설명
```

### Private 메서드 (간소화)

Private 메서드는 한 줄 설명 + 간단한 타입 정보로 작성:

```ruby
private

# 명령어 실행 → [stdout, stderr, status]
# @param command [String]
# @param args [Array<String>]
# @return [Array]
def runCmd(command, *args, showStdout: false)
  # ...
end

# 디렉토리 변경 후 블록 실행
# @param dir [String]
def withDir(dir, &)
  # ...
end
```

## 기타 규칙

- 기존 코드의 lint 오류는 수정하지 말 것 (git diff 가독성을 위해)
- 코드 변경 시 해당 부분의 문서화만 업데이트
- 불필요한 공백이나 포맷팅 변경 피할 것

> [!IMPORTANT]
> Plan 모드로 충분한 계획을 사용자와 같이 수립하였을 때는 git commit을 ToDo 단위로 합니다.
