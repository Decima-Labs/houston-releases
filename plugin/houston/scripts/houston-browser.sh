#!/bin/sh
# Claude Code runs this as each session starts, and waits for it. It tells the session which
# browser to use: Houston's own, through the houston server's browser_ tools, for any web page,
# and Claude in Chrome only when the user asks for Chrome by name, never asking them to connect
# the Claude extension in Chrome. Houston's instructions say the same first thing, and Claude
# in Chrome's own tell an agent to load Chrome's tools first, so it hears this from both
# (mission 20261031-pvv1). Its first sentences are
# AgentToolbox.browserRule, word for word. Where Houston has never run there's no browser of its
# to use, so it prints nothing. Always exits 0, so a session never fails to start over it.
[ -d "$HOME/Library/Application Support/Houston" ] || exit 0
/bin/cat <<'EOF'
{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"Browser: For any web page, use Houston's browser: browser_open, browser_read and the other browser_ tools. Use Claude in Chrome (the claude-in-chrome tools) or any other browser only when the user asks for Chrome by name, and never ask them to install, connect or sign in to the Claude extension. When a page needs them to sign in, use browser_logins, or browser_ask_sign_in, which asks them on your tab from their iPhone, iPad or Mac. If they ask for Chrome and you have no claude-in-chrome tools, Houston started you without them: its Settings › Agents › Claude Code › Claude in Chrome gives its agents Chrome."}}
EOF
exit 0
