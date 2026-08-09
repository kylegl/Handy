# Recording Router Maintenance and Placement

This is the canonical operational guide for agents maintaining the Handy–Herdr recording-router integration. Read it before changing, building, installing, relocating, or updating any integration component.

## Source and runtime layout

Tracked files use portable paths. Machine-specific values live only in the local configuration created by the installer.

| Component | Portable location | Ownership |
| --- | --- | --- |
| Canonical monorepo | `${HOME}/repos/herdr-handy` by convention | Source of truth for the Handy fork and router |
| Router source | `<repo>/integrations/herdr-recording-router` | Herdr plugin, templates, and installer source |
| Machine configuration | `${XDG_CONFIG_HOME:-$HOME/.config}/herdr-handy/config.json` | Untracked paths for one machine |
| Windows build checkout | `windows_build_checkout_windows` from machine configuration | Disposable checkout used only to compile Handy |
| Installed Handy | `handy_exe` from machine configuration | Runtime executable |
| Installed Windows wrapper | `windows_wrapper_dir` from machine configuration | Generated `.cmd` and `.ps1` files |
| Handy settings | `%APPDATA%\com.pais.handy\settings_store.json` | Runtime application configuration |
| Router state | `/tmp/herdr-recording-router-prototype.json` | Ephemeral route for one active recording |

`config.example.json` documents the machine-configuration schema. Never commit the generated configuration.

## Source-of-truth rules

- Edit Handy and router sources only in the canonical monorepo.
- Edit the router only under `integrations/herdr-recording-router`.
- Never edit generated files in `windows_wrapper_dir`; rerun the installer.
- Treat the Windows build checkout as disposable. Do not make canonical changes there.
- Do not commit generated build output, Handy application data, router state, installed wrappers, binaries, local configuration, or timestamped backups.
- Fetch official Handy changes from the fetch-only `upstream` remote.
- Push maintained work only to the personal fork configured as `origin`.
- An upstream Handy update may replace the custom executable. Rebase, rebuild, and reinstall before applying one.

## Configuration precedence

The router reads its configuration from:

1. `HANDY_HERDR_CONFIG`, when set;
2. otherwise `${XDG_CONFIG_HOME:-$HOME/.config}/herdr-handy/config.json`.

`HANDY_EXE` overrides the configured `handy_exe` for one invocation. Handy's Windows shortcut delegation accepts these optional user environment variables:

| Variable | Meaning |
| --- | --- |
| `HANDY_HERDR_COMMAND` | WSL shell command that invokes the Herdr action |
| `HANDY_HERDR_WSL_DISTRO` | WSL distribution passed to `wsl.exe -d`; omit to use the default distribution |

The default delegation command resolves `herdr` through `$HOME/.local/bin` and invokes `local.recording-router-prototype.toggle`, so it contains no user-specific path.

## Install or refresh the plugin

Run from the canonical router directory:

```bash
cd "${HOME}/repos/herdr-handy/integrations/herdr-recording-router"
./install-prototype.sh
```

The installer:

1. detects Windows `%LOCALAPPDATA%` and `%USERPROFILE%` through PowerShell;
2. creates the local configuration when it does not exist;
3. generates the PowerShell wrapper from `windows/recording-router.ps1.in`;
4. copies runtime wrappers into the configured Windows directory;
5. links the canonical source as `local.recording-router-prototype`.

Existing configuration is preserved. Edit `config.json` to relocate a component, then rerun the installer.

Verify the link:

```bash
herdr plugin list --plugin local.recording-router-prototype --json
```

The reported `plugin_root` must point into the canonical monorepo.

## Handy runtime configuration

Handy must use:

| Setting | Required value |
| --- | --- |
| Transcribe with Post-Processing shortcut | `Ctrl+B` |
| Paste method | `External Script` |
| External script | `<windows_wrapper_dir_windows>\recording-router.cmd` |
| Auto Submit | Disabled |

The router owns Submission so Enter reaches the same destination as the Final Text. Enabling Handy Auto Submit would send Enter to whichever Windows application is focused after the external script returns.

Before editing `settings_store.json` directly, stop Handy, create a timestamped backup, make only the required changes, and restart Handy. Prefer the settings UI when automation is unnecessary.

## Windows build checkout

Windows-native Rust, Tauri, CMake, and Vulkan tooling should build from a normal Windows path. Read `windows_build_checkout_windows` from the local configuration and clone the personal fork there:

```powershell
git clone --branch main <origin-url> <windows-build-checkout>
```

Refresh an existing checkout instead of editing it:

```powershell
cd <windows-build-checkout>
git fetch origin
git reset --hard origin/main
```

Build:

```powershell
bun install --frozen-lockfile --force
bun run tauri build --no-bundle
```

The result is `<windows-build-checkout>\src-tauri\target\release\handy.exe`.

## Install patched Handy

1. Stop Handy.
2. Back up the configured `handy_exe` with a timestamp.
3. Copy the newly built executable over `handy_exe`.
4. Restart Handy.
5. Confirm the running process uses the expected path.
6. Exercise `Ctrl+B` inside and outside Herdr before removing backups.

## Validation

1. Focus a Herdr pane and press `Ctrl+B`.
2. Confirm its title becomes `🎙 RECORDING`.
3. Dictate and move focus to another pane.
4. Press `Ctrl+B` again.
5. Confirm the title becomes `… TRANSCRIBING`.
6. Confirm post-processed text and Enter arrive in the Origin Pane.
7. Confirm the marker and route-state file are cleared.
8. Press `Ctrl+B` outside Windows Terminal and confirm Fallback Delivery.
9. Confirm no console window flashes.

Handy debug logs should show `transcribe_with_post_process`, a successful LLM post-processing result, and `PasteMethod::ExternalScript`.

## Update from official Handy

```bash
git fetch upstream
git rebase upstream/main
```

Then validate, push `main` to `origin`, refresh the Windows build checkout, rebuild, reinstall, and rerun end-to-end validation. The official `upstream` push URL is intentionally disabled; do not re-enable it.

## Recovery

Clear stale state and pane metadata:

```bash
python3 "<repo>/integrations/herdr-recording-router/router.py" reset
```

If a custom build or settings change fails, restore the latest timestamped backup and restart Handy.
