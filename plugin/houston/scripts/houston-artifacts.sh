#!/bin/sh
# Claude Code runs this as each session starts and before each Artifact tool call, and waits for
# it. It reads where Houston keeps the pages agents make, from artifacts.json in Houston's folder,
# which Settings › Agents › Artifacts writes; with no file, or one it can't read, they go on this
# Mac, in ~/Documents/Houston Artifacts. A page on claude.ai belongs to the Claude account that
# published it, so once the account in use changes, a later session can't update it or read it.
#
# On this Mac, a starting session is told where pages go, and a publish with the Artifact tool is
# refused with the same instructions as its reason: the page goes in its own folder, as
# <folder>/<name>/index.html, so the files it needs can sit beside it, as a published artifact's
# do. Reading, listing and the rest go ahead. On claude.ai it prints nothing; so does anything
# without jq. Always exits 0, so a session never fails to start over it.
[ -x /usr/bin/jq ] || exit 0
exec 2>/dev/null

kept=$(/bin/cat "$HOME/Library/Application Support/Houston/artifacts.json")
/usr/bin/jq -c --arg kept "$kept" --arg home "$HOME" '
  ($kept | try fromjson catch null | if type == "object" then . else {} end) as $settings
  | select($settings.place != "cloud")
  | ($settings.folder | if type == "string" and length > 0 then . else $home + "/Documents/Houston Artifacts" end) as $folder
  | "Write the page as an HTML file at \($folder)/<name>/index.html, where <name> is short and kebab-case, such as merge-train; make the folder, and put any files the page needs beside it. Follow the artifact-design skill as you would for a published page; runtime capabilities (window.claude) do not work in a local file. Then open it in the browser with: open \"\($folder)/<name>/index.html\". To change a page, edit its file." as $how
  | if .hook_event_name == "SessionStart" then
      {hookSpecificOutput: {hookEventName: "SessionStart", additionalContext:
        "Artifacts: Houston keeps the pages you make on this Mac, in \($folder), because a page on claude.ai belongs to the Claude account that published it, and the account in use can change. Do not publish with the Artifact tool; Houston refuses it. Reading, listing and quickstart still work. \($how)"}}
    elif .hook_event_name == "PreToolUse" and .tool_name == "Artifact" and ((.tool_input.action // "publish") == "publish") then
      {hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason:
        "Houston keeps artifacts on this Mac (Settings › Agents › Artifacts), so publishing to claude.ai is off: a page there belongs to the account that published it. \($how)"}}
    else empty end
'
exit 0
