# Pane-Targeted Transcription

This context covers speech transcription whose final text is delivered either to the Herdr pane where recording began or, when no pane route exists, to the active Windows application.

## Language

**Recording**:
A single captured-audio session initiated by a transcription shortcut and ended before transcription begins.
_Avoid_: Capture, dictation session

**Transcription**:
The text produced from a Recording by speech recognition, before optional Post-Processing.
_Avoid_: Transcript output, raw text

**Post-Processing**:
Optional language-model cleanup applied to a Transcription before delivery without intentionally changing its meaning.
_Avoid_: Transcription, formatting

**Final Text**:
The text selected for delivery after transcription and any requested Post-Processing have completed.
_Avoid_: Output, result, transcript

**Origin Pane**:
The Herdr pane focused when a routed Recording begins. It remains the authoritative destination even if focus moves elsewhere.
_Avoid_: Active pane, current pane, recording pane

**Recording Route**:
A one-shot association between an active Recording and its Origin Pane.
_Avoid_: Pane state, target file

**Routed Delivery**:
Delivery of Final Text directly to the Origin Pane, independent of the pane or application focused at delivery time.
_Avoid_: Paste, focused paste

**Fallback Delivery**:
Delivery of Final Text to the active Windows application when no valid Recording Route exists.
_Avoid_: Routed delivery, pane delivery

**Submission**:
The Enter key action performed after Final Text is delivered to its destination.
_Avoid_: Delivery, paste
