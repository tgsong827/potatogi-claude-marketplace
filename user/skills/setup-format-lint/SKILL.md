---
name: setup-format-lint
description: 현재 프로젝트의 포맷/린트 도구를 감지하여 프로젝트 전용 format-and-lint 스킬을 자동 생성한다. "포맷 린트 스킬 만들어줘", "린트 설정해줘", "format lint 세팅", "setup format lint", "프로젝트 린트 스킬 생성" 등의 요청에 사용한다. package.json의 scripts나 Cargo.toml이 있는 프로젝트에서 동작한다.
---

# Setup Format & Lint

현재 프로젝트의 포맷/린트 도구를 감지하고, 프로젝트 전용 `format-and-lint` 스킬을 자동 생성한다.
생성된 스킬은 독립적으로 호출하거나, auto-commit 스킬에서 커밋 전 자동으로 연동된다.

## 프로젝트 탐색

- 프로젝트 루트: !`pwd`
- package.json: !`test -f package.json && echo "found" || echo "not_found"`
- Cargo.toml: !`test -f Cargo.toml && echo "found" || echo "not_found"`
- package.json scripts: !`cat package.json 2>/dev/null | jq -r '.scripts // {} | to_entries[] | "\(.key): \(.value)"' 2>/dev/null || echo "none"`
- 패키지 매니저: !`test -f bun.lockb && echo "bun" || (test -f pnpm-lock.yaml && echo "pnpm" || (test -f yarn.lock && echo "yarn" || echo "npm"))`
- 기존 스킬 유무: !`test -f .claude/skills/format-and-lint/SKILL.md && echo "exists" || echo "not_found"`

## 워크플로우

### 1단계: 감지 가능 여부 확인

위의 탐색 결과를 확인한다:
- `package.json`과 `Cargo.toml` 둘 다 없으면 → "지원하는 프로젝트 설정 파일(package.json, Cargo.toml)을 찾을 수 없습니다." 출력 후 종료
- 기존 스킬이 이미 있으면 → `AskUserQuestion`으로 덮어쓸지 확인. 취소 시 종료

### 2단계: 명령 후보 수집

**package.json이 있는 경우:**

scripts에서 다음 키워드를 포함하는 항목을 추출한다:
- 포맷 계열: `format`, `fmt`, `prettier`
- 린트 계열: `lint`, `eslint`, `biome`, `stylelint`
- fix 변형도 포함: `lint:fix`, `format:fix`, `lint-fix` 등

각 항목을 감지된 패키지 매니저로 명령어를 구성한다:
- 예: script key가 `format`이고 패키지 매니저가 `pnpm`이면 → `pnpm run format`

같은 계열의 변형이 여러 개 있으면 (예: `lint`와 `lint:fix`) 모두 후보에 포함하고, 3단계에서 사용자가 선택하도록 한다.

**Cargo.toml이 있는 경우:**

다음을 후보로 추가한다:
- `cargo fmt` — 코드 포맷팅
- `cargo clippy --fix --allow-dirty` — 린트 자동 수정

**두 설정 파일이 모두 있는 경우:**

양쪽 후보를 모두 수집한다.

### 3단계: 사용자 확인

수집된 명령 후보를 `AskUserQuestion`으로 보여준다:

- **header**: "포맷/린트 스킬 생성"
- **question**: 아래 형식으로 작성

```
다음 포맷/린트 명령을 감지했습니다:

1. pnpm run format — 코드 포맷팅
2. pnpm run lint:fix — 린트 자동 수정
3. cargo fmt — Rust 포맷팅

이 명령들로 format-and-lint 스킬을 생성할까요?
제외할 항목이 있다면 번호를 입력해주세요.
```

- **옵션**: "전체 포함" / "취소"
- Other로 번호 입력 시 해당 항목을 제외

후보가 하나도 없으면:
"포맷/린트 관련 스크립트를 찾을 수 없습니다. package.json scripts에 format/lint 명령을 추가한 후 다시 시도해주세요." 출력 후 종료

### 4단계: 스킬 파일 생성

`.claude/skills/format-and-lint/SKILL.md`를 프로젝트 루트에 생성한다.

아래 템플릿의 `{{변수}}`를 실제 값으로 치환한다:

```markdown
---
name: format-and-lint
description: 이 프로젝트의 포맷/린트 도구를 실행한다. "포맷 돌려줘", "린트 해줘", "format", "lint", "코드 정리" 등의 요청에 사용한다. auto-commit 스킬에서 커밋 전 자동으로 호출되기도 한다.
---

# Format and Lint

이 프로젝트에서 사용하는 포맷/린트 명령을 실행한다.

## 명령 목록

| 순서 | 명령 | 용도 |
|------|------|------|
{{명령 테이블 행}}

## 워크플로우

### 1단계: 실행 확인

`AskUserQuestion`으로 실행 여부를 확인한다:

- **header**: "포맷/린트 실행"
- **question**: "다음 명령을 실행할까요?\n\n{{명령 목록 텍스트}}"
- **옵션**: "실행" / "건너뛰기"

### 2단계: 명령 실행

실행 전 `git diff --stat`의 결과를 저장해둔다.

승인 시 명령을 순서대로 실행한다.
각 명령의 exit code를 확인하고, 실패 시 에러 내용을 출력하되 다음 명령은 계속 실행한다.

### 3단계: 결과 보고

실행 후 `git diff --stat`의 결과를 2단계에서 저장한 결과와 비교하여, 포맷/린트로 인해 새로 변경된 파일만 보여준다.
새로 변경된 파일이 없으면 "포맷/린트 변경사항 없음"으로 간략히 알린다.
```

### 5단계: 완료 안내

생성 결과를 알린다:
- 생성된 경로: `.claude/skills/format-and-lint/SKILL.md`
- "이제 `커밋해줘` 시 자동으로 포맷/린트 확인이 포함됩니다"
- "직접 실행하려면 `포맷 돌려줘` 또는 `린트 해줘`라고 말하세요"
- `.gitignore`에 `.claude/skills/`가 포함되어 있지 않다면, 이 스킬을 git에 커밋하여 팀원과 공유할 수 있다는 점도 안내한다
