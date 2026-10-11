# Shell 스크립트

install.sh은 Bash 를 이용하여 Ruby를 설치하는 스크립트와 관련 테스트를 포함합니다.

현재는 Ubuntu만 지원합니다.

## 설치 방법

다음 명령어를 실행하면 필요한 패키지와 Ruby가 설치됩니다.

```bash
./install.sh
```

실행하면 rbenv와 ruby-build에 필요한 라이브러리를 포함하여 설치하고, 지정된 버전(3.4.3)의 Ruby가 세팅됩니다.

## 테스트 실행

실제 Ruby 설치를 포함한 통합 테스트는 Docker 컨테이너 환경에서 시행됩니다. `setup/` 디렉토리에서 아래 스크립트를 실행합니다.

```bash
./docker-test.sh
# 캐시 없이 빌드
./docker-test.sh --no-cache
```
