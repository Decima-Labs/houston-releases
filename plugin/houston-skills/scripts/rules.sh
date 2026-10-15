#!/bin/sh
# Adds the working rules in rules/rules.md to a Claude Code session as context, on SessionStart.
# Prints nothing when they're turned off: the plugin's "Working rules" option (which Claude Code
# hands hooks as CLAUDE_PLUGIN_OPTION_RULES) or HOUSTON_RULES in the environment set to off, 0,
# false or no. Always exits 0, so a session never fails to start over it.

off() {
  case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
    off | 0 | false | no) return 0 ;;
    *) return 1 ;;
  esac
}

off "${CLAUDE_PLUGIN_OPTION_RULES:-}" && exit 0
off "${HOUSTON_RULES:-}" && exit 0

root="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
rules="$root/rules/rules.md"
[ -r "$rules" ] || exit 0

# The rules as one JSON string: backslashes, quotes and tabs escaped, lines joined with \n.
awk '
  BEGIN { printf "{\"hookSpecificOutput\":{\"hookEventName\":\"SessionStart\",\"additionalContext\":\"" }
  {
    gsub(/\\/, "\\\\")
    gsub(/"/, "\\\"")
    gsub(/\t/, "\\t")
    gsub(/\r/, "")
    printf "%s%s", (NR > 1 ? "\\n" : ""), $0
  }
  END { printf "\"}}\n" }
' "$rules"
exit 0
