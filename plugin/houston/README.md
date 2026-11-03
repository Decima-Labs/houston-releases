# Houston plugin for Claude Code

Streams what each Claude Code agent is doing to Houston. On every session start and end, prompt, tool call (as it starts, and as it finishes or fails), permission request, notification, subagent start and finish, and stop, Claude Code runs `scripts/houston-event.sh`. The script picks out the few fields Houston shows and sends them to Houston as one line on `~/Library/Application Support/Houston/events.sock`.

A tool call shows the moment it starts, so a ten-minute build reads "Running swift build" while it runs, not the step before. Houston applies what each event says to its agent at once: working on a prompt or a tool call, waiting on a permission prompt, idle on a stop, failed on a stop failure. It doesn't wait for its next `claude agents` reading.

## Progress

The plugin's MCP server, `eta` (`scripts/houston-progress.sh`), gives each session one tool, `mcp__plugin_houston_eta__progress`, and adds a short "Progress bar" section to its system prompt saying when to use it: for work of three or more steps, or over about three minutes, `start` with a title, the steps and a guess in minutes, `next` as each step finishes, with `add_steps` when the work grows, and `finish`. Houston shows the plan, the step it's on and the time left on the agent's tab, its session bar, Now and the iPad.

The server keeps nothing. It hands each call, with the session's id and the call's arguments, to Houston as one line on `~/Library/Application Support/Houston/progress.sock`, and passes Houston's one-line answer back as the tool's result. When Houston isn't running, or doesn't answer within 3 seconds, the result tells the agent to carry on without a progress bar. It needs `/usr/bin/jq`; without it the server exits, and Claude Code lists it as failed.

Subagents and teammates share their session's server, so a call of theirs would take over the session's plan. `scripts/houston-progress-guard.sh`, a `PreToolUse` hook on the progress tool alone, refuses any call that carries an `agent_id`, with "Only the main thread reports progress; subagents are tracked automatically." Claude Code waits for it, as for the artifacts hook below; it reads nothing but the event on its stdin.

## Houston's tools

The plugin's second MCP server, `houston`, is `houston mcp`: the houston command Houston installs on your PATH (Houston › Install 'houston' Command in PATH…). `scripts/houston-mcp.sh` starts it, finding the command on the PATH, else in `~/.local/bin` or `/usr/local/bin`, else in Houston.app, so it starts whatever PATH Claude Code has. A houston from before `houston mcp` would take `mcp` for a folder to open, so it runs only a command whose help lists `houston mcp`. It lists the tools Houston has, asking Houston for them on `~/Library/Application Support/Houston/agent.sock`, with instructions that tell the agent when to reach for each, and hands each call to Houston as the session it's working for. An agent reads anything; changes what its session made; and anything else asks you first, on the bell and the iPhone. While Houston isn't running it lists the tools Houston last had, and each call says to carry on without it. Without a houston new enough, Claude Code lists the server as failed, `/mcp` shows why, and the rest of the plugin works as before.

### Codex, Gemini CLI and Antigravity CLI

None of them takes this plugin, so Houston adds the same server to each, with houston-skills translated for it, when you turn on Houston's tools and skills in Settings › Agents › Codex, › Gemini CLI or › Antigravity CLI. It shows every file it adds first, writes nothing if one changes before you say so, and turning it off takes out exactly what it added. For Codex that's a `[mcp_servers.houston]` block at the end of `~/.codex/config.toml`, the working rules at the end of `~/.codex/AGENTS.md` and the skills in `~/.codex/skills/houston-*`; for Gemini CLI, an extension of Houston's in `~/.gemini/extensions/houston` and a policy, `~/.gemini/policies/houston.toml`, that lets Houston's tools run without Gemini CLI asking first; for Antigravity CLI, the server in `~/.gemini/config/mcp_config.json`, the rule `mcp(houston/*)` in `~/.gemini/antigravity-cli/settings.json`'s `permissions.allow`, and a plugin of Houston's, `~/.gemini/config/plugins/houston`, with the rules and skills. Each runs `~/Library/Application Support/Houston/bin/houston-mcp`, which Houston writes, and which finds the houston command the way `scripts/houston-mcp.sh` does. Gemini CLI starts it only in a folder you trust (`gemini trust`). docs/architecture/agents.md has the rest.

What follows is how Codex takes the server, which holds whichever way it was added. By hand, once Houston is up to date, add it to `~/.codex/config.toml`:

```toml
[mcp_servers.houston]
command = "houston"
args = ["mcp"]
default_tools_approval_mode = "approve"
```

Settings › Agents leaves a houston server you added by hand as it is.

`default_tools_approval_mode = "approve"` lets the thread call Houston's tools without Codex asking first. Houston still decides what needs you: a thread reads anything and changes what it made, and anything else asks you on the bell and the iPhone. Without that line, Codex asks before every tool Houston doesn't mark read-only, such as `browser_open`, `browser_read` and `browser_close`, and under `approval_policy = "never"` (`codex -a never`) it refuses them: "MCP tool call requires approval, but approval policy is never". `houston_status` and `browser_tabs` are read-only, so Codex never asks about them. To let through only some tools, leave the default out and give each its own `[mcp_servers.houston.tools.<tool>]` table with `approval_mode = "approve"`.

If Codex can't find `houston`, give the command's full path, such as `/Users/you/.local/bin/houston` (`command -v houston` prints it).

This is the way in to use. Codex 0.123 and later name the thread that calls in every tool call (`_meta.threadId`, the id its shell has in `CODEX_THREAD_ID`), and `houston mcp` takes each call as that thread's. That makes it the thread's own: `browser_open` opens a tab as the thread's, and `houston_status` names it. Codex starts MCP servers outside its sandbox, so this needs no sandbox setting.

- It works wherever Codex runs: `codex` in a terminal, including `codex resume` and `codex fork`, `codex exec`, and Codex.app and the IDE extension, whose app-server runs many threads in one process. Each call is the thread that made it, after `/new` too.
- A Codex older than 0.123 names no thread in its calls, and gives an MCP server nothing of its thread in its environment or as it starts. Then `houston mcp` sends Houston the `codex` process it runs under, and Houston calls it by the thread it lists for that process on the Agents screen, reading Codex's threads again, at most every 15 seconds, when it lists none yet. That works for `codex` in a terminal; after `/new` in the same `codex`, calls belong to the old thread until Houston lists the new one, within a minute. Under Codex.app, the IDE extension or `codex exec`, no listed thread holds the process, so their calls have no session: they read anything, own nothing, and every change asks you first, until Codex is updated.
- When an agent such as Claude Code runs `codex exec`, Codex's calls are its thread's, not the agent's that started it.

The shell commands, such as `houston browser open`, also work, and name the thread from the `CODEX_THREAD_ID` Codex gives its shell. But Codex's sandbox blocks the Unix socket Houston listens on, `~/Library/Application Support/Houston/agent.sock`, so a sandboxed shell needs one of these:

- `--sandbox workspace-write` with network access on, in `~/.codex/config.toml`. This lets its commands reach the internet too:

  ```toml
  sandbox_mode = "workspace-write"

  [sandbox_workspace_write]
  network_access = true
  ```

- For one command, `codex sandbox --allow-unix-socket ~/Library/Application\ Support/Houston houston browser tabs`.

We checked all of this on 26 October 2026 with Codex 0.161.0 in a terminal, in one thread with `--sandbox workspace-write` and `network_access = true`: `houston_status` named the thread, `browser_open`, `browser_read` and `browser_close` opened, read and closed a tab as the thread's own once Codex let them through, and `houston browser tabs` from the thread's shell reached Houston.

We first checked the sandbox with `codex sandbox` against a stand-in socket. A connection was refused under the default and workspace-write sandboxes, and also with a permissions profile's `network.unix_sockets` set to the folder. It went through with `network_access = true` or `--allow-unix-socket`.

We checked the thread in each call on 26 October 2026 against a stand-in MCP server and a stand-in model on this Mac, in a `CODEX_HOME` of their own: `codex exec` 0.161.0's call named its thread, and so did each of two threads in one `codex app-server`, the program Codex.app and the IDE extension run, both with Codex 0.161.0 and with the 0.140.0-alpha.2 inside Codex.app 26.609. Each thread had a `houston mcp` of its own, and none had its thread in its environment. The IDE extension isn't installed here, so it wasn't run; it starts the same app-server, and Codex's source sends `threadId` from one place for every way in (`codex-rs/core/src/mcp_tool_call.rs`, since 0.123.0).

## Artifacts

A page published to claude.ai with Claude Code's `Artifact` tool belongs to the Claude account that published it, so once the account in use changes, a later session can't update it or even read it. Houston's Settings › Agents › Artifacts says where pages go, On this Mac or On claude.ai, and writes it to `~/Library/Application Support/Houston/artifacts.json`: `{"folder": "/Users/you/Documents/Houston Artifacts", "place": "mac"}`, or `"place": "cloud"`.

`scripts/houston-artifacts.sh` reads that file with `/usr/bin/jq` as each session starts (`SessionStart`) and before each `Artifact` call (`PreToolUse`, matching that tool alone), and Claude Code waits for it, 5 seconds at most. A file that isn't there, or can't be read, means On this Mac, in `~/Documents/Houston Artifacts`, so it holds without Houston running.

- **On this Mac**, a starting session gets a few lines of context: where its pages go, and how to make one. Write it as `<folder>/<name>/index.html`, a short kebab-case name such as `merge-train`, with the files it needs beside it, following the artifact-design skill as for a published page; open it with `open`; edit the file to change it. A publish (an `Artifact` call whose action is `publish`, or that names none) is refused with `permissionDecision: "deny"`, the same instructions as its reason. Every other action, such as read, list or quickstart, goes ahead.
- **On claude.ai**, it prints nothing, and nothing is refused.

Without jq it prints nothing either, and it always exits 0, so a session never fails to start over it.

## Houston's browser

`scripts/houston-browser.sh` runs as each session starts (`SessionStart`), and Claude Code waits for it, 5 seconds at most. It tells the session to use Houston's browser, the houston server's `browser_` tools, for any web page; Claude in Chrome only when you ask for Chrome by name; never to ask you to connect the Claude extension in Chrome; and `browser_logins` or `browser_ask_sign_in` when a page needs you to sign in. Houston's instructions say the same first thing; Claude in Chrome's own tell an agent to load Chrome's tools first, so it hears this from both. Where Houston has never run it prints nothing, and it always exits 0.

The sessions Houston starts or resumes have no Claude in Chrome at all (`--no-chrome`) unless Settings › Agents › Claude Code › Claude in Chrome is on.

## Install

Run this in your shell. It needs Claude Code 2.1.292 or later.

```bash
claude plugin install houston --marketplace Decima-Labs/houston-releases
```

Sessions you start afterwards load it. In a session that's already open, run `/reload-plugins`. To remove it, run `claude plugin uninstall houston@houston`.

Houston keeps it up to date with itself: Houston.app carries the plugins it was built with, and when Claude Code's copy is older, Houston points the `houston` marketplace at Houston.app's and updates them, once for each new version. Settings › Permissions says when it did, and sessions already running keep the copy they started with until they restart.

## Permission prompts

When a session is about to ask you for permission to use a tool, Claude Code runs `scripts/houston-permission.sh` (`PermissionRequest`) and waits for it. It hands Houston the call on `~/Library/Application Support/Houston/permissions.sock` and waits for your answer on Houston's permission card: the session's card on Agents and the questions sheet, with the tool and its whole command, path, link or input, Allow, Always allow when Claude Code suggests a rule, a folder or edits without asking (never a mode that skips every prompt, nor a rule to deny or ask), and Deny. Your answer comes back as Claude Code's own decision, `hookSpecificOutput.decision.behavior` `allow` or `deny`:

- **Allow** runs the call once.
- **Always allow** runs it with `updatedPermissions` set to the one suggestion you chose. Houston's answer names only the suggestion's place in the list; the script takes the update from Claude Code's own event, so Houston can only ever apply what Claude Code offered.
- **Deny** refuses it and stops the agent (`interrupt`), as Esc does in its terminal. Your own words in the card's box deny it too, and Claude hears them (`message`) and goes on.

Houston holds a prompt only for a session it can't answer itself, such as one in Terminal, iTerm or Ghostty. For a session in one of Houston's own tabs, or in the background, which Houston answers by pressing keys, it answers the script at once with nothing. A session's own agent, any other session and any agent tool can't answer it: the socket takes a prompt in and gives a decision back on the same connection, and only your answer on the card makes one.

A question (`AskUserQuestion`) or a plan to approve (`ExitPlanMode`) is held the same way, but asked on its own card in the session's chat on Agents, and on your iPhone and iPad, rather than with Allow and Deny: every question with its answers, their descriptions and previews, words of your own and notes on a preview; or the plan, with Approve and a box for what to change. Your answers come back as Claude Code's own: the call allowed with your `answers` (and `annotations`, for your notes on a preview) put in its input, as its dialog would have put them, each under one of the questions the call asks; a plan approved, or refused with what you'd change, which Claude hears. Checked against Claude Code 2.1.314 on 30 October 2026, which took a hook's answers in place of its dialog's.

Claude Code shows its own prompt while the script waits (Claude Code 2.1.311 runs a session's `PermissionRequest` hooks beside its dialog, and the first answer wins), so you can answer in the terminal too; Houston takes the card down once that call finishes or fails, or the turn or session ends. A background subagent's prompt is the exception: Claude Code waits for its hooks before it shows that one, so it shows in the terminal once Houston lets it go.

The script prints nothing, and Claude Code's prompt is the only one, when:

- Houston isn't running, or its socket is there with nothing listening;
- Houston has no answer from you after five minutes (`PermissionHolds.wait`), and takes the card down; the script itself gives up after 310 seconds with nothing said on the socket (`nc -w`, `HOUSTON_PERMISSION_PATIENCE` in tests), and Claude Code stops it at 330 (`timeout` in `hooks/hooks.json`);
- the session runs with no terminal, `claude -p` or the Agent SDK (`CLAUDE_CODE_ENTRYPOINT` other than `cli`), which has its own way to decide;
- Houston answers anything but allow or deny.

It needs `/usr/bin/jq`, and always exits 0. It works only in sessions started after the plugin updates to 0.8.0, and for questions and plans to 0.8.1. From 0.8.2 it says when it cut a string of the call's input (`tool_input_cut`), and Houston's card then offers only Deny, as it can't show all that Allow would approve; and Always allow applies only a rule that allows, a folder or edits without asking, whatever the answer names.

## Behaviour

- The live-activity hooks are async, so Claude Code never waits for them. It waits only for the permission hook, at a permission prompt, as above, and for the progress tool's guard and the artifacts hook, which read nothing but their event and, for the artifacts hook, one small file.
- When Houston isn't running, the script finds no socket and exits at once.
- The script gives up on a send after a second, prints nothing, and always exits 0.

## What it sends

Only these fields leave the hook, picked out by `/usr/bin/jq` (shipped with macOS 15). Without jq the script sends nothing.

| Field | What Houston does with it |
|---|---|
| `hook_event_name`, `session_id`, `cwd`, `source`, `reason` | Which hook fired, for which session and folder, and how a session started or why it ended, such as `resume` or `logout` |
| `tool_name`, `tool_use_id` | The tool, and which call, so a call's start and finish make one row |
| `tool_input.description`, `tool_input.file_path`, `tool_input.notebook_path` | What a call does, in words: a Bash call's description, never its command; the file an edit touched, never the edit. A finished edit's whole path is kept for the collision radar, which compares the files agents change across worktrees |
| `message`, `title`, `notification_type` | A notification, and whether it means the agent waits for you |
| `error` | Why a turn stopped. A failed tool call's error, which is its output, never leaves |
| `agent_id`, `agent_type` | The subagent an event came from, and its type, such as Explore |
| `tool_input.subagent_type`, `tool_input.run_in_background` | For the Agent tool (Task in older Claude Code) only: the subagent it asked for, and whether it runs in the background. With the call's description, this names the subagent when it starts. Never the call's prompt |
| `last_assistant_message`, `agent_transcript_path` | For `SubagentStop` only: what a finished subagent said last, and where its transcript is, which Houston reads only inside `~/.claude/projects` |
| `prompt` | Its first 80 characters |
| `permission_mode` | The session's permission mode, for the bar at the top of its pane: shown in red while it bypasses permissions |
| `shells` | For `Stop` and `SubagentStop` only: how many shells the session runs in the background, counted from `background_tasks`. Never their commands |
| `command_hash`, `failure_hash` | As a call ends (`PostToolUse`, `PostToolUseFailure`): a Bash call's command, and how a call failed, each as a digest, a number that is the same for the same text and can't be read back. The failure's is of the lines of the call's error, or of a Bash call's output, that say something failed (an error, a failed test, a panic, a traceback, but not "0 failures"), with every number taken out, so two runs that failed the same way share it whatever their timings or line numbers; an error with no such line is taken whole. Nothing for a call you stopped. Houston tells an agent going round in circles from them: the same command failing the same way again and again while it changes files between runs. Never the command, the error or the output |
| `git.pr`, `git.push` | For a Bash call that opened, readied or reopened a pull request, or pushed a branch, as Claude Code reads the command (`tool_response.gitOperation`): the pull request's number, link and what was done, or the branch pushed. Houston watches that pull request's checks in the session's bar. Never the command or its output |

The permission hook is the exception, on its own socket: at a permission prompt, `houston-permission.sh` sends Houston the session, subagent and folder, the tool and its whole input, each string cut to 20,000 characters (500 when the line would still pass about 900 KB), Claude Code's `permission_suggestions` as they are, and a Bash command's digest, as above, so you can judge the call on the card. Houston keeps it only while the card is up, and only for a session it can't answer itself.

Every string is cut to 300 characters. Commands, file contents, edits, tool responses and errors (but for the pull request or branch a Bash call opened or pushed, and the digests above) and transcripts never leave the hook, and nor do the assistant's messages, except a subagent's last one as it finishes. Houston reads at most 64 KiB a line and keeps at most 100 sessions' activity, forgetting a session a day after no agent lists it. At most 1,000 events wait for Houston at once, and all that are waiting land together as one update; in a burst bigger than that it keeps the newest. It counts the events it dropped and the lines that weren't events, and logs both as they grow, at most once a minute (`log stream --predicate 'subsystem == "xyz.decima.houston" && category == "hooks"'`).
