# Houston plugin for Claude Code

Streams what each Claude Code agent is doing to Houston. On every session start, prompt, tool call (as it starts and as it finishes), permission request, notification, subagent start and finish, and stop, Claude Code runs `scripts/houston-event.sh`. The script picks out the few fields Houston shows and sends them to Houston as one line on `~/Library/Application Support/Houston/events.sock`.

A tool call shows the moment it starts, so a ten-minute build reads "Running swift build" while it runs, not the step before. Houston applies what each event says to its agent at once: working on a prompt or a tool call, waiting on a permission prompt, idle on a stop, failed on a stop failure. It doesn't wait for its next `claude agents` reading.

## Install

Run this in your shell. It needs Claude Code 2.1.292 or later. From a Houston checkout at `~/code/houston`:

```bash
claude plugin install houston --marketplace ~/code/houston/plugin
```

It adds `plugin/`, the folder above this one, as a marketplace named `houston`, then installs the plugin from it for every project. Claude Code reads the plugin from this folder, so a change here reaches the next session without a reinstall. Without a checkout, install it from the public marketplace instead:

```bash
claude plugin install houston --marketplace Decima-Labs/houston-releases
```

Sessions you start afterwards load it. In a session that's already open, run `/reload-plugins`.

To try it in one session without installing it:

```bash
claude --plugin-dir ~/code/houston/plugin/houston
```

To remove it, run `claude plugin uninstall houston@houston`.

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

Every string is cut to 300 characters. Commands, file contents, edits, tool responses and transcripts never leave the hook, and nor do the assistant's messages, except a subagent's last one as it finishes. Houston reads at most 64 KiB a line and keeps at most 100 sessions' activity, forgetting a session a day after no agent lists it. At most 1,000 events wait for Houston at once, and all that are waiting land together as one update; in a burst bigger than that it keeps the newest. It counts the events it dropped and the lines that weren't events, and logs both as they grow, at most once a minute (`log stream --predicate 'subsystem == "xyz.decima.houston" && category == "hooks"'`).

`claude plugin validate ~/code/houston/plugin` checks the marketplace, and `claude plugin validate ~/code/houston/plugin/houston` this plugin. The tests in `Tests/HoustonCoreTests/HookPluginTests.swift` run the script against Houston's socket server.
