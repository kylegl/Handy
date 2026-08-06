# Recording Router Prototype

> **Throwaway prototype.** It tests whether a Herdr action can remember a pane,
> mark it as recording, and route Handy output back to it after focus changes.

## Install

```bash
./install-prototype.sh
```

This integration lives with the prototype Handy build in
`~/repos/handy-herdr`. Configure Handy:

1. Set **Paste method** to **External Script**.
2. Set the script path to
   `C:\Users\LINK\AppData\Local\HandyRecordingRouterPrototype\recording-router.cmd`.
3. Disable **Auto Submit**. The router sends Enter to the target itself.

## Try it

1. In a Herdr pane, press `Ctrl+B`.
2. The pane title becomes `🎙 RECORDING`.
3. Dictate, switch to another pane, then press `Ctrl+B` again.
4. The title becomes `… TRANSCRIBING`.
5. Handy sends the transcript and Enter to the original pane, then the marker clears.

Outside Windows Terminal, Handy handles `Ctrl+B` normally and the external script
falls back to clipboard paste plus Enter in the focused Windows application.

## Reset

```bash
python3 router.py reset
```

The prototype supports one recording at a time and expires stale routing state after
15 minutes.
