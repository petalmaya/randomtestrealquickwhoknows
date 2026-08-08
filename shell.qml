//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick
import qs.Layers as Lay
import qs.Data as Dat

// This is the shell's "main()" - the one file Quickshell actually loads on
// startup. All it does is decide WHAT gets shown and on WHICH monitor; the
// actual look/behavior of each piece lives in its own file under Layers/.
ShellRoot {
  // Variants repeats everything inside it once per entry in `model` - here
  // that's Quickshell.screens, so you automatically get one full set of
  // bar/launcher/etc. per connected monitor, with no manual "if 2 screens
  // do X" logic. Unplug a monitor and its Scope (and everything in it)
  // just goes away.
  Variants {
    model: Quickshell.screens

    // One Scope per monitor. `modelData` is that monitor's ShellScreen,
    // passed down to every Layers/*.qml surface below so each one knows
    // which physical screen it belongs to.
    Scope {
      id: scopeRoot

      required property ShellScreen modelData

      // LazyLoader only builds its `component` when `activeAsync` is true,
      // and tears it back down when it goes false. Used here for the two
      // optional/config-gated surfaces so they cost nothing (no QML
      // objects, no timers) when the user hasn't turned them on.
      LazyLoader {
        activeAsync: Dat.Config.data.reservedShell

        component: Lay.PseudoReserved {
          modelData: scopeRoot.modelData
        }
      }

      LazyLoader {
        activeAsync: Dat.Config.data.setWallpaper

        component: Lay.Wallpaper {
          modelData: scopeRoot.modelData
        }
      }

      // The rest of these always exist per-monitor (not lazy) since
      // they're core to the bar, not optional extras.
      Lay.Notch {
        modelData: scopeRoot.modelData
      }

      Lay.NetPanel {
        modelData: scopeRoot.modelData
      }

      Lay.Launcher {
        modelData: scopeRoot.modelData
      }

      Lay.VolumeOsd {
        modelData: scopeRoot.modelData
      }

      // Quickshell shows a popup by default whenever it hot-reloads the
      // config (or fails to). Both handlers below just tell it "don't" -
      // useful once you're actively editing files and reloading a lot.
      Connections {
        function onReloadCompleted() {
          Quickshell.inhibitReloadPopup();
        }

        function onReloadFailed() {
          Quickshell.inhibitReloadPopup();
        }

        target: Quickshell
      }
    }
  }

  // The lock screen is deliberately outside the per-screen Variants above -
  // there's only ever one lock session for the whole system, not one per
  // monitor, so it gets a single instance here instead of living inside
  // scopeRoot like the per-output surfaces do.
  Lay.LockScreen {
  }
}
