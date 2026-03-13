#!/bin/bash
# post-commit-reminder.sh
# git commit 완료 후 /review, /simplify 수행 여부 리마인더

INPUT=$(cat)

# git commit 명령 완료 후 리마인더
if echo "$INPUT" | grep -q 'git commit'; then
  cat <<'EOF'
{
  "decision": "block",
  "reason": "커밋이 완료되었습니다. 사용자에게 다음을 안내해주세요: /review 또는 /simplify를 아직 수행하지 않았다면 실행을 권장합니다."
}
EOF
  exit 0
fi

exit 0
