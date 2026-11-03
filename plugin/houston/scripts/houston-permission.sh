#!/bin/sh
# Claude Code runs this when a session is about to ask you for permission to use a tool
# (PermissionRequest), and waits for it: the plugin's one live-activity hook that isn't async. It
# hands Houston the call whole, with the permission updates Claude Code suggests for it, and waits
# for your answer on Houston's permission card, up to five minutes. Allow, Always allow and Deny
# come back as Claude Code's own decision, so a session in Terminal, iTerm or Ghostty, which
# Houston can't press keys in, is answered from Houston too.
#
# Claude Code shows its own prompt while this waits (Claude Code 2.1.311 runs a session's
# PermissionRequest hooks beside its dialog, and the first answer wins), so you can still answer
# in the terminal. It prints nothing, and that prompt stays, when Houston isn't running, answers
# with nothing (it does at once for a session it can answer itself, in one of its own tabs or
# through `claude attach`), has no answer from you in time, or says anything else; and for a run
# with no terminal (`claude -p`, the Agent SDK), which has its own way to decide. It always exits 0.
#
# Always allow names which of Claude Code's suggestions you chose, by its place in the list; the
# update itself is taken from this event, never from Houston's answer, so Houston can only ever
# apply what Claude Code offered, and only a kind Houston offers: a rule that allows, a folder, or
# edits without asking, never another mode.

socket="$HOME/Library/Application Support/Houston/permissions.sock"
[ -S "$socket" ] || exit 0
# Only jq (shipped with macOS 15) can read the event and write the decision.
[ -x /usr/bin/jq ] || exit 0
# A session in a terminal says "cli"; a run Claude Code can't prompt in says otherwise.
case "${CLAUDE_CODE_ENTRYPOINT:-cli}" in cli) ;; *) exit 0 ;; esac
exec 2>/dev/null

event="$(cat)"

# What Houston shows on the card: the session, the subagent when it's one's, the folder, the tool
# and its input, each string cut to 20,000 characters (500 when that still leaves more than about
# 900 KB, under the 1 MiB a line Houston reads), with tool_input_cut saying when one was, so the
# card offers no Allow for what it can't show whole; Claude Code's suggestions as they are; and a
# Bash command's digest, the same houston-event.sh sends as the call ends, so Houston can tell when
# this call has gone on without it.
request="$(printf '%s' "$event" | /usr/bin/jq -c '
  def digest: reduce explode[] as $c (5381; (. * 33 + $c) % 2147483647) | tostring;
  def cut($n): walk(if type == "string" then .[0:$n] else . end);
  select(type == "object" and .hook_event_name == "PermissionRequest" and (.session_id | type) == "string")
  | (.tool_input | if type == "object" then . else {} end) as $input
  | ([$input | .. | strings | length] | max // 0) as $longest
  | {
      hook_event_name, session_id, agent_id, agent_type, cwd, permission_mode, tool_name,
      tool_input: ($input | cut(20000)),
      tool_input_cut: (if $longest > 20000 then true else null end),
      permission_suggestions: (.permission_suggestions | if type == "array" then . else null end),
      command_hash: (if .tool_name == "Bash" then ($input.command | if type == "string" then digest else null end) else null end)
    }
  | if (tojson | length) > 900000 then (.tool_input |= cut(500)) | .tool_input_cut = (if $longest > 500 then true else null end) else . end
  | with_entries(select(.value != null))
')"
[ -n "$request" ] || exit 0

# Houston answers with one line once you've chosen, or with nothing when it gives up, after five
# minutes. nc gives up too once nothing has passed for HOUSTON_PERMISSION_PATIENCE seconds, 310
# unless a test says, and Claude Code ends this hook at its timeout, 330 (hooks.json), whatever.
patience="${HOUSTON_PERMISSION_PATIENCE:-310}"
case "$patience" in ''|*[!0-9]*) patience=310 ;; esac
answer="$(printf '%s\n' "$request" | /usr/bin/nc -w "$patience" -U "$socket")"
[ -n "$answer" ] || exit 0

# The answer as Claude Code's decision: allow, with the suggestion chosen when it's one this event
# carried, or deny, with why and whether to stop. Anything else prints nothing. A question
# (AskUserQuestion) is allowed with your answers, and your notes on a preview, put in the call's
# own input, as its dialog would have put them: each answer a string under its question's words,
# for a question this call asks.
printf '%s' "$event" | /usr/bin/jq -c --arg answer "$answer" '
  (try ($answer | fromjson) catch null) as $a
  | select(($a | type) == "object")
  | (.permission_suggestions | if type == "array" then . else [] end) as $offered
  | ($a.suggestion | if type == "number" and . >= 0 and . == floor and . < ($offered | length) then $offered[.] else null end
     | if type == "object" and ((.type == "addRules" and .behavior == "allow") or .type == "addDirectories" or (.type == "setMode" and .mode == "acceptEdits")) then . else null end) as $chosen
  | (.tool_input | if type == "object" then . else {} end) as $input
  | ([$input.questions // [] | .[]? | .question | strings]) as $asked
  | if $a.behavior == "allow" and .tool_name == "AskUserQuestion" then
      ($a.answers | if type == "object" then with_entries(select((.key as $k | $asked | index($k)) != null and (.value | type) == "string")) else {} end) as $answers
      | ($a.annotations | if type == "object" then with_entries(select((.key as $k | $asked | index($k)) != null and (.value | type) == "object")) else {} end) as $notes
      | select(($answers | length) > 0)
      | {hookSpecificOutput: {hookEventName: "PermissionRequest", decision: {behavior: "allow",
          updatedInput: ($input + {answers: $answers} + (if ($notes | length) > 0 then {annotations: $notes} else {} end))}}}
    elif $a.behavior == "allow" then
      {hookSpecificOutput: {hookEventName: "PermissionRequest", decision: ({behavior: "allow"} + (if $chosen == null then {} else {updatedPermissions: [$chosen]} end))}}
    elif $a.behavior == "deny" then
      {hookSpecificOutput: {hookEventName: "PermissionRequest", decision: {
        behavior: "deny",
        message: ($a.message | if type == "string" and length > 0 then .[0:2000] else "The user denied this in Houston." end),
        interrupt: ($a.interrupt == true)
      }}}
    else empty end
'
exit 0
