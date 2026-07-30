#!/bin/sh

# Lightweight macOS metrics for the tmux status line.

LC_ALL=C
export LC_ALL

case "${1:-}" in
  cpu)
    cores=$(/usr/sbin/sysctl -n hw.logicalcpu 2>/dev/null)
    [ -n "$cores" ] || cores=1

    /bin/ps -A -o %cpu= 2>/dev/null |
      /usr/bin/awk -v cores="$cores" '
        { total += $1 }
        END {
          if (cores < 1) cores = 1
          usage = total / cores
          if (usage > 100) usage = 100
          printf "%.0f%%", usage
        }
      '
    ;;

  memory)
    /usr/bin/memory_pressure -Q 2>/dev/null |
      /usr/bin/awk '
        /free percentage:/ {
          free = $5
          gsub(/%/, "", free)
          printf "%d%%", 100 - free
          found = 1
        }
        END {
          if (!found) printf "--"
        }
      '
    ;;

  battery)
    /usr/bin/pmset -g batt 2>/dev/null |
      /usr/bin/awk -F '[;%]' '
        /InternalBattery/ {
          percent = $1
          sub(/^.*[[:space:]]/, "", percent)
          printf "%s%%", percent
          found = 1
        }
        END {
          if (!found) printf "--"
        }
      '
    ;;

  *)
    printf '%s' '--'
    ;;
esac
