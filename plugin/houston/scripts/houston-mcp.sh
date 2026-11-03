#!/bin/sh
# The houston plugin's MCP server "houston": Houston's own tools, served by `houston mcp`, the
# houston command in Houston.app. Claude Code starts it for each session, with whatever PATH it was
# started with, which may not be your shell's: so this looks in Houston.app itself, then where
# Houston installs the command, and only then on the PATH (mission 20261030-0t01, L2).
#
# A houston from before `houston mcp` takes the word for a folder to open, so a command is run only
# once its help lists `houston mcp`. With none, it says why on stderr and exits, and Claude Code
# lists the server as failed; the rest of the plugin works as before.

# Houston.app's own command in both Applications folders, then where Houston installs it, and only
# then the PATH, where a repository's own bin folder could hold a houston of its own; tests give theirs.
places=${HOUSTON_MCP_PLACES:-"/Applications/Houston.app/Contents/MacOS/houston-cli:$HOME/Applications/Houston.app/Contents/MacOS/houston-cli:/usr/local/bin/houston:$HOME/.local/bin/houston"}

found=$(command -v houston 2>/dev/null)
IFS=:
for cli in $places $found; do
  [ -x "$cli" ] || continue
  if "$cli" --help 2>/dev/null | grep -q 'houston mcp'; then
    exec "$cli" mcp
  fi
done

echo "houston mcp: no houston command new enough to serve Houston's tools. Update Houston (Houston › Update Houston…), then install its command (Houston › Install 'houston' Command in PATH…)." >&2
exit 1
