#!/bin/sh
# Called only after terminal navigation reaches an outer edge.
set -eu

case "${1:-}" in
    left|down|up|right) direction=$1 ;;
    *) exit 2 ;;
esac

# This bridge belongs to the local desktop, never an SSH server.
[ -z "${SSH_CONNECTION:-}" ] || exit 0
command -v omniwmctl >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

# Discard a delayed request if its originating pane is no longer selected.
if [ -n "${2:-}" ]; then
    active=$(tmux display-message -p -t "$2" '#{&&:#{pane_active},#{window_active}}' 2>/dev/null) || exit 0
    [ "$active" = 1 ] || exit 0
fi

# A key repeat queued in tmux must not keep walking after leaving Ghostty.
focused=$(omniwmctl query focused-window --json 2>/dev/null) || exit 0
printf '%s\n' "$focused" | jq -e \
    '.ok == true and .result.payload.window.app.bundleId == "com.mitchellh.ghostty"' \
    >/dev/null 2>&1 || exit 0

exec omniwmctl command focus "$direction" >/dev/null
