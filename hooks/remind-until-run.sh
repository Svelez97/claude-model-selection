#!/usr/bin/env bash
# Claude-Model-Selection trigger (UserPromptSubmit).
# Until the skill has run in this chat, remind Claude to run it on the incoming message.

input=$(cat)

transcript=$(printf '%s' "$input" | grep -o '"transcript_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -n 1 | sed 's/.*"\([^"]*\)"$/\1/; s/\\\\/\//g')

# The skill already ran in this chat: stay quiet.
if [ -n "$transcript" ] && [ -f "$transcript" ] && grep -q '"skill":"[^"]*claude-model-selection' "$transcript"; then
  exit 0
fi

echo "Claude-Model-Selection: the claude-model-selection skill has not run yet in this chat. Before doing anything else for this message, invoke it, unless the message is only a greeting or the user asked to skip it in this chat (for example: skip selection, sin seleccion). If it recommends a different model than the current one, stop after the recommendation and wait for the user to switch."
exit 0
