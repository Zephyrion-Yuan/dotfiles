#!/usr/bin/env bash
# Toggle between "desktop" and "mobile" tmux UI modes based on the
# attached client's terminal width. Intended to be driven by the
# client-attached hook but also runnable manually:
#
#   detect_client_mode.sh            # same as `auto`
#   detect_client_mode.sh auto       # decide from client width
#   detect_client_mode.sh mobile     # force mobile mode
#   detect_client_mode.sh desktop    # force desktop mode
#
# Threshold is overridable via TMUX_MOBILE_MAX_WIDTH (default 100).
set -euo pipefail

mode="${1:-auto}"
threshold="${TMUX_MOBILE_MAX_WIDTH:-100}"

[[ -z "${TMUX:-}" ]] && exit 0

get_width() {
  local w
  w=$(tmux display-message -p '#{client_width}' 2>/dev/null || true)
  [[ -z "$w" || "$w" == "0" ]] && w=$(tmux display-message -p '#{window_width}' 2>/dev/null || true)
  [[ -z "$w" || "$w" == "0" ]] && w=100
  printf '%s' "$w"
}

if [[ "$mode" == "auto" ]]; then
  width=$(get_width)
  if [[ "$width" =~ ^[0-9]+$ ]] && (( width < threshold )); then
    mode="mobile"
  else
    mode="desktop"
  fi
fi

current=$(tmux show -gqv '@ui_mode' 2>/dev/null || true)
[[ "$current" == "$mode" ]] && exit 0

apply_mobile() {
  tmux set -g mouse off
  tmux set -g pane-border-status off
  tmux set -g pane-scrollbars off
  tmux set -g status-left-length 40
  tmux set -g status-right-length 30
  tmux set -g status-left '#[fg=#{?#{!=:#{environ:TMUX_THEME_COLOR},},#{environ:TMUX_THEME_COLOR},#b294bb},bold] #S #[default]'
  tmux set -g status-right '#[fg=colour244] #h #[default]'
  tmux setw -g window-status-format ' #I:#W '
  tmux setw -g window-status-current-format '#[fg=#{?#{!=:#{environ:TMUX_THEME_COLOR},},#{environ:TMUX_THEME_COLOR},#b294bb},bold] #I:#W '
}

apply_desktop() {
  tmux set -g mouse on
  tmux set -g pane-border-status top
  tmux set -g pane-scrollbars on
  tmux set -g status-left-length 90
  tmux set -g status-right-length 140
  tmux set -g status-left "#(~/.config/tmux/tmux-status/left.sh \"#{session_id}\" \"#{session_name}\")   "
  tmux set -g status-right "#(~/.config/tmux/tmux-status/right.sh)"
  tmux setw -g window-status-format '#[fg=#c5c8c6] #W#(~/.config/tmux/tmux-status/window_task_icon.sh "#{window_id}") '
  tmux setw -g window-status-current-format '#[fg=#{?#{!=:#{environ:TMUX_THEME_COLOR},},#{environ:TMUX_THEME_COLOR},#b294bb},bold] #W#(~/.config/tmux/tmux-status/window_task_icon.sh "#{window_id}") '
}

case "$mode" in
  mobile)  apply_mobile ;;
  desktop) apply_desktop ;;
  *) printf 'unknown mode: %s\n' "$mode" >&2; exit 1 ;;
esac

tmux set -g '@ui_mode' "$mode"
tmux refresh-client -S 2>/dev/null || true
