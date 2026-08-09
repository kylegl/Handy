# Recording Router Prototype

> **Throwaway prototype.** It tests whether a Herdr action can remember a pane,
> mark it as recording, and route Handy output back to it after focus changes.

Agents maintaining or configuring this integration must first read the canonical
[maintenance and placement guide](../../.agents/docs/recording-router.md).

## Install

```bash
cd ~/repos/herdr-handy/integrations/herdr-recording-router
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
python3 ~/repos/herdr-handy/integrations/herdr-recording-router/router.py reset
```
