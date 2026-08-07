pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

import qs.Data as Dat
import qs.Generics as Gen

// Small bottom-center pill that pops up whenever the default sink's
// volume or mute state changes, then auto-hides. Purely visual - it
// never takes input, so it never needs a click-off/escape story like
// NetPanel or the notch do.
WlrLayershell {
  id: root

  required property ShellScreen modelData

  // ignore the very first volume/mute change that fires as Pipewire
  // hands us the default sink on startup - only real user-driven
  // changes after that should pop the OSD
  property bool ready: false
  property bool osdVisible: false
  property real displayVolume: 0
  property bool displayMuted: false

  function pulse() {
    if (!root.ready)
      return;

    root.displayVolume = Dat.Audio.volume ?? 0;
    root.displayMuted = Dat.Audio.muted ?? false;
    root.osdVisible = true;
    hideTimer.restart();
  }

  anchors.bottom: true
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  focusable: false
  implicitHeight: 110
  implicitWidth: 240
  layer: WlrLayer.Overlay
  namespace: "kurukuru-volume-osd"
  screen: root.modelData
  surfaceFormat.opaque: false
  visible: root.osdVisible

  // empty mask - this surface never captures clicks/keys, it's purely
  // an overlay indicator
  mask: Region {
  }

  Connections {
    target: Dat.Audio

    function onMutedChanged() {
      root.pulse();
    }

    function onVolumeChanged() {
      root.pulse();
    }
  }

  Timer {
    // give Pipewire a moment to report the real default sink before we
    // start reacting to changes, so app startup doesn't itself pop the OSD
    id: readyTimer

    interval: 500
    running: true

    onTriggered: root.ready = true
  }

  Timer {
    id: hideTimer

    interval: 1400

    onTriggered: root.osdVisible = false
  }

  Rectangle {
    id: pill

    // the launcher's search field sits bottom-center too - lift the OSD
    // well clear of it while the launcher is open on this screen, so
    // the two never overlap
    readonly property bool launcherUp: Dat.Launcher.open && Dat.Launcher.outputName == root.modelData.name

    anchors.bottom: parent.bottom
    anchors.bottomMargin: pill.launcherUp ? 200 : 46
    anchors.horizontalCenter: parent.horizontalCenter
    color: Dat.Colors.current.surface_container_high
    height: 56
    opacity: root.osdVisible ? 1 : 0
    radius: 18
    scale: root.osdVisible ? 1 : 0.85
    transformOrigin: Item.Bottom
    width: 200

    Behavior on anchors.bottomMargin {
      NumberAnimation {
        duration: Dat.MaterialEasing.standardTime
        easing.bezierCurve: Dat.MaterialEasing.standard
      }
    }

    Behavior on opacity {
      NumberAnimation {
        duration: root.osdVisible ? Dat.MaterialEasing.standardDecelTime : Dat.MaterialEasing.standardAccelTime
        easing.bezierCurve: root.osdVisible ? Dat.MaterialEasing.standardDecel : Dat.MaterialEasing.standardAccel
      }
    }

    Behavior on scale {
      NumberAnimation {
        duration: root.osdVisible ? Dat.MaterialEasing.standardDecelTime : Dat.MaterialEasing.standardAccelTime
        easing.bezierCurve: root.osdVisible ? Dat.MaterialEasing.standardDecel : Dat.MaterialEasing.standardAccel
      }
    }

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: 14
      anchors.rightMargin: 14
      spacing: 10

      Gen.MatIcon {
        color: root.displayMuted ? Dat.Colors.current.error : Dat.Colors.current.on_surface
        font.pointSize: 16
        icon: root.displayMuted ? "volume_off" : (root.displayVolume > 0.5 ? "volume_up" : root.displayVolume > 0.01 ? "volume_down" : "volume_mute")
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 6
        color: Dat.Colors.current.surface_container_highest
        radius: 3

        Rectangle {
          color: root.displayMuted ? Dat.Colors.current.outline : Dat.Colors.current.primary
          height: parent.height
          radius: 3
          width: parent.width * Math.max(0, Math.min(root.displayVolume, 1))

          Behavior on width {
            NumberAnimation {
              duration: 120
              easing.type: Easing.OutQuad
            }
          }
        }
      }

      Text {
        Layout.preferredWidth: 34
        color: Dat.Colors.current.on_surface
        font.pointSize: 9
        horizontalAlignment: Text.AlignRight
        text: root.displayMuted ? "mute" : Math.round(root.displayVolume * 100) + "%"
      }
    }
  }
}
