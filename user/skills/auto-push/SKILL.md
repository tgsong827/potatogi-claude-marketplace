---
name: auto-push
description: Use this skill whenever the user wants to push commits to a remote repository — whether they say "푸시해줘", "push해줘", "origin에 올려줘", "올려줘", "원격에 반영해줘", "push the changes", "push to origin", "git push", or anything implying uploading local commits to a remote. Also trigger when the user says things like "커밋하고 올려줘" (after the commit part is done) or "배포 브랜치에 올려줘". Do NOT trigger for commit-only requests, pull/fetch/merge operations, or staging-only requests.
---

# Auto Push

> **[필수 규칙]** 이 스킬은 반드시 `AskUserQuestion` 도구로 사용자의 확인을 받은 후에만 `git push`를 실행한다. 확인 없이 푸시하는 것은 금지된다.

## 현재 Git 상태

- 브랜치: !`git branch --show-current 2>/dev/null || echo "git 저장소 아님"`
- 리모트 상태: !`git status -sb 2>/dev/null | head -1 || echo "없음"`
- 로컬/리모트 커밋 차이: !`git log --oneline @{u}..HEAD 2>/dev/null || echo "upstream 미설정"`

## 워크플로우

### 1단계: 저장소 및 브랜치 확인

위의 상태 정보를 바탕으로 확인한다:
- git 저장소가 아니면 → "현재 디렉토리가 git 저장소가 아닙니다." 출력 후 종료
- 푸시할 커밋이 없으면 (로컬과 리모트가 동일하면) → "푸시할 커밋이 없습니다. (리모트와 동일한 상태)" 출력 후 종료

### 2단계: main/master 브랜치 경고

현재 브랜치가 `main` 또는 `master`인 경우:
- 경고 메시지를 확인 질문에 포함한다: `"⚠️ 현재 main/master 브랜치에 직접 푸시하려 합니다."`
- 중단하지 않고 4단계 확인 질문으로 넘어간다 (사용자가 판단하도록)

### 3단계: upstream 설정 여부 확인

`git rev-parse --abbrev-ref @{u} 2>/dev/null` 로 upstream 설정 여부를 확인한다:
- **upstream이 설정된 경우**: `git push origin <현재브랜치>` 사용
- **upstream이 미설정된 경우**: `git push -u origin <현재브랜치>` 사용
  - 확인 질문에 "upstream이 설정되지 않아 `-u origin <브랜치>` 옵션으로 푸시합니다." 안내 포함

remote와 branch를 항상 명시하는 이유: 실수로 다른 remote에 푸시되는 것을 방지하고, 실행될 명령을 사용자가 정확히 확인할 수 있다.

### 4단계: 사용자 확인 [이 단계는 절대 건너뛰지 않는다]

`AskUserQuestion` 도구를 호출하여 사용자의 승인을 받는다:

- **header**: `"푸시 확인"`
- **question**: 아래 형식으로 현재 상태를 포함하여 작성

```
다음 내용으로 푸시할까요?

브랜치: <현재 브랜치> → origin/<브랜치>
푸시할 커밋 (<N>개):
  - <커밋 해시> <커밋 메시지>
  - ...

[main/master 경고 또는 upstream 안내가 있으면 여기 포함]
```

- **옵션 1**: `"푸시"` — 실행
- **옵션 2**: `"취소"` — 중단

### 5단계: 푸시 실행

- "푸시" 선택 시: 3단계에서 결정한 명령어로 푸시 실행 후 결과 출력
- "취소" 선택 시: "푸시를 취소했습니다." 출력 후 종료
