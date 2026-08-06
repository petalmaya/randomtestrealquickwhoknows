pragma Singleton
import QtQuick
import Quickshell
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
