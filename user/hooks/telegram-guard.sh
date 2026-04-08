#!/bin/bash
# telegram-guard.sh
# SessionStart hook: --channels 없이 시작된 세션이 spawn한 telegram bun 프로세스를 kill
# 다른 세션에는 영향을 주지 않음 (자기 자신만 정리)

LOG="/tmp/telegram-guard.log"
cat > /dev/null

echo "$(date '+%H:%M:%S') === telegram-guard START (PID=$$, PPID=$PPID) ===" >> "$LOG"

# PPID에서 위로 올라가며 claude 프로세스를 찾는다
PID=$PPID
CLAUDE_PID=""
while [ -n "$PID" ] && [ "$PID" != "1" ] && [ "$PID" != "0" ]; do
  ARGS=$(ps -o args= -p "$PID" 2>/dev/null)
  if echo "$ARGS" | grep -qi "claude"; then
    CLAUDE_PID="$PID"
    break
  fi
  PID=$(ps -o ppid= -p "$PID" 2>/dev/null | tr -d ' ')
done

# claude 프로세스를 찾지 못하면 종료
if [ -z "$CLAUDE_PID" ]; then
  echo "$(date '+%H:%M:%S') claude process NOT FOUND, exiting" >> "$LOG"
  exit 0
fi

echo "$(date '+%H:%M:%S') found claude PID=$CLAUDE_PID" >> "$LOG"
echo "$(date '+%H:%M:%S') claude args: $(ps -o args= -p "$CLAUDE_PID" 2>/dev/null)" >> "$LOG"

# --channels 세션이면 telegram을 유지해야 하므로 종료
if ps -o args= -p "$CLAUDE_PID" 2>/dev/null | grep -q -- '--channels'; then
  echo "$(date '+%H:%M:%S') --channels detected, keeping telegram" >> "$LOG"
  exit 0
fi

echo "$(date '+%H:%M:%S') no --channels, will kill telegram in 3s" >> "$LOG"

# 백그라운드에서 3초 대기 후, 이 세션이 spawn한 telegram bun 프로세스만 kill
(
  sleep 3

  FOUND=$(pgrep -f "plugins.*telegram.*start" 2>/dev/null)
  echo "$(date '+%H:%M:%S') telegram pids found: $FOUND" >> "$LOG"

  echo "$FOUND" | while read BUN_PID; do
    [ -z "$BUN_PID" ] && continue
    # 이 bun 프로세스가 우리 claude 프로세스의 자손인지 확인
    CHECK_PID="$BUN_PID"
    while [ -n "$CHECK_PID" ] && [ "$CHECK_PID" != "1" ] && [ "$CHECK_PID" != "0" ]; do
      CHECK_PID=$(ps -o ppid= -p "$CHECK_PID" 2>/dev/null | tr -d ' ')
      echo "$(date '+%H:%M:%S')   walking: BUN=$BUN_PID, CHECK_PID=$CHECK_PID, CLAUDE_PID=$CLAUDE_PID" >> "$LOG"
      if [ "$CHECK_PID" = "$CLAUDE_PID" ]; then
        echo "$(date '+%H:%M:%S')   KILLING BUN_PID=$BUN_PID" >> "$LOG"
        kill "$BUN_PID" 2>/dev/null
        break
      fi
    done
  done
) &

exit 0
