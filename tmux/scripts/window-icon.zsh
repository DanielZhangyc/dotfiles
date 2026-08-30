#!/bin/zsh

# Print the icon for the active pane in a tmux window. When the window has
# multiple panes, prefix the focused application with nf-md-view_quilt.
#
# #{pane_current_command} alone is unreliable: interpreted programs report
# the interpreter's name (pi runs via `#!/usr/bin/env node`, so tmux sees
# "node" and the pi icon never matched). Instead resolve the true foreground
# process from the pane's tty — the process that owns the terminal's
# foreground process group (pgid == tpgid) — and fall back to
# pane_current_command only when that fails.

pane_count=${1:-1}
command_name=${2:-}
tty_name=${3:-}

# `ps -t` lists every process attached to the pane's tty; while a job is
# running, the shell sits in its own background group and drops out of the
# filter, leaving the foreground application (last in a pipeline wins).
if [[ -n $tty_name && $tty_name != '?' ]]; then
  fg_command=$(ps -t "$tty_name" -o pid=,pgid=,tpgid=,comm= 2>/dev/null \
               | awk '$2 == $3 { print $4 }' | tail -n 1)
  [[ -n $fg_command ]] && command_name=$fg_command
fi

command_name=${command_name:t}
command_name=${(L)command_name}

case "$command_name" in
  # AI agents from the custom Maple Mono NF build.
  claude*)                  icon=$'\U000F2000' ;;
  codex*)                   icon=$'\U000F2001' ;;
  gemini*)                  icon=$'\U000F2002' ;;
  opencode*)                icon=$'\U000F2003' ;;
  pi)                       icon=$'\U000F2004' ;;
  aider|amp|goose|cursor-agent)
                            icon='' ;;

  # Editors and developer tools.
  nvim|nvim-*)              icon='' ;;
  vim|vi|view)              icon='' ;;
  lazygit|git|gitui)        icon='' ;;
  gh)                       icon='' ;;
  yazi|ranger|lf|nnn|fzf)   icon='' ;;
  btop|htop|top)            icon='󰍛' ;;
  docker|lazydocker)        icon='' ;;
  kubectl|k9s|helm)         icon='󱃾' ;;
  mysql|mariadb|psql|sqlite3|redis-cli|mongosh)
                            icon='' ;;

  # Languages and runtimes.
  node|nodejs|npm|npx|pnpm|yarn|bun|deno)
                            icon='' ;;
  python|python[0-9]*|ipython|uv)
                            icon='' ;;
  ruby|irb|bundle)          icon='' ;;
  rustc|cargo)              icon='' ;;
  go)                       icon='' ;;
  lua|luajit)               icon='' ;;
  java|javac|jshell)        icon='' ;;

  # Shells, remote sessions, and terminal-oriented commands.
  ssh|mosh)                 icon='󰣀' ;;
  zsh|bash|fish|sh|dash|ksh|nu|pwsh|tmux|screen)
                            icon='' ;;
  man|less|more)            icon='󰂺' ;;
  *)                        icon='' ;;
esac

if (( pane_count > 1 )); then
  print -rn -- '󰕴 '
fi

print -rn -- "$icon"
