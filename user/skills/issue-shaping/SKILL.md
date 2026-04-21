---
name: issue-shaping
description: 개발 시작 전 issue spec을 shaping하여 GitHub issue로 생성. "이슈 만들어줘", "issue shape", "이슈 작성", "shape this", "새 이슈", "버그 리포트 만들어줘", "기능 요청 이슈" 등 GitHub issue를 shaping/생성하려는 요청에 트리거. 이미 있는 issue 수정/닫기, PR 생성, commit/push 요청에는 트리거하지 않음.
---

# Issue Shaping

> **[필수 규칙]** 이 스킬은 반드시 `AskUserQuestion` 도구로 사용자의 최종 확인을 받은 후에만 `gh issue create`를 실행한다. 확인 없이 issue를 생성하는 것은 금지된다.

## 현재 컨텍스트

- 브랜치: !`git branch --show-current 2>/dev/null || echo "git 저장소 아님"`
- Remote: !`git remote get-url origin 2>/dev/null || echo "none"`
- GitHub 인증: !`gh auth status 2>&1 | grep -E "(Logged in|not logged|command not found)" | head -1`
- Template 개수: !`ls .github/ISSUE_TEMPLATE/*.md 2>/dev/null | wc -l | awk '{$1=$1};1'`

## 워크플로우

### 1단계: 사전 검증

위의 "현재 컨텍스트"를 확인한다. 다음 조건 중 하나라도 실패하면 해당 안내 메시지를 출력한 뒤 **종료**한다 (AskUserQuestion이나 추가 작업 없이 단순 텍스트 응답으로 종료):

| 조건 | 실패 시 메시지 |
|---|---|
| 브랜치 != "git 저장소 아님" | "현재 디렉토리가 git 저장소가 아닙니다." |
| Remote != "none" 이고 github.com 포함 | "GitHub remote가 설정되어 있지 않습니다." |
| GitHub 인증 status에 "Logged in" 포함 | "gh CLI 인증이 필요합니다. `gh auth login` 실행 후 다시 시도하세요." |
| Template 개수 > 0 | "이 repo에 `.github/ISSUE_TEMPLATE/*.md`가 없습니다. Template을 추가한 뒤 다시 시도하세요." |

`gh` CLI 자체가 설치되어 있지 않다면 "현재 컨텍스트"의 GitHub 인증 라인에 "command not found" 류가 표시된다. 그 경우 "`gh` CLI가 필요합니다. `dev-tools-doctor` 스킬로 설치하세요." 안내 후 종료한다.

모든 조건 통과 시 2단계로 진행한다.

### 2단계: Template 탐지 및 선택

#### 2.1 Template 파일 목록화

`Glob` 도구로 `.github/ISSUE_TEMPLATE/*.md` 패턴을 조회한다 (`.yml`은 미지원). 결과가 빈 배열이면 1단계 검증에서 이미 걸러졌어야 하므로 이 시점에 도달했다면 로직 오류로 간주하고 종료한다.

#### 2.2 Template 파싱

각 `.md` 파일에 대해:

1. `Read` 도구로 파일 내용을 읽는다.
2. 최상단의 YAML frontmatter (`---`로 감싸진 블록) 를 파싱한다.
3. 다음 필드를 추출한다:
   - `name`: template 표시 이름 (없으면 파일명 사용)
   - `about`: template 설명 (없으면 빈 문자열)
   - `title`: issue title prefix (없으면 빈 문자열)
   - `labels`: 배열 (없으면 빈 배열)
4. frontmatter 아래 body는 별도로 보관 (Task 4의 draft 작성에 사용).
5. 파싱 실패 시 해당 template은 제외하고 경고 로그를 남긴다. 모든 template이 파싱 실패면 "Template 파싱 실패" 안내 후 종료.

#### 2.3 사용자 의도 수집

최초 사용자 메시지에 이미 "한 줄 설명"이 포함되어 있는지 확인한다 (예: "로그인 실패 버그 이슈 만들어줘"의 "로그인 실패 버그"). 있으면 그 설명을 그대로 사용한다.

없으면 사용자에게 한 번 묻는다 (AskUserQuestion 아님, 일반 텍스트 질문):

> "어떤 이슈를 shaping할까요? 한 줄로 요약해주세요."

사용자의 다음 응답을 "한 줄 설명"으로 사용한다.

#### 2.4 Template 선택

- Template이 **1개**만 있으면 질문 없이 그것을 사용하고 2.5단계로 진행한다.
- Template이 **2개 이상**이면:
  1. 한 줄 설명을 기반으로 가장 적합한 template을 추론한다 (이름 + about 비교).
  2. `AskUserQuestion` 으로 확인한다:
     - **question**: `"'<inferred_name>' template으로 작성할까요?"`
     - **header**: `"Template 확인"`
     - **옵션 1**: `"확인"` — 추론된 template 사용
     - **옵션 2**: `"다른 template 선택"` — 다음 질문에서 전체 목록에서 고름
  3. "다른 template 선택" 시 두 번째 `AskUserQuestion`:
     - **question**: `"어떤 template을 사용할까요?"`
     - **header**: `"Template 선택"`
     - **옵션**: 모든 template의 `name` 을 옵션으로 나열 (최대 4개). 4개 초과 시 Other로 직접 입력 유도.

#### 2.5 결과 정리

선택된 template의 `frontmatter` 와 `body` 를 다음 단계에서 사용하기 위해 보관한다.

### 3단계: Draft 작성 및 Review

_(Task 4에서 작성)_

### 4단계: 메타데이터 및 최종 승인

_(Task 5에서 작성)_

### 5단계: Issue 생성

_(Task 6에서 작성)_

## 오류 처리

_(Task 6에서 작성)_
