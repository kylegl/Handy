#!/usr/bin/env bash
# PROTOTYPE installer. Safe to rerun.
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
windows_dir="/mnt/c/Users/LINK/AppData/Local/HandyRecordingRouterPrototype"

install -d "$windows_dir"
install -m 0644 "$root/windows/recording-router.ps1" "$windows_dir/recording-router.ps1"
install -m 0644 "$root/windows/recording-router.cmd" "$windows_dir/recording-router.cmd"
chmod +x "$root/router.py"

if ! herdr plugin list --json | python3 -c 'import json,sys; p=json.load(sys.stdin)["result"]["plugins"]; raise SystemExit(0 if any(x["plugin_id"] == "local.recording-router-prototype" for x in p) else 1)'; then
  herdr plugin link "$root"
fi

cat <<'EOF'
Prototype installed.

The patched Handy build delegates Ctrl+B to this plugin while Windows Terminal is focused.
Handy external script:
  C:\Users\LINK\AppData\Local\HandyRecordingRouterPrototype\recording-router.cmd

Before use, select Handy's External Script paste method and disable Handy Auto Submit.
The router performs Enter itself so submission goes to the originating pane.
EOF
