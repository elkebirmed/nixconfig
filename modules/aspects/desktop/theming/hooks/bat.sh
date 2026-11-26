#!/usr/bin/env bash
# ~/.config/noctalia/hooks/bat.sh
# =============================================================================
# Noctalia hook: reload running bat themes after rendering.
#

# Reload running bat themes after Noctalia renders bat.tmTheme.
# bat caches themes on first use; rebuild the cache so the regenerated
# theme is picked up immediately. Safe when bat is not installed.
set -euo pipefail

if command -v bat >/dev/null 2>&1; then
    bat cache --build 2>/dev/null || true
fi
