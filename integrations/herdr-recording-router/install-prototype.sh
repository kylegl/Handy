#!/usr/bin/env bash
# PROTOTYPE installer. Safe to rerun.
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/handy-herdr"
config_path="${HANDY_HERDR_CONFIG:-$config_dir/config.json}"

local_app_data_windows=$(powershell.exe -NoProfile -Command '[Environment]::GetFolderPath("LocalApplicationData")' | tr -d '\r')
user_profile_windows=$(powershell.exe -NoProfile -Command '[Environment]::GetFolderPath("UserProfile")' | tr -d '\r')
wrapper_dir_windows="$local_app_data_windows\\HandyRecordingRouterPrototype"
wrapper_dir=$(wslpath -u "$wrapper_dir_windows")
handy_exe=$(wslpath -u "$local_app_data_windows\\Handy\\handy.exe")
build_checkout_windows="$user_profile_windows\\source\\Handy-herdr-build"
wsl_distro="${HANDY_HERDR_WSL_DISTRO:-${WSL_DISTRO_NAME:-}}"

install -d "$(dirname "$config_path")"
if [[ ! -f "$config_path" ]]; then
  python3 - "$config_path" "$handy_exe" "$wrapper_dir" "$wrapper_dir_windows" "$build_checkout_windows" "$wsl_distro" <<'PY'
import json
from pathlib import Path
import sys

path, handy_exe, wrapper_dir, wrapper_dir_windows, build_checkout, distro = sys.argv[1:]
Path(path).write_text(
    json.dumps(
        {
            "handy_exe": handy_exe,
            "windows_wrapper_dir": wrapper_dir,
            "windows_wrapper_dir_windows": wrapper_dir_windows,
            "windows_build_checkout_windows": build_checkout,
            "wsl_distro": distro,
        },
        indent=2,
    )
    + "\n"
)
PY
fi
chmod 600 "$config_path"

read_config() {
  python3 - "$config_path" "$1" <<'PY'
import json
import sys
print(json.load(open(sys.argv[1]))[sys.argv[2]])
PY
}

wrapper_dir=$(read_config windows_wrapper_dir)
wrapper_dir_windows=$(read_config windows_wrapper_dir_windows)
wsl_distro=$(read_config wsl_distro)
install -d "$wrapper_dir"
install -m 0644 "$root/windows/recording-router.cmd" "$wrapper_dir/recording-router.cmd"
python3 - "$root/windows/recording-router.ps1.in" "$wrapper_dir/recording-router.ps1" "$root/router.py" "$wsl_distro" <<'PY'
from pathlib import Path
import sys

template, output, router, distro = sys.argv[1:]
distro_args = f"-d {distro} " if distro else ""
text = Path(template).read_text()
text = text.replace("@ROUTER_PATH@", router).replace("@WSL_DISTRO_ARGS@", distro_args)
Path(output).write_text(text)
PY
chmod +x "$root/router.py"

plugin_root=$(herdr plugin list --json | python3 -c 'import json,sys; p=json.load(sys.stdin)["result"]["plugins"]; print(next((x["plugin_root"] for x in p if x["plugin_id"] == "local.recording-router-prototype"), ""))')
if [[ -n "$plugin_root" && "$plugin_root" != "$root" ]]; then
  herdr plugin unlink local.recording-router-prototype
  plugin_root=""
fi
if [[ -z "$plugin_root" ]]; then
  herdr plugin link "$root"
fi

cat <<EOF
Prototype installed.

Machine config:
  $config_path
Handy external script:
  $wrapper_dir_windows\\recording-router.cmd

Select Handy's External Script paste method and disable Handy Auto Submit.
The router performs Enter itself so submission goes to the originating pane.
EOF
