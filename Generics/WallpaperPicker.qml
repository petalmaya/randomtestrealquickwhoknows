import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Qt.labs.platform as Labs

import qs.Data as Dat
import qs.Generics as Gen

// Browsable grid of wallpapers from Dat.Config.data.wallpaperDir, plus a
// native "Browse" file dialog for picking any image on disk.
//
// When outputName is set (this picker is embedded in a per-monitor bar),
// a small toggle lets you edit either that monitor's own override or the
// shared default, and clicking a thumbnail writes through
// Dat.Config.setWallpaperFor(...), which Layers/Wallpaper.qml watches per
// output and animates into.
ColumnLayout {
  id: root

  // the output this picker's bar lives on, e.g. "eDP-1". Leave empty to
  // always edit the shared default wallpaper.
  property string outputName: ""
  // true = editing the shared default even though outputName is set
  property bool editingDefault: outputName == ""
  readonly property string targetOutput: editingDefault ? "" : outputName
  readonly property string currentSrc: Dat.Config.wallpaperFor(root.targetOutput)
  readonly property bool hasOverride: outputName != "" && Dat.Config.data.wallpapersByOutput && Dat.Config.data.wallpapersByOutput[outputName] !== undefined

  spacing: 8

  RowLayout {
    Layout.fillWidth: true
    spacing: 6
    visible: root.outputName != ""

    Repeater {
      model: [{
          "label": "This Display",
          "isDefault": false
        }, {
          "label": "Default",
          "isDefault": true
        }]

      Rectangle {
        id: chip

        required property var modelData

        Layout.fillHeight: true
        color: (root.editingDefault == modelData.isDefault) ? Dat.Colors.current.primary : Dat.Colors.current.surface_container
        implicitHeight: 24
        implicitWidth: chipText.contentWidth + 18
        radius: 8

        Text {
          id: chipText

          anchors.centerIn: parent
          color: (chip.modelData.isDefault == root.editingDefault) ? Dat.Colors.current.on_primary : Dat.Colors.current.on_surface
          font.pointSize: 9
          text: chip.modelData.label
        }

        Gen.MouseArea {
          layerColor: chip.modelData.isDefault ? Dat.Colors.current.on_surface : Dat.Colors.current.on_primary
          layerRadius: 8

          onClicked: root.editingDefault = chip.modelData.isDefault
        }
      }
    }

    Item {
      Layout.fillWidth: true
    }

    Rectangle {
      Layout.fillHeight: true
      color: Dat.Colors.current.surface_container
      implicitHeight: 24
      implicitWidth: resetText.contentWidth + 18
      radius: 8
      visible: !root.editingDefault && root.hasOverride

      Text {
        id: resetText

        anchors.centerIn: parent
        color: Dat.Colors.current.on_surface
        font.pointSize: 9
        text: "Reset"
      }

      Gen.MouseArea {
        layerColor: Dat.Colors.current.on_surface
        layerRadius: 8

        onClicked: Dat.Config.clearWallpaperFor(root.outputName)
      }
    }
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: 6

    Rectangle {
      Layout.fillHeight: true
      Layout.fillWidth: true
      color: Dat.Colors.current.surface_container
      implicitHeight: 26
      radius: 8

      Text {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        color: Dat.Colors.current.on_surface
        elide: Text.ElideMiddle
        font.pointSize: 9
        text: Dat.Config.data.wallpaperDir
        verticalAlignment: Text.AlignVCenter
      }

      Gen.MouseArea {
        layerColor: Dat.Colors.current.on_surface
        layerRadius: 8

        onClicked: folderDialog.open()
      }
    }

    Rectangle {
      Layout.fillHeight: true
      color: Dat.Colors.current.primary
      implicitHeight: 26
      implicitWidth: browseText.contentWidth + 20
      radius: 8

      Text {
        id: browseText

        anchors.centerIn: parent
        color: Dat.Colors.current.on_primary
        font.pointSize: 9
        text: "Browse"
      }

      Gen.MouseArea {
        layerColor: Dat.Colors.current.on_primary
        layerRadius: 8

        onClicked: fileDialog.open()
      }
    }
  }

  Rectangle {
    Layout.fillWidth: true
    Layout.preferredHeight: 96
    clip: true
    color: Dat.Colors.current.surface_container
    radius: 10
    visible: folderModel.count > 0

    GridView {
      id: grid

      anchors.fill: parent
      anchors.margins: 6
      cellHeight: 84
      cellWidth: 84

      model: FolderListModel {
        id: folderModel

        folder: "file://" + Dat.Config.data.wallpaperDir
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp"]
        showDirs: false
        sortField: FolderListModel.Name
      }

      delegate: Item {
        id: thumbDelegate

        required property url fileUrl

        height: grid.cellHeight
        width: grid.cellWidth

        Rectangle {
          anchors.fill: parent
          anchors.margins: 4
          border.color: Dat.Colors.current.primary
          border.width: (root.currentSrc == Dat.Paths.urlToPath(thumbDelegate.fileUrl)) ? 3 : 0
          clip: true
          color: Dat.Colors.current.surface_container_high
          radius: 8

          Image {
            anchors.fill: parent
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            smooth: true
            source: thumbDelegate.fileUrl
            sourceSize.height: 80
            sourceSize.width: 80
          }
        }

        Gen.MouseArea {
          anchors.margins: 4
          layerColor: Dat.Colors.current.primary
          layerRadius: 8

          onClicked: Dat.Config.setWallpaperFor(root.targetOutput, Dat.Paths.urlToPath(thumbDelegate.fileUrl))
        }
      }
    }
  }

  Text {
    Layout.fillWidth: true
    color: Dat.Colors.current.on_surface
    font.pointSize: 9
    horizontalAlignment: Text.AlignHCenter
    opacity: 0.7
    text: "No wallpapers found in this folder"
    visible: folderModel.count == 0
  }

  Labs.FolderDialog {
    id: folderDialog

    folder: "file://" + Dat.Config.data.wallpaperDir

    onAccepted: Dat.Config.data.wallpaperDir = Dat.Paths.urlToPath(folder)
  }

  Labs.FileDialog {
    id: fileDialog

    folder: "file://" + Dat.Config.data.wallpaperDir
    nameFilters: ["Images (*.png *.jpg *.jpeg *.webp *.bmp)"]

    onAccepted: Dat.Config.setWallpaperFor(root.targetOutput, Dat.Paths.urlToPath(file))
  }
}
