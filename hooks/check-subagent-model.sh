#!/usr/bin/env bash
# Claude-Model-Selection guard (PreToolUse on Agent/Task).
# A subagent may run on the session's model or a cheaper one without asking.
# A more expensive model needs the user's approval.

input=$(cat)

rank() {
  case "$1" in
    *haiku*) echo 1 ;;
    *sonnet*) echo 2 ;;
    *opus*) echo 3 ;;
    *fable* | *best*) echo 4 ;;
    *) echo 0 ;;
  esac
}

# Last "key":"value" pair in stdin. Escaped quotes don't match, so text inside prompts is ignored.
last_value() {
  grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | tail -n 1 | sed 's/.*"\([^"]*\)"$/\1/'
}

requested=$(printf '%s' "$input" | last_value model)

# No model given: the subagent inherits the session model, unless its definition sets one.
if [ -z "$requested" ]; then
  type=$(printf '%s' "$input" | last_value subagent_type)
  for f in "$CLAUDE_PROJECT_DIR/.claude/agents/$type.md" "$HOME/.claude/agents/$type.md"; do
    if [ -n "$type" ] && [ -f "$f" ]; then
      requested=$(grep -m 1 -i '^model:' "$f" | sed 's/^[Mm]odel:[[:space:]]*//; s/[[:space:]"'\'']*$//')
      break
    fi
  done
fi

r=$(rank "$requested")
[ "$r" -eq 0 ] && exit 0

# Session model: the latest model recorded in the transcript.
transcript=$(printf '%s' "$input" | last_value transcript_path | sed 's/\\\\/\//g')
session=""
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  session=$(tail -c 2000000 "$transcript" | grep -o '"model":"[^"]*claude-[^"]*"' | tail -n 1 | sed 's/.*"\([^"]*\)"$/\1/')
fi
s=$(rank "$session")

# Unknown session model: only Haiku passes without asking.
if [ "$s" -eq 0 ]; then
  [ "$r" -le 1 ] && exit 0
  session="unknown"
elif [ "$r" -le "$s" ]; then
  exit 0
fi

reason="Claude-Model-Selection: this subagent would run on $requested, a more expensive model than this session ($session). Approve only if the task really needs it."
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}\n' "$reason"
exit 0
