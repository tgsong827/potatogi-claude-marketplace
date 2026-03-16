---
name: auto-commit
description: Use this skill whenever the user wants to make a git commit — whether they say "커밋해줘", "commit 해줘", "커밋해", "변경사항 커밋해줘", "commit the changes", "stage and commit", or anything that implies creating a new commit. Also trigger when the user mentions a specific file or path and asks to commit it, e.g. "src/main.rs 커밋해줘" or "services/ 하위 파일들 커밋해줘". Do NOT trigger for git push, git status checks, undoing/reverting commits, git stash, branch operations, or staging-only requests where the user explicitly says they will commit themselves.
---

# Auto Commit

> **[필수 규칙]** 이 스킬은 반드시 `AskUserQuestion` 도구로 사용자의 확인을 받은 후에만 `git commit`을 실행한다. 확인 없이 커밋하는 것은 금지된다.

## 현재 Git 상태

- 브랜치: !`git branch --show-current 2>/dev/null || echo "git 저장소 아님"`
- 변경사항: !`git status --short 2>/dev/null || echo "없음"`
- 최근 커밋: !`git log --oneline -5 2>/dev/null || echo "없음"`

## 워크플로우

### 1단계: 변경사항 확인

위의 git status를 확인한다:
- 변경사항이 없으면 → "커밋할 변경사항이 없습니다." 출력 후 종료
- git 저장소가 아니면 → "현재 디렉토리가 git 저장소가 아닙니다." 출력 후 종료

### 2단계: 스테이징

사용자의 요청에서 특정 파일이나 경로가 명시되었는지 확인한다:
- **특정 파일/경로가 명시된 경우**: 해당 파일/경로만 스테이징한다 (`git add <path>...`)
- **명시되지 않은 경우**: 전체 변경사항을 스테이징한다 (`git add -A`)

다음 민감한 파일은 절대 스테이징하지 않는다:
- `.env`, `.env.*`, `.env.local`, `.env.*.local`
- `*.secret`, `*credentials*`, `*.pem`, `*.key`, `*.p12`

### 2.5단계: 보안 감사

`agents/security-auditor.md`의 내용을 instructions으로 전달하여 Agent tool로 subagent를 spawn한다.

subagent가 반환한 JSON 결과를 바탕으로:
- `severity: "none"` → 3단계로 진행
- `severity: "medium"` → AskUserQuestion으로 발견된 이슈 목록과 `summary`를 보여주고 진행 여부를 확인한다
- `severity: "high"` → AskUserQuestion으로 발견된 이슈 목록과 `summary`를 보여주고 커밋을 강력히 권고하지 않는다. 사용자가 명시적으로 무시(ignore)를 선택한 경우에만 3단계로 진행한다

### 3단계: 커밋 메시지 생성

스테이징된 변경사항(`git diff --staged`)과 최근 커밋 로그를 참고하여 메시지를 작성한다:
- 기존 커밋의 언어(한국어/영어)와 형식을 따른다
- Conventional Commits 권장: `type(scope): summary`

### 4단계: 사용자 확인 [이 단계는 절대 건너뛰지 않는다]

`AskUserQuestion` 도구를 호출하여 사용자의 승인을 받는다:

- **question**: `"아래 커밋 메시지로 커밋할까요?\n\n\`생성된 커밋 메시지\`"`
- **header**: `"커밋 확인"`
- **옵션 1**: `"커밋"` — 제안 메시지로 커밋 실행
- **옵션 2**: `"취소"` — 커밋 중단 (스테이징 유지)
- 메시지를 수정하려면 "Other"를 선택하여 직접 입력

### 5단계: 커밋 실행

- "커밋" 선택 시: `git commit -m "..."` 실행 후 결과 출력
- "취소" 선택 시: 스테이징 상태를 유지한 채 종료
- "Other"로 직접 입력 시: 입력된 메시지로 커밋
