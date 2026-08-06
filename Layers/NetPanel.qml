pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.Data as Dat
import qs.Generics as Gen

WlrLayershell {
  id: root

  required property ShellScreen modelData

  readonly property bool open: Dat.Globals.networkPanelOpen(root.modelData.name)
  // kept true for the duration of the close animation so the surface
  // doesn't just vanish the instant `open` flips - mirrors the
  // visible/PropertyAction dance the notch does for its own transitions
  property bool surfaceVisible: false

  function close() {
    Dat.Globals.setNetworkPanelOpen(root.modelData.name, false);
  }

  anchors.bottom: true
  anchors.left: true
  anchors.right: true
  anchors.top: true
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  focusable: root.open
  keyboardFocus: root.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  layer: WlrLayer.Overlay
  namespace: "kurukuru-netpanel"
  screen: root.modelData
  surfaceFormat.opaque: false
  visible: root.surfaceVisible

  onOpenChanged: {
    if (root.open) {
      closeLinger.stop();
      root.surfaceVisible = true;
    } else {
      // let the close animation on `panel` finish before unmapping
      closeLinger.restart();
    }
  }

  Timer {
    id: closeLinger

    interval: Dat.MaterialEasing.standardAccelTime

    onTriggered: root.surfaceVisible = false
  }

  // covers the whole output; any click here (outside the panel itself)
  // closes it. the panel below stops its own clicks from reaching this.
  // esc does the same, via the focus scope below.
  MouseArea {
    anchors.fill: parent

    onClicked: root.close()
  }

  Item {
    id: focusScope

    anchors.fill: parent
    focus: root.open

    Keys.onEscapePressed: root.close()
  }

  Rectangle {
    id: panel

    anchors.right: parent.right
    anchors.rightMargin: 10
    anchors.top: parent.top
    anchors.topMargin: 34
    color: Dat.Colors.current.surface_container_high
    height: content.height + 28
    implicitWidth: 320
    opacity: root.open ? 1 : 0
    radius: 20
    scale: root.open ? 1 : 0.88
    transformOrigin: Item.TopRight

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

    Gen.NetworkPanel {
      id: content

      anchors.left: parent.left
      anchors.leftMargin: 14
      anchors.right: parent.right
      anchors.rightMargin: 14
      anchors.top: parent.top
      anchors.topMargin: 14
    }
  }
}
