#!/bin/sh
# Claude Code runs this for each of the plugin's hooks, in the background
# (async). It forwards the parts of the hook's JSON event Houston reads to
# Houston, as one line on the socket Houston listens on. It prints nothing,
# always exits 0 and gives up after a second, so a missing, quitting or stuck
# Houston never slows or breaks an agent.

socket="$HOME/Library/Application Support/Houston/events.sock"
[ -S "$socket" ] || exit 0
# Only jq (shipped with macOS 15) can pick the fields out. Without it nothing
# is sent: a whole event carries commands, file contents and tool output.
[ -x /usr/bin/jq ] || exit 0
exec 2>/dev/null

# A background job's stdin is /dev/null, so the sender reads the event on fd 3.
# Houston gets only what it shows: which hook, session and folder, and why a
# session started or ended; the tool's name, its description and the file it
# touched, never a command, an edit or what the tool returned; a
# notification's words; a stop's reason; the subagent's id and type; and a
# prompt's first 80 characters. For the Agent tool (Task in older Claude
# Code), the subagent type it asked for and whether it runs in the background,
# never its prompt; and when a subagent finishes, its last message and where
# its transcript is. The session's permission mode, and on a stop how many
# shells it runs in the background, never their commands. For a Bash call that
# opened or pushed to a pull request, which one, as Claude Code itself reads
# the command: its number, link and branch, never the output. Every string is
# cut to 300 characters, so no event can grow Houston's memory.
#
# As a call ends, two numbers let Houston tell an agent going round in circles,
# running one command again and again and failing the same way, without ever
# reading the command or its output: a Bash call's command as a digest, and how
# a call failed as a digest of the lines of its error, or of a Bash call's
# output, that say something failed, with their numbers taken out, so a test
# run's timings and line numbers don't tell one run from the next. A digest is
# the same for the same text and can't be read back. A failed call's error,
# which is its output, never leaves.
#
# When a call asks you for permission, what lets Houston offer a rule once you
# have allowed the same call three times in a day: a Bash call's command as the
# same digest, so its end can be told for its own; its first three words, up
# to the first that isn't a plain word, so never a quoted string, a variable,
# an assignment or an option, each cut to 40 characters; and whether the
# command chains, pipes or redirects. For a WebFetch, the domain of its link,
# never the rest of it.
exec 3<&0
/usr/bin/jq -c '
  def digest: reduce explode[] as $c (5381; (. * 33 + $c) % 2147483647) | tostring;
  def failing: [.[-100000:] | split("\n")[]
    | select(test("(?i:\\b(errors?|fail(ed|ing|ures?)?|fatal|panic(ked)?|exception|traceback)\\b)|[a-z](Error|Exception)\\b|\u2718|\u2717"))
    | select(test("\\b(0|no) (errors?|fail(ed|ures?)?)\\b"; "i") | not)
    | gsub("[0-9]+"; "#")];
  def failure: failing | if length > 0 then join("\n") | digest else null end;
  (.tool_name == "Agent" or .tool_name == "Task") as $spawns
  | (.hook_event_name == "SubagentStop") as $finished
  | (.hook_event_name == "PostToolUseFailure") as $failed
  | (.hook_event_name == "PermissionRequest") as $asks
  | (if $asks and .tool_name == "Bash" then (.tool_input | if type == "object" then .command else null end | if type == "string" then . else null end) else null end) as $command
  | {
      hook_event_name, session_id, cwd, source, reason, tool_name, tool_use_id,
      message, title, notification_type, agent_id, agent_type, permission_mode,
      error: (if $failed then null else .error end),
      command_hash: (if (.hook_event_name == "PostToolUse" or $failed or $asks) and .tool_name == "Bash" then
        (.tool_input | if type == "object" then .command else null end | if type == "string" then digest else null end) else null end),
      failure_hash: (if $failed then
          (if .is_interrupt == true then null else (.error | if type == "string" then failure // (.[-100000:] | gsub("[0-9]+"; "#") | digest) else null end) end)
        elif .hook_event_name == "PostToolUse" and .tool_name == "Bash" then
          (.tool_response | if type == "object" then [.stdout, .stderr] | map(strings) | join("\n") | failure else null end)
        else null end),
      command_words: ($command | if . == null then null else
        [splits("[ \t]+") | select(length > 0)] | .[0:3] | until(all(test("^[A-Za-z0-9._/+@:][A-Za-z0-9._/+@:-]{0,39}$")); .[:-1]) end),
      command_compound: ($command | if . == null then null else test("[;&|`\n<>]|\\$\\(") end),
      fetch_domain: (if $asks and .tool_name == "WebFetch" then
        ([.tool_input | if type == "object" then .url else null end | strings | capture("^[A-Za-z][A-Za-z0-9+.-]*://(?:[^/@?#]*@)?(?<host>[A-Za-z0-9.-]+)")] | .[0].host | if . == null then null else ascii_downcase end)
        else null end),
      shells: (.background_tasks | if type == "array" then map(select(type == "object" and .type == "shell")) | length else null end),
      git: (if .hook_event_name == "PostToolUse" and .tool_name == "Bash" then (.tool_response | if type == "object" then .gitOperation else null end
        | if type == "object" then {
            pr: (.pr | if type == "object" then {number, url, action} else null end),
            push: (.push | if type == "object" then {branch} else null end)
          } else null end) else null end),
      prompt: (.prompt | if type == "string" then .[0:80] else null end),
      tool_input: (.tool_input | if type == "object" then
        {description, file_path, notebook_path} + (if $spawns then {subagent_type, run_in_background} else {} end)
        else null end),
      last_assistant_message: (if $finished then .last_assistant_message else null end),
      agent_transcript_path: (if $finished then .agent_transcript_path else null end)
    }
  | walk(if type == "object" then with_entries(select(.value != null)) elif type == "string" then .[0:300] else . end)
' <&3 | /usr/bin/nc -U "$socket" >/dev/null &
sender=$!
exec 3<&-

# Claude Code sets no time limit on async hooks, and nc's own -w can't end a
# send that Houston isn't reading, so a watchdog stops it after a second.
# HOUSTON_HOOK_PATIENCE, in whole seconds, lets the plugin's tests wait longer,
# so "exits at once" can be told from "waited for the watchdog" on a busy machine.
patience="${HOUSTON_HOOK_PATIENCE:-1}"
case "$patience" in ''|*[!0-9]*) patience=1 ;; esac
( /bin/sleep "$patience"; kill "$sender" ) >/dev/null &
watchdog=$!
wait "$sender"
kill "$watchdog"
exit 0
