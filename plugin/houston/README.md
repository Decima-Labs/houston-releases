# Houston plugin for Claude Code

Streams what each Claude Code agent is doing to Houston. On every session start, prompt, tool call (as it starts and as it finishes), permission request, notification, subagent start and finish, and stop, Claude Code runs `scripts/houston-event.sh`. The script picks out the few fields Houston shows and sends them to Houston as one line on `~/Library/Application Support/Houston/events.sock`.

A tool call shows the moment it starts, so a ten-minute build reads "Running swift build" while it runs, not the step before. Houston applies what each event says to its agent at once: working on a prompt or a tool call, waiting on a permission prompt, idle on a stop, failed on a stop failure. It doesn't wait for its next `claude agents` reading.

## Progress

The plugin's MCP server, `eta` (`scripts/houston-progress.sh`), gives each session one tool, `mcp__plugin_houston_eta__progress`, and adds a short "Progress bar" section to its system prompt saying when to use it: for work of three or more steps, or over about three minutes, `start` with a title, the steps and a guess in minutes, `next` as each step finishes, with `add_steps` when the work grows, and `finish`. Houston shows the plan, the step it's on and the time left on the agent's tab, its session bar, Now and the iPad.

The server keeps nothing. It hands each call, with the session's id and the call's arguments, to Houston as one line on `~/Library/Application Support/Houston/progress.sock`, and passes Houston's one-line answer back as the tool's result. When Houston isn't running, or doesn't answer within 3 seconds, the result tells the agent to carry on without a progress bar. It needs `/usr/bin/jq`; without it the server exits, and Claude Code lists it as failed.

Subagents and teammates share their session's server, so a call of theirs would take over the session's plan. `scripts/houston-progress-guard.sh`, a `PreToolUse` hook on the progress tool alone, refuses any call that carries an `agent_id`, with "Only the main thread reports progress; subagents are tracked automatically." It is the plugin's only hook that Claude Code waits for, and it reads nothing but the event on its stdin.

## Install

Run this in your shell. It needs Claude Code 2.1.292 or later.

```bash
claude plugin install houston --marketplace Decima-Labs/houston-releases
```

Sessions you start afterwards load it. In a session that's already open, run `/reload-plugins`. To remove it, run `claude plugin uninstall houston@houston`.

## Behaviour

- Every hook is async, so Claude Code never waits for one.
- When Houston isn't running, the script finds no socket and exits at once.
- The script gives up on a send after a second, prints nothing, and always exits 0.

## What it sends

Only these fields leave the hook, picked out by `/usr/bin/jq` (shipped with macOS 15). Without jq the script sends nothing.

| Field | What Houston does with it |
|---|---|
| `hook_event_name`, `session_id`, `cwd`, `source` | Which hook fired, for which session and folder |
| `tool_name`, `tool_use_id` | The tool, and which call, so a call's start and finish make one row |
| `tool_input.description`, `tool_input.file_path`, `tool_input.notebook_path` | What a call does, in words: a Bash call's description, never its command; the file an edit touched, never the edit |
| `message`, `title`, `notification_type` | A notification, and whether it means the agent waits for you |
| `error` | Why a turn stopped |
| `agent_id`, `agent_type` | The subagent an event came from, and its type, such as Explore |
| `tool_input.subagent_type`, `tool_input.run_in_background` | For the Agent tool (Task in older Claude Code) only: the subagent it asked for, and whether it runs in the background. With the call's description, this names the subagent when it starts. Never the call's prompt |
| `last_assistant_message`, `agent_transcript_path` | For `SubagentStop` only: what a finished subagent said last, and where its transcript is, which Houston reads only inside `~/.claude/projects` |
| `prompt` | Its first 80 characters |
| `permission_mode` | The session's permission mode, for the bar at the top of its pane: shown in red while it bypasses permissions |
| `shells` | For `Stop` and `SubagentStop` only: how many shells the session runs in the background, counted from `background_tasks`. Never their commands |
| `git.pr`, `git.push` | For a Bash call that opened, readied or reopened a pull request, or pushed a branch, as Claude Code reads the command (`tool_response.gitOperation`): the pull request's number, link and what was done, or the branch pushed. Houston watches that pull request's checks in the session's bar. Never the command or its output |

Every string is cut to 300 characters. Commands, file contents, edits, tool responses (but for the pull request or branch a Bash call opened or pushed) and transcripts never leave the hook, and nor do the assistant's messages, except a subagent's last one as it finishes. Houston reads at most 64 KiB a line and keeps at most 100 sessions' activity, forgetting a session a day after no agent lists it. At most 1,000 events wait for Houston at once, and all that are waiting land together as one update; in a burst bigger than that it keeps the newest. It counts the events it dropped and the lines that weren't events, and logs both as they grow, at most once a minute (`log stream --predicate 'subsystem == "xyz.decima.houston" && category == "hooks"'`).
