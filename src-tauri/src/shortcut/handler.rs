//! Shared shortcut event handling logic
//!
//! This module contains the common logic for handling shortcut events,
//! used by both the Tauri and handy-keys implementations.

use log::warn;
use std::sync::Arc;
#[cfg(target_os = "windows")]
use std::{
    os::windows::process::CommandExt,
    process::{Command, Stdio},
    sync::atomic::{AtomicBool, Ordering},
    thread,
};
use tauri::{AppHandle, Manager};

use crate::actions::ACTION_MAP;
use crate::managers::audio::AudioRecordingManager;
use crate::settings::get_settings;
use crate::transcription_coordinator::is_transcribe_binding;
use crate::TranscriptionCoordinator;

#[cfg(target_os = "windows")]
static HERDR_DELEGATED_POST_PROCESS_KEY_HELD: AtomicBool = AtomicBool::new(false);
#[cfg(target_os = "windows")]
const CREATE_NO_WINDOW: u32 = 0x08000000;

#[cfg(target_os = "windows")]
fn foreground_is_windows_terminal() -> bool {
    use windows::Win32::UI::WindowsAndMessaging::{GetClassNameW, GetForegroundWindow};

    unsafe {
        let window = GetForegroundWindow();
        if window.0.is_null() {
            return false;
        }

        let mut class_name = [0u16; 256];
        let length = GetClassNameW(window, &mut class_name);
        length > 0
            && String::from_utf16_lossy(&class_name[..length as usize])
                == "CASCADIA_HOSTING_WINDOW_CLASS"
    }
}

#[cfg(target_os = "windows")]
fn delegate_post_process_to_herdr(binding_id: &str, is_pressed: bool) -> bool {
    if binding_id != "transcribe_with_post_process" {
        return false;
    }

    if !is_pressed {
        return HERDR_DELEGATED_POST_PROCESS_KEY_HELD.swap(false, Ordering::SeqCst);
    }

    if !foreground_is_windows_terminal() {
        return false;
    }

    let command = std::env::var("HANDY_HERDR_COMMAND").unwrap_or_else(|_| {
        concat!(
            "PATH=\"$HOME/.local/bin:$PATH\"; ",
            "herdr plugin action invoke local.recording-router-prototype.toggle"
        )
        .to_string()
    });
    let distro = std::env::var("HANDY_HERDR_WSL_DISTRO")
        .ok()
        .filter(|value| !value.trim().is_empty());

    thread::spawn(move || {
        let mut delegate = Command::new("wsl.exe");
        if let Some(distro) = distro {
            delegate.args(["-d", &distro]);
        }
        let status = delegate
            .args(["--", "sh", "-lc", &command])
            .creation_flags(CREATE_NO_WINDOW)
            .stdin(Stdio::null())
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status();

        if status.is_ok_and(|status| status.success()) {
            return;
        }

        warn!("Failed to delegate post-processing shortcut to Herdr; falling back to Handy");
        if let Ok(executable) = std::env::current_exe() {
            let _ = Command::new(executable)
                .arg("--toggle-post-process")
                .creation_flags(CREATE_NO_WINDOW)
                .stdin(Stdio::null())
                .stdout(Stdio::null())
                .stderr(Stdio::null())
                .spawn();
        }
    });

    HERDR_DELEGATED_POST_PROCESS_KEY_HELD.store(true, Ordering::SeqCst);
    true
}

#[cfg(not(target_os = "windows"))]
fn delegate_post_process_to_herdr(_binding_id: &str, _is_pressed: bool) -> bool {
    false
}

/// Handle a shortcut event from either implementation.
///
/// This function contains the shared logic for:
/// - Looking up the action in ACTION_MAP
/// - Handling the cancel binding (only fires when recording)
/// - Handling push-to-talk mode (start on press, stop on release)
/// - Handling toggle mode (toggle state on press only)
///
/// # Arguments
/// * `app` - The Tauri app handle
/// * `binding_id` - The ID of the binding (e.g., "transcribe", "cancel")
/// * `hotkey_string` - The string representation of the hotkey
/// * `is_pressed` - Whether this is a key press (true) or release (false)
pub fn handle_shortcut_event(
    app: &AppHandle,
    binding_id: &str,
    hotkey_string: &str,
    is_pressed: bool,
) {
    if delegate_post_process_to_herdr(binding_id, is_pressed) {
        return;
    }

    let settings = get_settings(app);

    // Transcribe bindings are handled by the coordinator.
    if is_transcribe_binding(binding_id) {
        if let Some(coordinator) = app.try_state::<TranscriptionCoordinator>() {
            coordinator.send_input(binding_id, hotkey_string, is_pressed, settings.push_to_talk);
        } else {
            warn!("TranscriptionCoordinator is not initialized");
        }
        return;
    }

    let Some(action) = ACTION_MAP.get(binding_id) else {
        warn!(
            "No action defined in ACTION_MAP for shortcut ID '{}'. Shortcut: '{}', Pressed: {}",
            binding_id, hotkey_string, is_pressed
        );
        return;
    };

    // Cancel binding: only fires when recording and key is pressed
    if binding_id == "cancel" {
        let audio_manager = app.state::<Arc<AudioRecordingManager>>();
        if audio_manager.is_recording() && is_pressed {
            action.start(app, binding_id, hotkey_string);
        }
        return;
    }

    // Remaining bindings (e.g. "test") use simple start/stop on press/release.
    if is_pressed {
        action.start(app, binding_id, hotkey_string);
    } else {
        action.stop(app, binding_id, hotkey_string);
    }
}
