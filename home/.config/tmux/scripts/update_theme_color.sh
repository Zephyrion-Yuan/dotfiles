#!/usr/bin/env bash
set -euo pipefail

# Determine theme color from tmux environments with fallback
# Prefer session env, then global env, else default.
DEFAULT="#b294bb"

theme_line=$(tmux show-environment TMUX_THEME_COLOR 2>/dev/null || true)
if [[ "$theme_line" == TMUX_THEME_COLOR=* ]]; then
  theme="${theme_line#TMUX_THEME_COLOR=}"
else
  theme_line=$(tmux show-environment -g TMUX_THEME_COLOR 2>/dev/null || true)
  if [[ "$theme_line" == TMUX_THEME_COLOR=* ]]; then
    theme="${theme_line#TMUX_THEME_COLOR=}"
  else
    theme=""
  fi
fi

# show-environment returns "FOO=" when a var is *set but empty* — guard against
# that and any malformed value so we never feed `fg=` to pane-border-style.
[[ -z "$theme" || "$theme" == -* ]] && theme="$DEFAULT"

tmux set -g @theme_color "$theme"
tmux set -g pane-active-border-style "fg=$theme"

exit 0
