#!/usr/bin/env python3
"""PROTOTYPE: route one Handy transcription back to its originating Herdr pane."""

from __future__ import annotations

import contextlib
import json
import os
import subprocess
import sys
import time
from pathlib import Path

STATE_PATH = Path("/tmp/herdr-recording-router-prototype.json")
METADATA_SOURCE = "plugin:local.recording-router-prototype"
MAX_AGE_SECONDS = 15 * 60


def config_path() -> Path:
    configured = os.environ.get("HANDY_HERDR_CONFIG")
    if configured:
        return Path(configured).expanduser()
    config_home = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    return config_home / "handy" / "herdr-recording-router.json"


def load_config() -> dict:
    try:
        return json.loads(config_path().read_text())
    except FileNotFoundError as error:
        raise RuntimeError(
            f"Missing {config_path()}; run install-prototype.sh first"
        ) from error


def handy_executable() -> str:
    configured = os.environ.get("HANDY_EXE") or load_config().get("handy_exe")
    if not configured:
        raise RuntimeError("handy_exe is not configured")
    return configured


def load_state() -> dict | None:
    try:
        state = json.loads(STATE_PATH.read_text())
    except (FileNotFoundError, json.JSONDecodeError):
        return None
    if time.time() - state.get("started_at", 0) > MAX_AGE_SECONDS:
        clear_indicator(state)
        STATE_PATH.unlink(missing_ok=True)
        return None
    return state


def herdr(state: dict, *args: str, capture: bool = True) -> subprocess.CompletedProcess[str]:
    env = os.environ.copy()
    env["HERDR_ENV"] = "1"
    env["HERDR_SOCKET_PATH"] = state["socket_path"]
    return subprocess.run(
        [state.get("herdr_bin", "herdr"), *args],
        env=env,
        text=True,
        capture_output=capture,
        check=False,
    )


def set_indicator(state: dict, title: str) -> None:
    herdr(
        state,
        "pane",
        "report-metadata",
        state["pane_id"],
        "--source",
        METADATA_SOURCE,
        "--title",
        title,
        "--ttl-ms",
        str(MAX_AGE_SECONDS * 1000),
    )


def clear_indicator(state: dict) -> None:
    with contextlib.suppress(KeyError, OSError):
        herdr(
            state,
            "pane",
            "report-metadata",
            state["pane_id"],
            "--source",
            METADATA_SOURCE,
            "--clear-title",
        )


def toggle() -> int:
    state = load_state()
    if state is None:
        pane_id = os.environ.get("HERDR_PANE_ID")
        socket_path = os.environ.get("HERDR_SOCKET_PATH")
        if not pane_id or not socket_path:
            print("Recording router must be invoked from a Herdr pane", file=sys.stderr)
            return 1
        state = {
            "pane_id": pane_id,
            "socket_path": socket_path,
            "herdr_bin": os.environ.get("HERDR_BIN_PATH", "herdr"),
            "started_at": time.time(),
            "phase": "recording",
        }
        STATE_PATH.write_text(json.dumps(state))
        set_indicator(state, "🎙 RECORDING")
    else:
        state["phase"] = "transcribing"
        STATE_PATH.write_text(json.dumps(state))
        set_indicator(state, "… TRANSCRIBING")

    result = subprocess.run([handy_executable(), "--toggle-post-process"], check=False)
    if result.returncode != 0:
        clear_indicator(state)
        STATE_PATH.unlink(missing_ok=True)
    return result.returncode


def deliver() -> int:
    transcript = sys.stdin.read()
    state = load_state()
    if state is None:
        return 75  # Not handled: Windows wrapper should use normal paste.

    pane = herdr(state, "pane", "get", state["pane_id"])
    if pane.returncode != 0:
        clear_indicator(state)
        STATE_PATH.unlink(missing_ok=True)
        return 75

    try:
        sent = herdr(state, "pane", "send-text", state["pane_id"], transcript)
        if sent.returncode != 0:
            return 75
        submitted = herdr(state, "pane", "send-keys", state["pane_id"], "enter")
        if submitted.returncode != 0:
            return 75
        return 0
    finally:
        clear_indicator(state)
        STATE_PATH.unlink(missing_ok=True)


def reset() -> int:
    state = load_state()
    if state is not None:
        clear_indicator(state)
    STATE_PATH.unlink(missing_ok=True)
    return 0


def main() -> int:
    commands = {"toggle": toggle, "deliver": deliver, "reset": reset}
    if len(sys.argv) != 2 or sys.argv[1] not in commands:
        print("usage: router.py toggle|deliver|reset", file=sys.stderr)
        return 2
    return commands[sys.argv[1]]()


if __name__ == "__main__":
    raise SystemExit(main())
