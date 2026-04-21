---
name: issue-shaping
description: 개발 시작 전 issue spec을 shaping하여 GitHub issue로 생성. "이슈 만들어줘", "issue shape", "이슈 작성", "shape this", "새 이슈", "버그 리포트 만들어줘", "기능 요청 이슈" 등 GitHub issue를 shaping/생성하려는 요청에 트리거. 이미 있는 issue 수정/닫기, PR 생성, commit/push 요청에는 트리거하지 않음.
---

# Issue Shaping

> **[필수 규칙]** 이 스킬은 반드시 `AskUserQuestion` 도구로 사용자의 최종 확인을 받은 후에만 `gh issue create`를 실행한다. 확인 없이 issue를 생성하는 것은 금지된다.

## 현재 컨텍스트

- 브랜치: !`git branch --show-current 2>/dev/null || echo "git 저장소 아님"`
- Remote: !`git remote get-url origin 2>/dev/null || echo "none"`
- GitHub 인증: !`gh auth status 2>&1 | head -1`
- Template 개수: !`ls .github/ISSUE_TEMPLATE/*.md 2>/dev/null | wc -l | awk '{$1=$1};1'`

## 워크플로우

### 1단계: 사전 검증

_(Task 2에서 작성)_

### 2단계: Template 탐지 및 선택

_(Task 3에서 작성)_

### 3단계: Draft 작성 및 Review

_(Task 4에서 작성)_

### 4단계: 메타데이터 및 최종 승인

_(Task 5에서 작성)_

### 5단계: Issue 생성

_(Task 6에서 작성)_

## 오류 처리

_(Task 6에서 작성)_
