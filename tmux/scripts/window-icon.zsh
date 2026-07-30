#!/bin/zsh

# Print the icon for the active pane in a tmux window. When the window has
# multiple panes, prefix the focused application with nf-md-view_quilt.

pane_count=${1:-1}
command_name=${2:-}
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
