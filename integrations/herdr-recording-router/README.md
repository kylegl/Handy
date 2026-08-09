# Recording Router Prototype

> **Throwaway prototype.** It tests whether a Herdr action can remember a pane,
> mark it as recording, and route Handy output back to it after focus changes.

Agents maintaining or configuring this integration must first read the canonical
[maintenance and placement guide](../../.agents/docs/recording-router.md).

## Machine configuration

The installer creates `${XDG_CONFIG_HOME:-$HOME/.config}/handy/herdr-recording-router.json` for machine-specific Handy, Windows wrapper, build-checkout, and WSL paths. Set `HANDY_HERDR_CONFIG` to override this location.

The generated file is untracked and must not be committed. See [`config.example.json`](config.example.json) for its schema and the [maintenance and placement guide](../../.agents/docs/recording-router.md) for operational details.

## Install

```bash
cd ~/repos/Handy/integrations/herdr-recording-router
./install-prototype.sh
```

Configure Handy:

1. Keep **Transcribe with Post-Processing** bound to `Ctrl+B`.
2. Set **Paste method** to **External Script**.
3. Set the script path to the `windows_wrapper_dir_windows` value from the
   generated machine configuration, followed by `\recording-router.cmd`.
4. Disable **Auto Submit**. The router sends Enter to the selected destination.

## Use

1. In a Herdr pane, press `Ctrl+B`.
2. The pane title becomes `🎙 RECORDING`.
3. Dictate, switch to another pane, then press `Ctrl+B` again.
4. The title becomes `… TRANSCRIBING`.
5. Handy sends the post-processed text and Enter to the original pane, then clears
   the marker and route state.

Outside Windows Terminal, Handy handles `Ctrl+B` normally and the external script
falls back to clipboard paste plus Enter in the active Windows application.

## Reset

```bash
python3 ~/repos/Handy/integrations/herdr-recording-router/router.py reset
```
