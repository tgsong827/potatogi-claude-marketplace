# potatogi-claude-marketplace

Claude Code plugin marketplace - 개인용 Claude plugin 도구들을 관리하는 프로젝트.

## Project Structure

```
potatogi-claude-marketplace/
├── user/                          # User scope plugin (potatogi-plugin-user)
│   ├── .claude-plugin/plugin.json # Plugin manifest
│   ├── .lsp.json                  # LSP server configs (rust, python, typescript)
│   ├── .mcp.json                  # MCP server configs
│   ├── agents/                    # Agent definitions
│   ├── hooks/                     # Hook scripts + hooks.json
│   └── skills/                    # Skill definitions (SKILL.md per skill)
├── projects/                      # Project scope plugins
│   ├── backend/                   # Backend project plugin (potatogi-plugin-backend)
│   └── frontend/                  # Frontend project plugin (potatogi-plugin-frontend)
└── docs/                          # Documentation (gitignored)
```

## Scopes

### User Scope (`user/`)

모든 Claude Code 세션에 적용되는 개인 도구 모음.

| Type   | Items                                                    |
|--------|----------------------------------------------------------|
| Skills | auto-commit, auto-push, setup-format-lint, skill-creator |
| Hooks  | telegram-guard (SessionStart), post-commit-reminder (PostToolUse:Bash) |
| Agents | security-auditor                                         |
| MCP    | willog-atlassian                                         |
| LSP    | rust-analyzer, pyright, vtsls                            |

### Project Scope (`projects/`)

특정 프로젝트 유형에 적용되는 plugin. 현재는 backend/frontend stub만 존재.

## Conventions

### Skill 작성

- 각 skill은 `{scope}/skills/{skill-name}/SKILL.md`에 정의
- SKILL.md에 frontmatter(`name`, `description`)와 본문(instructions) 포함
- 부가 리소스(scripts, agents, references)는 skill 디렉토리 하위에 배치

### Hook 작성

- hook script는 `{scope}/hooks/` 디렉토리에 배치
- `hooks.json`에서 event matcher와 command를 등록
- script 경로는 `${CLAUDE_PLUGIN_ROOT}/hooks/...` 형식 사용

### Agent 작성

- agent definition은 `{scope}/agents/{agent-name}.md`에 배치

### Plugin Manifest

- 각 scope의 `.claude-plugin/plugin.json`에 name, description, version, author 명시
