# Recording Router Maintenance and Placement

This is the canonical operational guide for agents maintaining the Handy–Herdr recording-router integration. Read it before changing, building, installing, relocating, or updating any integration component.

## Component placement

The integration currently uses fixed paths. Keep each component at the location shown below unless all references to that path are updated together.

| Component | Required location | Ownership |
| --- | --- | --- |
| Canonical monorepo | `~/repos/handy-herdr` | Source of truth for the Handy fork and router |
| Router source | `~/repos/handy-herdr/integrations/herdr-recording-router` | Herdr plugin and installer source |
| Windows build checkout | `C:\Users\LINK\source\Handy-herdr-build` | Disposable Windows-native checkout used only to compile Handy |
| Installed Handy | `C:\Users\LINK\AppData\Local\Handy\handy.exe` | Runtime executable used by the router |
| Installed Windows wrapper | `C:\Users\LINK\AppData\Local\HandyRecordingRouterPrototype` | Generated runtime copies of `recording-router.cmd` and `.ps1` |
| Handy settings | `%APPDATA%\com.pais.handy\settings_store.json` | Runtime paste-method and external-script configuration |
| Router state | `/tmp/herdr-recording-router-prototype.json` | Ephemeral one-shot route for the active recording |

## Source-of-truth rules

- Edit Handy and router sources only in `~/repos/handy-herdr`.
- Edit the router only under `integrations/herdr-recording-router`.
- Never edit files copied into `%LOCALAPPDATA%\HandyRecordingRouterPrototype`; rerun the installer to replace them.
- Treat the Windows build checkout as disposable. Do not make canonical changes there.
- Do not commit generated build output, Handy application data, router state, installed wrappers, binaries, or timestamped backups.
- Fetch official Handy changes from the fetch-only `upstream` remote.
- Push maintained work only to `origin`, the `kylegl/Handy` fork.
- An upstream Handy update may replace the custom executable. Rebase, rebuild, and reinstall this branch before applying one.

## Fixed-path references

When relocating a component, search and update every affected reference before reinstalling:

```bash
rg -n 'handy-herdr|HandyRecordingRouterPrototype|Ubuntu-20.04|/home/linkdevk|C:\\Users\\LINK' \
  src-tauri/src/shortcut/handler.rs \
  integrations/herdr-recording-router \
  .agents/docs/recording-router.md
```

The Handy shortcut delegation currently contains the WSL distribution, Herdr binary, plugin action, and installed Handy paths. The PowerShell wrapper contains the canonical WSL router path. The installer contains the Windows wrapper destination.

## Herdr plugin installation

Run from WSL:

```bash
cd ~/repos/handy-herdr/integrations/herdr-recording-router
./install-prototype.sh
```

The installer must:

1. link this canonical source directory as `local.recording-router-prototype`;
2. copy the Windows wrapper into `C:\Users\LINK\AppData\Local\HandyRecordingRouterPrototype`.

Verify the linked source after installation:

```bash
herdr plugin list --plugin local.recording-router-prototype --json
```

The reported `plugin_root` must point into `~/repos/handy-herdr`, not a retired standalone checkout.

## Handy runtime configuration

Handy must be configured with:

| Setting | Required value |
| --- | --- |
| Transcribe with Post-Processing shortcut | `Ctrl+B` |
| Paste method | `External Script` |
| External script | `C:\Users\LINK\AppData\Local\HandyRecordingRouterPrototype\recording-router.cmd` |
| Auto Submit | Disabled |

The router owns submission so Enter reaches the same destination as the Final Text. Enabling Handy Auto Submit would send Enter to whichever Windows application is focused after the external script returns.

Before editing `settings_store.json` directly:

1. stop Handy;
2. make a timestamped backup;
3. update only the required settings;
4. restart Handy and verify the loaded settings in its logs.

Prefer the Handy settings UI when automation is unnecessary.

## Windows build checkout

Windows-native Rust, Tauri, CMake, and Vulkan tooling should build from a normal Windows path. The canonical WSL checkout remains the source of truth.

Create the disposable build checkout from the pushed integration branch:

```powershell
git clone --branch main `
  https://github.com/kylegl/Handy.git `
  C:\Users\LINK\source\Handy-herdr-build
```

Refresh an existing checkout instead of editing it:

```powershell
cd C:\Users\LINK\source\Handy-herdr-build
git fetch origin
git reset --hard origin/main
```

Build:

```powershell
bun install --frozen-lockfile --force
bun run tauri build --no-bundle
```

The built executable is:

```text
C:\Users\LINK\source\Handy-herdr-build\src-tauri\target\release\handy.exe
```

## Installing patched Handy

1. Stop the running Handy process.
2. Back up `C:\Users\LINK\AppData\Local\Handy\handy.exe` with a timestamp.
3. Copy the built executable over the installed executable.
4. Restart Handy.
5. Confirm the process uses the expected path.
6. Exercise `Ctrl+B` inside and outside Herdr before removing any backup.

Do not copy source files or build directories into the Handy installation directory.

## Validation

Validate the integration end to end:

1. Focus a Herdr pane and press `Ctrl+B`.
2. Confirm its title becomes `🎙 RECORDING`.
3. Dictate and move focus to another pane.
4. Press `Ctrl+B` again.
5. Confirm the title becomes `… TRANSCRIBING`.
6. Confirm post-processed text and Enter arrive in the Origin Pane.
7. Confirm the pane marker and `/tmp/herdr-recording-router-prototype.json` are cleared.
8. Press `Ctrl+B` outside Windows Terminal and confirm ordinary focused-application delivery.
9. Confirm no console window flashes during shortcut delegation or external-script delivery.

Handy debug logs should show `transcribe_with_post_process`, an LLM post-processing request and successful result, followed by `PasteMethod::ExternalScript`.

## Updating from official Handy

From the canonical monorepo:

```bash
git fetch upstream
git rebase upstream/main
```

Resolve conflicts only in the canonical checkout. Then:

1. run relevant formatting, diagnostics, and tests;
2. push the maintained branch to `origin`;
3. refresh the Windows build checkout from `origin`;
4. rebuild and reinstall Handy;
5. rerun the end-to-end validation.

The official `upstream` push URL is intentionally disabled. Do not re-enable it.

## Recovery

Clear stale router state and pane metadata:

```bash
python3 ~/repos/handy-herdr/integrations/herdr-recording-router/router.py reset
```

If a custom build fails, restore the latest timestamped Handy executable backup and restart Handy. If settings fail, stop Handy, restore the latest settings backup, and restart it.
