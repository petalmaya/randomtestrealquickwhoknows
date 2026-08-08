pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property alias idleInhibited: persist.enabled

  function poweroff() {
    // Raw `poweroff`/`reboot` binaries need root and just fail silently
    // (execDetached has no stdout/stderr for you to notice) for a normal
    // user - go through systemd instead, same as suspend() already does,
    // which is allowed for the active session via logind/polkit without
    // needing to be root.
    Quickshell.execDetached(["systemctl", "poweroff"]);
  }

  function reboot() {
    Quickshell.execDetached(["systemctl", "reboot"]);
  }

  function suspend() {
    // Was `loginctl lock-session`, which asks logind/the compositor for
    // whatever *its* default lock is - not this shell's own IpcHandler
    // ("lockscreen" target) that drives Layers/LockScreen.qml. Depending
    // on compositor config that could mean no lock screen at all, or the
    // wrong one, on wake. Go through our own IPC target instead so
    // suspending always shows the shell's actual lock screen.
    Quickshell.execDetached(["qs", "ipc", "call", "lockscreen", "lock"]);
    Quickshell.execDetached(["systemctl", "suspend"]);
  }

  // Was start/stop-ing "hypridle.service" here on top of the
  // systemd-inhibit Process below - hypridle is Hyprland's idle daemon,
  // this shell targets niri/mangowc (see CLAUDE.md), so that service
  // almost certainly doesn't exist on this system. execDetached() has no
  // stdout/stderr to notice a failure with (same gotcha poweroff()'s
  // comment already calls out), so it was silently no-op-ing every
  // toggle instead of erroring - never actually did anything, for better
  // or worse. The systemd-inhibit Process below is compositor-agnostic
  // (goes through logind, not a Hyprland-specific daemon) and is the only
  // piece of this that was actually inhibiting idle - toggling it is now
  // the whole implementation.
  function toggleIdle() {
    root.idleInhibited = !root.idleInhibited;
  }

  PersistentProperties {
    id: persist

    property bool enabled: false

    reloadableId: "idleInhibitor"
  }

  Process {
    command: ["systemd-inhibit", "--what=idle", "--who=kurukurubar", "--why=Manually Blocked Idle", "--mode=block", "sleep", "inf"]
    running: root.idleInhibited
  }
}
