# Recording Router Prototype

> **Throwaway prototype.** It tests whether a Herdr action can remember a pane,
> mark it as recording, and route Handy output back to it after focus changes.

## Required placement

The integration currently uses fixed paths. Keep each component at the location
shown below unless all references to that path are updated together.

| Component | Required location | Purpose |
| --- | --- | --- |
| Canonical monorepo | `~/repos/handy-herdr` | Source of truth for the Handy fork and router |
| Router source | `~/repos/handy-herdr/integrations/herdr-recording-router` | Herdr plugin and installer source |
| Windows build checkout | `C:\Users\LINK\source\Handy-herdr-build` | Disposable Windows-native checkout used only to compile Handy |
| Installed Handy | `C:\Users\LINK\AppData\Local\Handy\handy.exe` | Runtime executable used by the router |
| Installed Windows wrapper | `C:\Users\LINK\AppData\Local\HandyRecordingRouterPrototype` | Runtime copies of `recording-router.cmd` and `.ps1` |
| Handy settings | `%APPDATA%\com.pais.handy\settings_store.json` | Paste-method and external-script configuration |
| Router state | `/tmp/herdr-recording-router-prototype.json` | One-shot route for the active recording |

The Windows build checkout is not a second source of truth. Create or refresh it
from the pushed fork branch, build there, and make code changes in the canonical
WSL monorepo.

```powershell
git clone --branch prototype/herdr-shortcut-delegation `
  https://github.com/kylegl/Handy.git `
  C:\Users\LINK\source\Handy-herdr-build
```

## Source-of-truth rules

- Edit the router only under `integrations/herdr-recording-router`.
- Do not edit files copied into `%LOCALAPPDATA%\HandyRecordingRouterPrototype`;
  rerun the installer to replace them.
- Do not commit generated build output, Handy application data, router state, or
  installed binaries.
- Fetch official Handy changes from the read-only `upstream` remote and push only
  to `origin`, the `kylegl/Handy` fork.
- An upstream Handy update may replace the custom executable. Rebase, rebuild,
  and reinstall this branch before applying an upstream update.

## Install the router

From WSL:

```bash
cd ~/repos/handy-herdr/integrations/herdr-recording-router
./install-prototype.sh
```

The installer:

1. links this directory as the `local.recording-router-prototype` Herdr plugin;
2. copies the Windows wrapper into
   `C:\Users\LINK\AppData\Local\HandyRecordingRouterPrototype`.

## Configure Handy

In Handy settings:

1. Set **Paste method** to **External Script**.
2. Set the script path to
   `C:\Users\LINK\AppData\Local\HandyRecordingRouterPrototype\recording-router.cmd`.
3. Disable **Auto Submit**. The router sends Enter to the selected destination.
4. Keep **Transcribe with Post-Processing** bound to `Ctrl+B`.

The patched Handy executable delegates `Ctrl+B` to the Herdr plugin while Windows
Terminal is foreground. Outside Windows Terminal, Handy handles the shortcut
normally and the wrapper falls back to clipboard paste plus Enter in the active
Windows application.

## Build and install patched Handy

Build from the disposable Windows checkout so Windows-native Rust, Tauri, CMake,
and Vulkan tooling operate on a normal Windows path:

```powershell
cd C:\Users\LINK\source\Handy-herdr-build
bun install --frozen-lockfile --force
bun run tauri build --no-bundle
```

After closing Handy, back up the installed executable and copy:

```text
C:\Users\LINK\source\Handy-herdr-build\src-tauri\target\release\handy.exe
```

into:

```text
C:\Users\LINK\AppData\Local\Handy\handy.exe
```

Then restart Handy. Keep the timestamped executable and settings backups until the
new build has been exercised successfully.

## Try it

1. In a Herdr pane, press `Ctrl+B`.
2. The pane title becomes `🎙 RECORDING`.
3. Dictate, switch to another pane, then press `Ctrl+B` again.
4. The title becomes `… TRANSCRIBING`.
5. Handy sends the post-processed text and Enter to the original pane, then clears
   the marker and route state.

## Reset

```bash
python3 ~/repos/handy-herdr/integrations/herdr-recording-router/router.py reset
```

The prototype supports one recording at a time and expires stale routing state after
15 minutes.
