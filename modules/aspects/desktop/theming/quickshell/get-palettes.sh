#!/usr/bin/env bash
# ~/.local/bin/quickshell-get-palettes
# =============================================================================
# Output JSON list of palettes with their wallpapers for the QuickShell
# theme switcher. Each entry: { "name": "<palette>", "wallpapers": [...] }
#

# Output JSON list of palettes with their wallpapers for the QuickShell theme switcher.
# Each entry: { "name": "<palette>", "wallpapers": ["/path/to/img1", ...] }
python3 - <<'PY'
import os, json, glob, sys
try:
    import tomllib
except ImportError:
    import tomldecoder as tomllib # Fallback if needed, though 3.11+ has it

palettes_dir = os.path.expanduser("~/.config/noctalia/palettes/")
wall_dir_base = os.path.expanduser("~/Pictures/Wallpapers/")
sources_file = os.path.expanduser("~/.config/noctalia/wallpaper-sources.toml")

sources = {}
if os.path.exists(sources_file):
    try:
        with open(sources_file, "rb") as f:
            data = tomllib.load(f)
            sources = data.get("wallpaper", {}).get("sources", {})
    except Exception as e:
        print(f"DEBUG: Error loading TOML: {e}", file=sys.stderr)
        pass

def get_walls_from_dir(d):
    walls = []
    if os.path.isdir(d):
        for root, dirs, files in os.walk(d):
            for img in sorted(files):
                if img.lower().endswith((".jpg", ".jpeg", ".png", ".webp", ".bmp", ".avif")):
                    walls.append(os.path.join(root, img))
    return sorted(walls)

result = []
for f in sorted(glob.glob(os.path.join(palettes_dir, "*.json"))):
    name = os.path.splitext(os.path.basename(f))[0]
    walls = []

    custom_path = sources.get(name)
    if custom_path:
        # Expand environment variables manually since os.path.expanduser doesn't do $VAR
        expanded_path = os.path.expandvars(os.path.expanduser(custom_path))
        walls = get_walls_from_dir(expanded_path)
    else:
        # Default logic
        # Check Dark/ and Light/ subdirs first
        for mode in ("Dark", "Light"):
            md = os.path.join(wall_dir_base, name, mode)
            walls.extend(get_walls_from_dir(md))
        
        # Fallback: palette root dir
        if not walls:
            pd = os.path.join(wall_dir_base, name)
            walls.extend(get_walls_from_dir(pd))

    result.append({"name": name, "wallpapers": walls})

print(json.dumps(result))
PY
