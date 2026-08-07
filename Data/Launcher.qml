pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

import qs.Data as Dat

// Central state for the app launcher popup. Mirrors the
// networkPanelOpenByOutput pattern in Globals.qml but lives on its own
// singleton since the launcher carries more state (search query, mode)
// than a plain bool, and is meant to grow: `mode` is what makes this
// extendable - "apps" today, "wallpaper" / "command" later on, each
// driven by its own Generics/Launcher*.qml content component picked by
// Layers/Launcher.qml. Adding a mode later means adding a value here and
// a branch in the Loader, not touching the surface/animation/click-off
// plumbing at all.
Singleton {
  id: root

  // name of the mode used when the launcher is first opened / reset
  readonly property string defaultMode: "apps"

  property bool open: false
  // which screen currently owns the launcher - only that screen's
  // Layers/Launcher.qml instance actually shows itself
  property string outputName: ""
  property string mode: root.defaultMode
  property string query: ""

  // best-effort guess at "the screen the user is currently on", used
  // when show()/toggle() is called without an explicit output (e.g. a
  // global IPC keybind, which has no idea which monitor you're looking
  // at). Falls back to the first screen if the compositor integration
  // isn't reporting anything yet.
  function _guessOutput() {
    if (Dat.Niri.active && Dat.Niri.focusedOutput) {
      return Dat.Niri.focusedOutput;
    }
    return Quickshell.screens[0]?.name ?? "";
  }

  function show(outputName) {
    root.outputName = outputName || root._guessOutput();
    root.mode = root.defaultMode;
    root.query = "";
    root.open = true;
  }

  function hide() {
    root.open = false;
  }

  function toggle(outputName) {
    if (root.open) {
      root.hide();
    } else {
      root.show(outputName);
    }
  }

  // switches mode without closing the launcher (e.g. a future
  // "command mode" toggle inside the launcher itself)
  function setMode(m) {
    root.mode = m;
    root.query = "";
  }

  IpcHandler {
    function toggle() {
      root.toggle("");
    }

    function open() {
      root.show("");
    }

    function close() {
      root.hide();
    }

    target: "launcher"
  }
}
