#!/bin/sh
# Claude Code runs this before each progress tool call, and waits for it. A call from a subagent
# or teammate is refused, with the reason as the tool's answer: they share their session's
# progress server, so a call of theirs would take over the session's own plan. Their progress is
# tracked from the hooks. A main-thread call goes on; so does every call when jq is missing.
[ -x /usr/bin/jq ] || exit 0
exec 2>/dev/null
/usr/bin/jq -c 'select((.agent_id // "") != "") | {
  hookSpecificOutput: {
    hookEventName: "PreToolUse", permissionDecision: "deny",
    permissionDecisionReason: "Only the main thread reports progress; subagents are tracked automatically."
  }
}'
exit 0
