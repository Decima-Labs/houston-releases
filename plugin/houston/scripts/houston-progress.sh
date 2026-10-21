#!/bin/sh
# The houston plugin's MCP server, "eta": the progress tool, mcp__plugin_houston_eta__progress,
# which feeds the progress bar and time left Houston shows on the agent's tab, its session bar, Now
# and the iPhone and iPad. Claude Code starts it for each session and speaks JSON-RPC to it, a line
# at a time, on stdin and stdout. The server keeps nothing: it hands each call to Houston, on the
# socket Houston answers on, and passes Houston's answer back. Houston keeps the plans, measures
# the steps and works out the time left, so it sees each session's turns, from the hooks, as well.
#
# Its instructions are the "Progress bar" section of every session's system prompt. Without jq
# (shipped with macOS 15) it can't speak, so it exits and Claude Code lists it as failed.

socket="$HOME/Library/Application Support/Houston/progress.sock"
version="0.3.0"
tool="mcp__plugin_houston_eta__progress"
jq=/usr/bin/jq
[ -x "$jq" ] || exit 1
exec 2>/dev/null

instructions="# Progress bar
The person watches a progress bar and time-left estimate fed by the $tool tool. For a task with 3 or more distinct steps, or one likely to take more than about 3 minutes, call it:
- \"start\" before the work: a short title, the steps as 2-5 word phrases, and your honest estimate_minutes for the whole task.
- \"next\" each time a step finishes (it starts the following one); pass add_steps when the work grows.
- \"finish\" when the task is done or abandoned.
Skip it for quick answers and one-step edits. Send each call alongside your other tool calls rather than on its own. Subagents never call it; their progress is tracked automatically."

spec='{
  "name": "progress",
  "description": "Report progress on the current multi-step task so the person sees a progress bar and time-left estimate. Actions: start (title, steps, estimate_minutes), next (completes the current step; optional add_steps), finish.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "action": {"type": "string", "enum": ["start", "next", "finish"]},
      "title": {"type": "string", "description": "start: the task in a few words"},
      "steps": {"type": "array", "items": {"type": "string"}, "description": "start: the planned steps, in order"},
      "estimate_minutes": {"type": "number", "description": "start: your estimate for the whole task"},
      "add_steps": {"type": "array", "items": {"type": "string"}, "description": "next: steps discovered since start"}
    },
    "required": ["action"]
  }
}'

# The session this server belongs to: Claude Code's own record for its process, which follows a
# /clear to the new session, else the id it started the server with.
session() {
  id="$("$jq" -r '.sessionId // empty' "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/sessions/$PPID.json")"
  printf '%s' "${id:-$CLAUDE_CODE_SESSION_ID}"
}

# Houston's answer to a call: one line back for the line sent, or nothing when Houston isn't
# running or doesn't answer within a few seconds. HOUSTON_PROGRESS_PATIENCE, in whole seconds,
# lets the plugin's tests wait longer on a busy machine.
ask() {
  [ -S "$socket" ] || return 0
  patience="${HOUSTON_PROGRESS_PATIENCE:-3}"
  case "$patience" in ''|*[!0-9]*) patience=3 ;; esac
  printf '%s\n' "$1" | /usr/bin/nc -w "$patience" -U "$socket" &
  sender=$!
  ( /bin/sleep "$patience"; kill "$sender" ) >/dev/null 2>&1 &
  watchdog=$!
  wait "$sender"
  kill "$watchdog" 2>/dev/null
}

# What the tool says for a call: Houston's answer, or why there is none.
call() {
  request="$(printf '%s' "$1" | "$jq" -c --arg session "$(session)" '{session_id: $session, arguments: (.params.arguments // {})}')"
  answer="$(ask "$request" | head -n 1)"
  printf '%s' "${answer:-Houston isn't running, so there's no progress bar; carry on without it.}"
}

while IFS= read -r line || [ -n "$line" ]; do
  method="$(printf '%s' "$line" | "$jq" -r 'if type == "object" then .method // "" else "" end')"
  case "$method" in
    initialize)
      printf '%s' "$line" | "$jq" -c --arg version "$version" --arg instructions "$instructions" '{
        jsonrpc: "2.0", id,
        result: {
          protocolVersion: (.params.protocolVersion // "2025-06-18"), capabilities: {tools: {}},
          serverInfo: {name: "houston", version: $version}, instructions: $instructions
        }
      }' ;;
    tools/list)
      printf '%s' "$line" | "$jq" -c --argjson spec "$spec" '{jsonrpc: "2.0", id, result: {tools: [$spec]}}' ;;
    tools/call)
      if [ "$(printf '%s' "$line" | "$jq" -r '.params.name')" = progress ]; then
        printf '%s' "$line" | "$jq" -c --arg text "$(call "$line")" '{jsonrpc: "2.0", id, result: {content: [{type: "text", text: $text}]}}'
      else
        printf '%s' "$line" | "$jq" -c '{jsonrpc: "2.0", id, error: {code: -32602, message: "Unknown tool: \(.params.name)"}}'
      fi ;;
    ping)
      printf '%s' "$line" | "$jq" -c '{jsonrpc: "2.0", id, result: {}}' ;;
    *)
      # A notification, such as notifications/initialized, takes no answer; a request this server
      # doesn't know does.
      printf '%s' "$line" | "$jq" -c 'select(type == "object" and has("id") and has("method")) | {jsonrpc: "2.0", id, error: {code: -32601, message: "Method not found"}}' ;;
  esac
done
