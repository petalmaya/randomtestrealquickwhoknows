pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.Data as Dat
import qs.Generics as Gen

// WlrLayershell is what actually puts a floating panel like this on
// screen, outside any normal window - it's the Wayland "layer shell"
// protocol Quickshell wraps for you. The `open`/`surfaceVisible` split
// below is the standard pattern used by every Layers/*.qml surface: `open`
// is the *logical* state (should this panel be shown right now?), while
// `surfaceVisible` is what the layershell itself actually reads for
// `visible` - it's kept true a little longer via closeLinger so the close
// animation gets to finish before the surface disappears from the screen.
WlrLayershell {
  id: root

  required property ShellScreen modelData

  readonly property bool open: Dat.Launcher.open && Dat.Launcher.outputName == root.modelData.name
  // kept mapped for the duration of the close animation, same pattern as
  // NetPanel/Notch - a WlrLayershell unmaps the instant `visible` flips,
  // which would otherwise cut the close animation short
  property bool surfaceVisible: false

  function close() {
    Dat.Launcher.hide();
  }

  anchors.bottom: true
  anchors.left: true
  anchors.right: true
  anchors.top: true
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  focusable: root.open
  // Exclusive (not OnDemand) is what actually forces the compositor to
  // hand this surface keyboard focus the instant it maps, so typing
  // works immediately without first clicking into the search field -
  // OnDemand only grabs focus once something inside the surface asks
  // for it, which raced against content.requestFocus() below
  keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  layer: WlrLayer.Overlay
  namespace: "kurukuru-launcher"
  screen: root.modelData
  surfaceFormat.opaque: false
  visible: root.surfaceVisible

  onOpenChanged: {
    if (root.open) {
      closeLinger.stop();
      root.surfaceVisible = true;
      content.requestFocus();
      // belt-and-suspenders: the Wayland surface for a just-shown
      // layershell isn't guaranteed to be fully mapped by the
      // compositor in the same tick surfaceVisible flips true, so the
      // immediate forceActiveFocus() above can occasionally land before
      // the surface can actually receive keyboard input. Re-request a
      // moment later once the map has almost certainly gone through.
      refocusTimer.restart();
    } else {
      closeLinger.restart();
    }
  }

  Timer {
    id: refocusTimer

    interval: 30

    onTriggered: content.requestFocus()
  }

  Timer {
    id: closeLinger

    interval: Dat.MaterialEasing.standardAccelTime

    onTriggered: root.surfaceVisible = false
  }

  // covers the whole output; any click here (outside the panel itself)
  // closes it, same click-off pattern as NetPanel
  MouseArea {
    anchors.fill: parent

    onClicked: root.close()
  }

  Rectangle {
    id: panel

    // this used to live on a separate sibling `Item` next to `panel`,
    // which meant it was fighting the search field's TextInput for
    // active focus every time the launcher opened - two unrelated
    // things in the tree both declaratively claiming focus on the same
    // root.open change, racing each other. panel is an actual ancestor
    // of the TextInput (via content/LauncherApps), so putting focus
    // handling here means there's only one focus claim, and unaccepted
    // key events (e.g. Escape once the search field is already empty -
    // see LauncherApps.qml) bubble straight up to it naturally
    focus: root.open

    Keys.onEscapePressed: root.close()
    // Tab cycles apps/wallpaper mode - accepted here (not left to
    // default focus-chain handling) so it never tabs focus out of the
    // panel to something else on the surface
    Keys.onTabPressed: event => {
      Dat.Launcher.cycleMode();
      content.requestFocus();
      event.accepted = true;
    }

    anchors.bottom: parent.bottom
    // fixed relative to the screen, NOT to the panel's own height - this
    // is what keeps the search field pinned in place as the results
    // list grows/shrinks: only `height` above changes, so it's the top
    // edge that moves, never the bottom. carried the 0.309 you'd tuned
    // verticalCenterOffset to over as a starting point, but it's a
    // different reference point now (distance up from the bottom edge,
    // not offset from center) so it'll likely want re-tuning to land in
    // the same visual spot
    anchors.bottomMargin: parent.height * 0.01
    anchors.horizontalCenter: parent.horizontalCenter
    // same withAlpha strategy as the notch bar (Layers/Notch.qml) - panel
    // background stays tinted with the theme's surface color but lets some
    // of the desktop/wallpaper show through instead of being fully opaque
    color: Dat.Colors.withAlpha(Dat.Colors.current.surface_container_high, 0.89)
    // 12 (top margin to modeSwitcher) + 28 (modeSwitcher height) + 10
    // (gap to content) + 12 (bottom padding to match the original
    // content-only 24px), see modeSwitcher/content anchoring below
    height: modeSwitcher.height + content.implicitHeight + 12 + 10 + 12
    implicitWidth: 560
    opacity: root.open ? 1 : 0
    radius: 24
    scale: root.open ? 1 : 0.92
    transformOrigin: Item.Bottom

    Behavior on opacity {
      NumberAnimation {
        duration: root.open ? Dat.MaterialEasing.standardDecelTime : Dat.MaterialEasing.standardAccelTime
        easing.bezierCurve: root.open ? Dat.MaterialEasing.standardDecel : Dat.MaterialEasing.standardAccel
      }
    }

    Behavior on scale {
      NumberAnimation {
        duration: root.open ? Dat.MaterialEasing.standardDecelTime : Dat.MaterialEasing.standardAccelTime
        easing.bezierCurve: root.open ? Dat.MaterialEasing.standardDecel : Dat.MaterialEasing.standardAccel
      }
    }

    Behavior on height {
      NumberAnimation {
        duration: Dat.MaterialEasing.standardTime
        easing.bezierCurve: Dat.MaterialEasing.standard
      }
    }

    // swallow clicks that land on the panel itself so they don't fall
    // through to the full-screen close-catcher behind it
    MouseArea {
      anchors.fill: parent
    }

    // small mode-switcher row - exactly the extension point the handoff
    // notes sketched out ("a small mode-switcher row inside the panel
    // itself"). setMode() clears query but leaves open/outputName alone,
    // so switching tabs doesn't close the panel.
    Row {
      id: modeSwitcher

      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.topMargin: 12
      spacing: 6

      Repeater {
        model: [{
            "mode": "apps",
            "icon": "apps"
          }, {
            "mode": "wallpaper",
            "icon": "wallpaper"
          }]

        Rectangle {
          id: modeTab

          required property var modelData

          color: (Dat.Launcher.mode == modelData.mode) ? Dat.Colors.current.primary_container : "transparent"
          height: 28
          radius: 10
          width: 28

          Gen.MatIcon {
            anchors.centerIn: parent
            color: (modeTab.modelData.mode == Dat.Launcher.mode) ? Dat.Colors.current.on_primary_container : Dat.Colors.current.on_surface_variant
            font.pointSize: 13
            icon: modeTab.modelData.icon
          }

          Gen.MouseArea {
            layerColor: Dat.Colors.current.on_surface
            layerRadius: 10

            onClicked: {
              Dat.Launcher.setMode(modeTab.modelData.mode);
              content.requestFocus();
            }
          }
        }
      }
    }

    // mode is what makes this extendable: "apps" and "wallpaper" today,
    // future modes (command mode) just add a branch here and their own
    // Generics/Launcher*.qml, everything else on this surface (click-off,
    // escape, animation, positioning) stays untouched
    Loader {
      id: content

      function requestFocus() {
        if (content.item && content.item.requestFocus) {
          content.item.requestFocus();
        }
      }

      readonly property real implicitHeight: item ? item.implicitHeight : 0

      anchors.left: parent.left
      anchors.leftMargin: 14
      anchors.right: parent.right
      anchors.rightMargin: 14
      anchors.top: modeSwitcher.bottom
      anchors.topMargin: 10
      sourceComponent: Dat.Launcher.mode == "wallpaper" ? wallpaperMode : appsMode
    }

    Component {
      id: appsMode

      Gen.LauncherApps {
      }
    }

    Component {
      id: wallpaperMode

      Gen.LauncherWallpaper {
      }
    }
  }
}
