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
  visible: root.open

  // covers the whole output; any click here (outside the panel itself)
  // closes it. the panel below stops its own clicks from reaching this.
  MouseArea {
    anchors.fill: parent

    onClicked: Dat.Globals.setNetworkPanelOpen(root.modelData.name, false)
  }

  Rectangle {
    id: panel

    anchors.right: parent.right
    anchors.rightMargin: 10
    anchors.top: parent.top
    anchors.topMargin: 34
    color: Dat.Colors.current.surface_container_high
    implicitWidth: 320
    radius: 20

    height: content.height + 28

    Behavior on opacity {
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
