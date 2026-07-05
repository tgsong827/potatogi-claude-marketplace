---
name: setup-ai-agent-rules-backend
description: >-
  백엔드(헥사고날 / 레이어드) 프로젝트에 AI 에이전트용 `.claude/rules/` 컨벤션 구조를 초기 셋업하고 내용까지 채운다.
  전 레이어 공통 원칙(01_conventions.md)과 레이어별 path-scoped 규칙 파일(domain / application /
  infrastructure / interface)을 생성한 뒤, 대상 프로젝트 코드를 분석해 레이어 규칙을 채운다.
  "컨벤션 룰 셋업", "백엔드 규칙 만들어줘", "레이어별 코딩 규칙 세팅", ".claude/rules 구성해줘",
  "아키텍처 컨벤션 문서 만들기", "AI 에이전트 규칙 셋업", "set up convention / architecture rules",
  "bootstrap coding conventions" 같은 요청에 사용한다. 새 백엔드 프로젝트 온보딩이나 기존 프로젝트에
  컨벤션 규칙을 도입할 때도 사용할 것. 룰이 없거나 정리가 안 된 백엔드 레포에서 규칙 체계를 잡아달라는
  뉘앙스면 명시적으로 "스킬"을 언급하지 않아도 이 스킬을 쓴다.
---

# Setup AI Agent Rules (Backend)

백엔드 프로젝트에 Claude Code가 자동 로드하는 `.claude/rules/` 컨벤션 규칙 체계를 세운다.

## 왜 이 구조인가 (배경)

Claude Code는 `.claude/rules/**/*.md`를 **매 세션 자동 로드**한다. `paths:` frontmatter가 없으면 항상 로드되고, 있으면 매칭 파일을 만질 때만 로드된다(progressive disclosure). 이 스킬은 그 메커니즘을 이렇게 활용한다:

- **`01_conventions.md`** — `paths` 없음 → 항상 로드. 특정 기술·프로젝트에 종속되지 않는 **범용 백엔드 큰 틀 원칙**만 간결하게.
- **`02_domain.md` ~ `05_interface.md`** — 각 레이어 디렉토리로 `paths` 스코프. 해당 레이어 코드를 작업할 때만 로드되는 **레이어 특화 규칙**.

레이어가 디렉토리와 1:1로 매핑되는 헥사고날/레이어드 구조에서 특히 잘 맞는다. always-on 컨텍스트는 최소화하고, 레이어별 상세는 필요할 때만 켜진다.

## 산출물

대상 프로젝트의 `.claude/rules/`에 최대 5개 파일:

```
01_conventions.md       # 항상 로드, 범용 공통 원칙 (12 카테고리, 이미 채워짐)
02_domain.md            # paths: <domain glob>
03_application.md       # paths: <application glob>
04_infrastructure.md    # paths: <infrastructure glob>
05_interface.md         # paths: <interface glob>
```

템플릿 원본은 **이 스킬의 `templates/` 디렉토리**에 있다. 구조는 진화할 수 있으므로 항상 템플릿을 원본(source of truth)으로 삼아 복사한다.

## 워크플로우

### 1. 사전 점검

- 대상이 백엔드 프로젝트인지, 레이어드/헥사고날 구조인지 확인한다.
- `.claude/rules/`가 이미 있으면 내용을 확인하고, 덮어쓰기 전에 사용자에게 알린다. 기존 규칙이 있으면 병합할지 교체할지 물어본다.

### 2. 레이어 감지 (detect & adapt)

대상 프로젝트를 스캔해 4개 레이어 역할에 실제 디렉토리를 매핑하고, 각 레이어의 glob을 정한다.

- **후보 위치**: 워크스페이스 멤버(`Cargo.toml`의 `members`, `pnpm-workspace.yaml`, `go.work`, Gradle 모듈 등), 최상위 디렉토리, `src/` 하위.
- **역할 ↔ 흔한 이름 매핑**:
  - domain → `domain`, `core`, `entities`, `model`
  - application → `application`, `app`, `service`, `usecase`, `use_cases`
  - infrastructure → `infrastructure`, `infra`, `adapter(s)`, `persistence`, `gateway`
  - interface → `interface`, `api`, `web`, `presentation`, `delivery`, `handler(s)`, `controller(s)`
- **glob 구성**: 매핑된 디렉토리 + 프로젝트 언어의 소스 확장자로 만든다. 예) Rust `domain/**/*.rs`, TS `src/domain/**/*.ts`, Go `internal/domain/**/*.go`, Java `**/domain/**/*.java`.
- 매핑이 애매하거나 레이어를 못 찾으면 **추측하지 말고 사용자에게 확인**한다.
- 레이어가 4개 미만이면 존재하는 것만 만든다. 3-tier(예: controller/service/repository)라면 그에 맞게 파일명을 조정해도 된다 — 핵심은 "역할별 path-scoped 파일 + 공통 conventions"라는 형태다.

### 3. 구조 생성

- 대상에 `.claude/rules/` 생성.
- `templates/01_conventions.md`를 **그대로** 복사한다(범용이라 수정 불필요, 사용자가 나중에 다듬음).
- 각 레이어 템플릿(`02`~`05`)을 복사하되 **`paths:` frontmatter를 2단계에서 정한 실제 glob으로 교체**한다. 템플릿 기본값은 언어 중립(`domain/**/*` 등)이므로 실제 레이어 디렉토리 + 소스 확장자로 바꾼다.
- 언어가 Rust가 아니면 `5. 네이밍 규칙`의 하위 슬롯 예시(`~Port`, `~Command` 등)를 해당 언어 관용에 맞게 이름만 조정한다(개념은 유지: 포트/커맨드/리포지토리/컨버터/DTO/핸들러 등).

### 4. 내용 채우기 (이 스킬의 최종 목표)

`01_conventions.md`는 이미 채워져 있다. **레이어 파일(`02`~`05`)의 빈 섹션을 대상 프로젝트 코드를 실제로 읽고 채운다.** 지어내지 말고 **관측된 패턴**만 규칙으로 적는다. 각 섹션에 채울 것:

| 섹션 | 채울 내용 |
|---|---|
| 1. 역할 & 책임 | 이 레이어가 무엇을 하고 무엇을 하지 않는가 (1~3줄) |
| 2. 의존 규칙 | 허용/금지 의존. 실제 import·매니페스트 의존성에서 확인한 방향 |
| 3. 구성 (모듈 구조) | 실제 하위 모듈/폴더와 각각의 책임 |
| 4. 핵심 구성요소 & 패턴 | 이 레이어의 주요 building block과 반복되는 작성 패턴 |
| 5. 네이밍 규칙 | **구성요소 종류별**로 관측된 접두/접미사·명명 규칙 (사용자가 상세히 쓰고 싶어하는 영역 — 세밀하게) |
| 6. 경계 & 변환 | 인접 레이어와 주고받는 타입, 변환(converter/DTO/mapper) 규칙 |
| 7. 에러 처리 | 이 레이어의 에러 타입과 전파/변환 방식 |
| 8. 테스트 | 이 레이어 테스트 전략·위치 |
| 9. 안티패턴 | 이 레이어에서 흔히 저지르는 실수 (아키텍처 위반 위주) |

작성 원칙:
- **간결하게.** 규칙은 검증 가능한 한 줄로. "clean code 작성" 같은 막연한 문장 금지.
- **관측 기반.** 코드에 실제로 나타난 컨벤션을 우선한다. 근거가 약하면 `<!-- TODO -->`로 남기고 사용자에게 확인받는다.
- 채우는 범위가 크면 레이어별로 진행하며 사용자에게 중간 확인을 받는다.

### 5. 마무리 & 보고

- 생성/수정한 파일과 각 레이어의 `paths` 매핑을 요약한다.
- 기존에 다른 규칙 파일(예: 관심사별 스텁)이 있었다면 정리 여부를 확인한다.
- `01_conventions.md`의 범용 원칙 중 프로젝트에 맞게 다듬을 부분을 짚어준다.

## 참고

- 이 스킬은 **레이어별 파일 + 공통 conventions**라는 형태가 핵심이다. 언어·프레임워크·레이어 개수는 대상에 맞춰 적응시킨다.
- 규칙은 강제(enforcement)가 아니라 컨텍스트다. 반드시 기계적으로 막아야 하는 것은 hook/CI로 따로 처리하도록 안내한다.
