pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import qs.Data as Dat

Singleton {
  id: root

  // the currently focused app is a single compositor-wide concept (there's
  // only one focused toplevel at a time), so this one stays global on
  // purpose - every bar showing the same "currently focused app" is correct
  property string actWinName: activeWindow?.activated ? activeWindow?.appId : "desktop"
  readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
  property string hostName: "KuruMi"
  property real mprisDotRotation: 0

  // experimental, not reallllyyy recommended
  property real notchScale: 1

  // --- per-output UI state ---
  // each monitor's notch has its own open/closed state, swipe page,
  // settings tab, hover state, and notification state, keyed by output
  // name (e.g. "eDP-1"), so interacting with one monitor's bar never
  // affects another monitor's bar.
  property var notchStateByOutput: ({})
  property var notchHoveredByOutput: ({})
  property var notifStateByOutput: ({})
  property var settingsTabIndexByOutput: ({})
  property var swipeIndexByOutput: ({})
  property var networkPanelOpenByOutput: ({})

  function networkPanelOpen(outputName) {
    return root.networkPanelOpenByOutput[outputName] ?? false;
  }

  function setNetworkPanelOpen(outputName, value) {
    const updated = Object.assign({}, root.networkPanelOpenByOutput);
    updated[outputName] = value;
    root.networkPanelOpenByOutput = updated;
  }

  function notchState(outputName) {
    return root.notchStateByOutput[outputName] ?? "COLLAPSED";
  }

  function setNotchState(outputName, value) {
    if (root.notchState(outputName) == value)
      return;
    const updated = Object.assign({}, root.notchStateByOutput);
    updated[outputName] = value;
    root.notchStateByOutput = updated;
  }

  function notchHovered(outputName) {
    return root.notchHoveredByOutput[outputName] ?? false;
  }

  function setNotchHovered(outputName, value) {
    const updated = Object.assign({}, root.notchHoveredByOutput);
    updated[outputName] = value;
    root.notchHoveredByOutput = updated;
  }

  function notifState(outputName) {
    return root.notifStateByOutput[outputName] ?? "HIDDEN";
  }

  function setNotifState(outputName, value) {
    const updated = Object.assign({}, root.notifStateByOutput);
    updated[outputName] = value;
    root.notifStateByOutput = updated;
  }

  function settingsTabIndex(outputName) {
    return root.settingsTabIndexByOutput[outputName] ?? 0;
  }

  function setSettingsTabIndex(outputName, value) {
    const updated = Object.assign({}, root.settingsTabIndexByOutput);
    updated[outputName] = value;
    root.settingsTabIndexByOutput = updated;
  }

  function swipeIndex(outputName) {
    return root.swipeIndexByOutput[outputName] ?? 0;
  }

  function setSwipeIndex(outputName, value) {
    const updated = Object.assign({}, root.swipeIndexByOutput);
    updated[outputName] = value;
    root.swipeIndexByOutput = updated;
  }

  // --- notch IPC (keybindable via `qs ipc call notch <fn>`) ---
  // swipe indices into CentralSwipable.qml's tab model
  // (["Home", "Calendar", "System", "Music", "Settings"]) - named here so
  // the IPC functions below don't read as arbitrary magic numbers.
  // WorkspacePill.qml's click handler hardcodes tabIndexSystem's value
  // (2) directly rather than importing this, since it predates this
  // block - fine to leave as is, just know they need to move together
  // if the tab order in CentralSwipable.qml ever changes.
  readonly property int tabIndexSystem: 2
  readonly property int tabIndexMusic: 3

  // best-effort guess at "the screen the user is currently on", for IPC
  // calls that don't specify an output (a global keybind has no idea
  // which monitor you're looking at). Mirrors Data/Launcher.qml's
  // _guessOutput() - kept as a separate copy rather than shared since
  // Launcher's version is private to that singleton.
  function _guessOutput() {
    if (Dat.Niri.active && Dat.Niri.focusedOutput) {
      return Dat.Niri.focusedOutput;
    }
    return Quickshell.screens[0]?.name ?? "";
  }

  // opens the notch to its full pane (tabs + KuruKuru), on whichever tab
  // was last showing - doesn't touch swipeIndex, so repeated calls (or a
  // toggle keybind) land back where you left it.
  function notchOpen(outputName) {
    root.setNotchState(outputName || root._guessOutput(), "FULLY_EXPANDED");
  }

  // same "where should this collapse to" fallback used by
  // onActWinNameChanged below - EXPANDED (small pill-with-content) if
  // there's no focused window to get out of the way of, COLLAPSED
  // otherwise.
  //
  // When reservedShell is on, the bar's whole point is to always occupy
  // its reserved strip of screen space - COLLAPSED sets notchRect's
  // opacity to 0 (see Layers/Notch.qml's state table), which reads as
  // the bar just vanishing, and nothing was reliably re-expanding it
  // afterwards (onActWinNameChanged below bails out early whenever
  // reservedShell is on, so it never got a second chance to fix this up
  // itself - only a keybind calling notchOpen()/notchToggle() again
  // would). So: never let an IPC/keybind-driven close go all the way to
  // COLLAPSED while reservedShell is enabled, floor it at EXPANDED
  // instead, same as the reservedShellChanged handler below already
  // does when the setting is first turned on.
  function notchClose(outputName) {
    const output = outputName || root._guessOutput();
    if (Dat.Config.data.reservedShell) {
      root.setNotchState(output, "EXPANDED");
      return;
    }
    root.setNotchState(output, root.actWinName == "desktop" ? "EXPANDED" : "COLLAPSED");
  }

  function notchToggle(outputName) {
    const output = outputName || root._guessOutput();
    if (root.notchState(output) == "FULLY_EXPANDED") {
      root.notchClose(output);
    } else {
      root.notchOpen(output);
    }
  }

  // opens straight to a specific tab, e.g. for a "media keys should also
  // reveal the media tab" keybind. Always jumps to FULLY_EXPANDED even if
  // already open on a different tab, rather than toggling, since a
  // dedicated media/workspace keybind firing twice in a row should
  // re-affirm that tab, not close the notch out from under you.
  function notchOpenTab(outputName, tabIndex) {
    const output = outputName || root._guessOutput();
    root.setSwipeIndex(output, tabIndex);
    root.setNotchState(output, "FULLY_EXPANDED");
  }

  IpcHandler {
    function close() {
      root.notchClose("");
    }

    function media() {
      root.notchOpenTab("", root.tabIndexMusic);
    }

    function open() {
      root.notchOpen("");
    }

    function toggle() {
      root.notchToggle("");
    }

    function workspaces() {
      root.notchOpenTab("", root.tabIndexSystem);
    }

    target: "notch"
  }

  // true if any monitor currently satisfies the given state / swipe /
  // settings-tab combo. used purely to throttle background polling
  // (Resources, Clock) - doesn't matter *which* monitor, just whether
  // any bar currently needs the data.
  function anyOutputAt(state, swipeIdx, tabIdx) {
    for (const output in root.notchStateByOutput) {
      if (root.notchStateByOutput[output] !== state)
        continue;
      if (swipeIdx !== undefined && root.swipeIndex(output) !== swipeIdx)
        continue;
      if (tabIdx !== undefined && root.settingsTabIndex(output) !== tabIdx)
        continue;
      return true;
    }
    return false;
  }

  // true if the net panel is open on ANY monitor. same throttling idea as
  // anyOutputAt above, just for networkPanelOpenByOutput instead of
  // notchStateByOutput - lets Data/Network.qml stop polling `nmcli` every
  // 15s in the background when nobody's actually looking at the wifi list.
  readonly property bool anyNetworkPanelOpen: {
    for (const output in root.networkPanelOpenByOutput) {
      if (root.networkPanelOpenByOutput[output])
        return true;
    }
    return false;
  }

  readonly property bool anyNotCollapsed: {
    for (const output in root.notchStateByOutput) {
      if (root.notchStateByOutput[output] !== "COLLAPSED")
        return true;
    }
    return false;
  }

  // fixes issue where bar starts collapsed when reserved shell is turned on
  // thanks syncqtc for noticing it :>
  Component.onCompleted: {
    Dat.Config.data.reservedShellChanged.connect(() => {
      if (!Dat.Config.data.reservedShell)
        return;
      for (const screen of Quickshell.screens) {
        if (root.notchState(screen.name) == "COLLAPSED") {
          root.setNotchState(screen.name, "EXPANDED");
        }
      }
    });
  }
  onActWinNameChanged: {
    if (Dat.Config.data.reservedShell) {
      return;
    }
    // the newly focused app could be on any monitor, and we don't get told
    // which - so this reacts uniformly across every bar, same as it always
    // implicitly did, just applied per-output now instead of via one
    // shared variable.
    for (const screen of Quickshell.screens) {
      const state = root.notchState(screen.name);
      if (root.actWinName == "desktop" && state == "COLLAPSED") {
        root.setNotchState(screen.name, "EXPANDED");
      } else if (state == "EXPANDED" && !root.notchHovered(screen.name)) {
        root.setNotchState(screen.name, "COLLAPSED");
      }
    }
  }
}
