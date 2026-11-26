#!/usr/bin/env bash
# ~/.config/noctalia/hooks/kitty.sh
# =============================================================================
# Noctalia hook: reload running kitty windows after rendering.
#

# Reload running kitty windows after Noctalia renders kitty-colors.conf.
# SIGUSR1 is kitty's documented "reload config" signal; it re-reads kitty.conf
# and its includes (the rendered colors) without restarting the terminal or
# disturbing child processes. Safe and idempotent when no kitty is running.
set -euo pipefail

if command -v kitty >/dev/null 2>&1; then
    pkill -USR1 -x kitty 2>/dev/null || true
fi
