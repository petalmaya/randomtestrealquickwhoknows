pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Wayland
import Quickshell
import Quickshell.Io

import qs.Data as Dat
import qs.Containers as Con

Scope {
  id: root

  property alias lock: lock
  // output name -> notchState it had right before we locked, so unlocking
  // restores every monitor's bar to how it was, not just one
  property var prevStateByOutput: ({})

  WlSessionLock {
    id: lock

    onLockedChanged: {
      if (lock.locked)
        return;
      for (const screen of Quickshell.screens) {
        const prev = root.prevStateByOutput[screen.name] ?? "COLLAPSED";
        Dat.Globals.setNotchState(screen.name, prev);
      }
    }

    Con.LockScreenSurface {
      lock: lock
    }
  }

  IpcHandler {
    function lock() {
      const saved = {};
      for (const screen of Quickshell.screens) {
        saved[screen.name] = Dat.Globals.notchState(screen.name);
        Dat.Globals.setNotchState(screen.name, "COLLAPSED");
      }
      root.prevStateByOutput = saved;
      locker.start();
    }

    function unlock() {
      lock.locked = false;
    }

    target: "lockscreen"
  }

  Timer {
    id: locker

    interval: 250

    onTriggered: lock.locked = true
  }
}
