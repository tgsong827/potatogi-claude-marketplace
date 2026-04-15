---
name: mac-uninstaller
description: "사용자가 macOS에서 앱/프로그램/CLI 도구를 삭제하려 할 때 사용한다. \"Chrome 삭제해줘\", \"brew로 설치한 node 지워줘\", \"uninstall Slack\", \"앱 지워줘\", \"프로그램 삭제\", \"클린 삭제\", \"앱 정리\", \"remove app\" 등의 요청에 트리거된다. Do NOT trigger for file deletion, directory cleanup, or disk cleanup requests that don't target a specific app/program."
---

# Mac Uninstaller

> **[필수 규칙]** 이 스킬은 반드시 `AskUserQuestion` 도구로 사용자의 확인을 받은 후에만 삭제/종료 작업을 실행한다. 확인 없이 삭제하거나 프로세스를 종료하는 것은 금지된다.

## 워크플로우

### 1단계: 대상 식별

사용자가 요청한 앱/프로그램 이름을 기반으로 아래 소스를 순서대로 탐색한다. 각 패키지 매니저는 `command -v`로 설치 여부를 먼저 확인하고, 없으면 건너뛴다. 모든 검색은 대소문자 무시(case-insensitive), 부분 일치(partial match)로 수행한다.

1. **.app 번들**: `find /Applications ~/Applications -maxdepth 2 -name "*.app" | grep -i "<name>"`
2. **Homebrew cask**: `brew list --cask | grep -i "<name>"`
3. **Homebrew formula**: `brew list --formula | grep -i "<name>"`
4. **Mac App Store**: `mas list | grep -i "<name>"`
5. **npm global**: `npm list -g --depth=0 | grep -i "<name>"`
6. **cargo**: `cargo install --list | grep -i "<name>"`
7. **pip/pipx**: `pip list | grep -i "<name>"` 및 `pipx list | grep -i "<name>"`
8. **go**: `ls ~/go/bin/ | grep -i "<name>"`
9. **gem**: `gem list | grep -i "<name>"`
10. **CLI binary (fallback)**: `which <name>`

결과에 따라:

- **0건** → "해당 이름의 앱/프로그램을 찾을 수 없습니다." 출력 후 종료
- **1건** → 2단계로 진행
- **2건 이상** → `AskUserQuestion`으로 목록을 보여주고 선택받는다 (multiSelect: true)

### 2단계: 실행 상태 확인 & 종료

`pgrep -fi "<name>"`으로 실행 중인 프로세스를 확인한다.

- **실행 중이 아닌 경우** → 3단계로 진행
- **실행 중인 경우** → `AskUserQuestion`으로 확인:
  - **"종료 후 계속"** → 아래 순서로 종료 시도:
    1. `osascript -e 'tell application "<name>" to quit'` (graceful quit)
    2. 3초 대기 후 아직 실행 중이면 → `kill <pid>`
    3. 2초 대기 후 아직 실행 중이면 → `kill -9 <pid>`
  - **"취소"** → 작업 중단

### 3단계: 잔여 파일 탐색

#### 3-1. 번들 ID 추출

.app 번들이 있는 경우 번들 ID를 추출한다:

```bash
mdls -name kMDItemCFBundleIdentifier -raw "<app-path>"
```

실패 시 fallback:

```bash
defaults read "<app-path>/Contents/Info.plist" CFBundleIdentifier
```

#### 3-2. 잔여 파일 스캔

앱 이름과 번들 ID 양쪽으로 아래 경로들을 탐색한다:

**User-level:**
- `~/Library/Application Support/`
- `~/Library/Caches/`
- `~/Library/Preferences/`
- `~/Library/Logs/`
- `~/Library/Saved Application State/`
- `~/Library/HTTPStorages/`
- `~/Library/WebKit/`
- `~/Library/Containers/`
- `~/Library/Group Containers/`
- `~/Library/LaunchAgents/`

**System-level:**
- `/Library/Application Support/`
- `/Library/Preferences/`
- `/Library/LaunchAgents/`
- `/Library/LaunchDaemons/`

#### 3-3. Spotlight 검색

```bash
mdfind "kMDItemCFBundleIdentifier == '<bundle-id>'"
mdfind -onlyin "$HOME" -name "<name>"
```

mdfind 결과에서 `/System/`, `/usr/`, `/bin/`, `/sbin/` 경로는 제외한다.

#### 3-4. 패키지 매니저 경로

설치 소스에 따라 해당 경로도 포함한다:
- Homebrew: `brew --prefix` 하위 경로
- npm: `npm root -g` 하위 경로
- cargo: `~/.cargo/bin/`
- pip: `pip show <name>`의 Location 경로
- go: `~/go/bin/`
- gem: `gem contents <name>`

#### 3-5. 중복 제거

모든 결과를 합치고 중복을 제거한다.

### 4단계: 삭제 계획 제시 & 확인

발견된 파일을 카테고리별로 분류하여 보여준다:

| 카테고리 | 설명 |
|---------|------|
| 앱 본체 | .app 번들 또는 바이너리 |
| 캐시/로그 | Caches, Logs, HTTPStorages |
| 설정 | Preferences, Application Support, Saved Application State |
| LaunchAgent/Daemon | LaunchAgents, LaunchDaemons |
| 패키지 매니저 | brew, npm, cargo, pip, go, gem 관리 항목 |

각 항목의 크기를 `du -sh`로 표시한다.

`AskUserQuestion`으로 삭제 방법을 선택받는다:

- **"휴지통으로 이동"** (기본) — 안전한 삭제, 복구 가능
- **"완전 삭제 (rm)"** — 영구 삭제, 복구 불가
- **"취소"** — 작업 중단

### 5단계: 삭제 실행

#### 패키지 매니저 항목

각 패키지 매니저의 네이티브 삭제 명령을 사용한다:

- Homebrew cask: `brew uninstall --cask <name>`
- Homebrew formula: `brew uninstall <name>`
- Mac App Store: `mas uninstall <app-id>`
- npm: `npm uninstall -g <name>`
- cargo: `cargo uninstall <name>`
- pip: `pip uninstall -y <name>`
- pipx: `pipx uninstall <name>`
- gem: `gem uninstall -x <name>`
- go: go 바이너리는 uninstall 명령이 없으므로 직접 파일 삭제

#### 잔여 파일 — 휴지통으로 이동

`trash` 명령이 있으면 사용하고, 없으면 fallback:

```bash
osascript -e "tell application \"Finder\" to delete (POSIX file \"<path>\" as alias)"
```

#### 잔여 파일 — 완전 삭제

```bash
rm -rf "<path>"
```

#### /Library/ 파일 권한 처리

`/Library/` 하위 파일은 먼저 sudo 없이 삭제를 시도한다. 권한 오류 발생 시 `AskUserQuestion`으로 sudo 사용 여부를 확인한다.

### 6단계: 결과 보고

삭제 결과를 정리하여 보고한다:

- 삭제된 항목 목록: 각 항목의 삭제 방법 (trash/rm/uninstall)과 크기
- 총 확보된 공간
- 실패한 항목이 있으면: 항목명과 실패 사유

## 안전장치

1. **시스템 앱 보호**: `/System/` 하위 앱은 삭제를 차단하고 경고 메시지를 출력한다.
2. **위험 경로 차단**: 다음 경로는 절대 `rm` 대상에 포함하지 않는다:
   - `/`
   - `/System`
   - `/usr`
   - `/bin`
   - `/sbin`
   - `/var`
   - `$HOME` 자체 (홈 디렉토리 루트)
   - `/Applications` 자체 (Applications 디렉토리 루트)
3. **사용자 확인 필수**: 모든 삭제 및 프로세스 종료 작업 전에 반드시 `AskUserQuestion`으로 확인을 받는다.
4. **의존성 경고**: 패키지 매니저가 의존성 경고를 출력하면 그대로 사용자에게 전달한다.
