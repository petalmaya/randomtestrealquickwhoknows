pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

import qs.Generics as Gen
import qs.Data as Dat

Rectangle {
  id: root

  property string outputName: ""

  color: Dat.Colors.current.surface_container_high
  radius: 20

  Flickable {
    id: flickableRoot

    anchors.fill: parent
    anchors.margins: 10
    clip: true
    contentHeight: coL.height

    ColumnLayout {
      id: coL

      width: flickableRoot.width

      Gen.TweakToggle {
        Layout.fillWidth: true
        active: Dat.Config.data.setWallpaper
        text: "Set Wallpaper"

        onClicked: () => Dat.Config.data.setWallpaper = !Dat.Config.data.setWallpaper
      }

      Gen.WallpaperPicker {
        Layout.fillWidth: true
        Layout.topMargin: 4
        outputName: root.outputName
        visible: Dat.Config.data.setWallpaper
      }
    }
  }
}
