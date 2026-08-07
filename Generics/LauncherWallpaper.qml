pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Qt.labs.platform as Labs

import qs.Data as Dat
import qs.Generics as Gen

// Content for Dat.Launcher.mode == "wallpaper". Same self-contained shape
// as LauncherApps.qml (owns its own model/selection, exposes
// requestFocus()) so it drops into Layers/Launcher.qml's Loader without
// either side knowing about the other's internals.
//
// This replaces the old Widgets/WallpaperTab.qml + Generics/WallpaperPicker.qml
// combo that used to live in the Kuru settings panel - grid/model/click
// wiring is carried over from WallpaperPicker.qml, just reshaped to match
// the launcher's search-field-at-bottom layout instead of a settings tab.
// The "This Display" / "Default" chip pair is the same idea as
// WallpaperPicker's, condensed - that's the multi-monitor bit: each
// screen's launcher instance defaults to editing *that* screen's
// override, but you can still switch to editing the shared default.
Item {
  id: root

  // pulses when the panel wants the search field focused/refocused
  signal requestFocus

  // the output this launcher instance is open on - Layers/Launcher.qml
  // only ever shows the instance matching Dat.Launcher.outputName, so
  // this is always "the screen you're looking at"
  readonly property string outputName: Dat.Launcher.outputName
  property bool editingDefault: false
  readonly property string targetOutput: root.editingDefault ? "" : root.outputName
  readonly property string currentSrc: Dat.Config.wallpaperFor(root.targetOutput)
  readonly property bool hasOverride: root.outputName != "" && Dat.Config.data.wallpapersByOutput && Dat.Config.data.wallpapersByOutput[root.outputName] !== undefined

  function pick(path) {
    Dat.Config.setWallpaperFor(root.targetOutput, path);
    Dat.Launcher.hide();
  }

  function pickSelected() {
    if (!list.currentItem)
      return;
    root.pick(Dat.Paths.urlToPath(list.currentItem.fileUrl));
  }

  implicitHeight: col.implicitHeight

  ColumnLayout {
    id: col

    anchors.fill: parent
    spacing: 8

    RowLayout {
      Layout.fillWidth: true
      spacing: 6

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

          Layout.preferredHeight: 26
          color: (root.editingDefault == modelData.isDefault) ? Dat.Colors.current.primary : Dat.Colors.current.surface_container
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
        Layout.preferredHeight: 26
        color: Dat.Colors.current.surface_container
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

      Rectangle {
        id: refreshBtn

        Layout.preferredHeight: 26
        Layout.preferredWidth: 26
        color: Dat.Colors.current.surface_container
        radius: 8

        Gen.MatIcon {
          anchors.centerIn: parent
          color: Dat.Colors.current.on_surface
          font.pointSize: 12
          icon: "refresh"
        }

        Gen.MouseArea {
          layerColor: Dat.Colors.current.on_surface
          layerRadius: 8

          onClicked: folderModel.folder = folderModel.folder
        }
      }
    }

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 150
      clip: true
      color: Dat.Colors.current.surface_container
      radius: 16
      visible: folderModel.count > 0

      ListView {
        id: list

        anchors.fill: parent
        anchors.margins: 6
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        currentIndex: folderModel.count > 0 ? 0 : -1
        orientation: ListView.Horizontal
        spacing: 8

        model: FolderListModel {
          id: folderModel

          folder: "file://" + Dat.Config.data.wallpaperDir
          nameFilters: root.filtersFor(Dat.Launcher.query)
          showDirs: false
          sortField: FolderListModel.Name

          onCountChanged: list.currentIndex = folderModel.count > 0 ? 0 : -1
        }

        delegate: Item {
          id: thumbDelegate

          required property url fileUrl
          required property string fileName
          required property int index

          height: list.height
          width: 128

          Rectangle {
            anchors.fill: parent
            anchors.bottomMargin: 20
            border.color: Dat.Colors.current.primary
            border.width: (list.currentIndex == thumbDelegate.index) ? 3 : ((root.currentSrc == Dat.Paths.urlToPath(thumbDelegate.fileUrl)) ? 2 : 0)
            clip: true
            color: Dat.Colors.current.surface_container_high
            radius: 10

            Image {
              anchors.fill: parent
              asynchronous: true
              fillMode: Image.PreserveAspectCrop
              smooth: true
              source: thumbDelegate.fileUrl
              sourceSize.height: 116
              sourceSize.width: 116
            }

            Gen.MouseArea {
              layerColor: Dat.Colors.current.primary
              layerRadius: 10

              onClicked: {
                list.currentIndex = thumbDelegate.index;
                root.pick(Dat.Paths.urlToPath(thumbDelegate.fileUrl));
              }
            }
          }

          Text {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottomMargin: 2
            color: Dat.Colors.current.on_surface_variant
            elide: Text.ElideMiddle
            font.pointSize: 7
            horizontalAlignment: Text.AlignHCenter
            opacity: 0.8
            text: thumbDelegate.fileName
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
      text: (Dat.Config.data.wallpaperDir == "" || folderModel.count > 0) ? "" : (Dat.Launcher.query == "" ? "No wallpapers found in this folder" : "No wallpapers match \u201c" + Dat.Launcher.query + "\u201d")
      visible: text.length > 0
    }

    Rectangle {
      id: field

      Layout.fillWidth: true
      Layout.preferredHeight: 48
      color: Dat.Colors.current.surface_container
      radius: 16

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 10

        Gen.MatIcon {
          color: Dat.Colors.current.on_surface_variant
          font.pointSize: 14
          icon: "search"
        }

        TextInput {
          id: input

          Layout.fillWidth: true
          color: Dat.Colors.current.on_surface
          font.pointSize: 11
          selectByMouse: true
          text: Dat.Launcher.query
          verticalAlignment: TextInput.AlignVCenter

          onTextChanged: Dat.Launcher.query = text

          onAccepted: root.pickSelected()

          Keys.onEscapePressed: event => {
            if (input.text.length > 0) {
              input.text = "";
            } else {
              event.accepted = false;
            }
          }
          // Left/Right move the row selection instead of the text
          // cursor (there's nothing meaningful to navigate to in a
          // single-line field otherwise) - same idea as LauncherApps'
          // Up/Down override for its vertical list
          Keys.onLeftPressed: {
            list.decrementCurrentIndex();
            if (list.currentIndex >= 0)
              list.positionViewAtIndex(list.currentIndex, ListView.Contain);
          }
          Keys.onRightPressed: {
            list.incrementCurrentIndex();
            if (list.currentIndex >= 0)
              list.positionViewAtIndex(list.currentIndex, ListView.Contain);
          }

          Text {
            anchors.fill: parent
            color: Dat.Colors.current.on_surface_variant
            font.pointSize: 11
            opacity: 0.6
            text: "Search wallpapers..."
            verticalAlignment: Text.AlignVCenter
            visible: input.text.length == 0
          }
        }

        Gen.MatIcon {
          color: Dat.Colors.current.on_surface_variant
          font.pointSize: 13
          icon: "close"
          opacity: clearArea.containsMouse ? 1 : 0.6
          visible: input.text.length > 0

          MouseArea {
            id: clearArea

            anchors.margins: -6
            anchors.fill: parent
            hoverEnabled: true

            onClicked: input.text = ""
          }
        }
      }
    }
  }

  // FolderListModel only filters by glob, not substring - wrap the typed
  // query in *...* against each allowed extension so it behaves like a
  // live search the same way LauncherApps' name/comment/keyword filter
  // does. Deliberately skips animated formats (gif/mp4/etc) per the ask
  // to leave that out for now.
  function filtersFor(query) {
    const exts = ["png", "jpg", "jpeg", "webp", "bmp"];
    const q = query.trim();
    if (q == "")
      return exts.map(e => "*." + e);
    return exts.map(e => "*" + q + "*." + e);
  }

  onRequestFocus: input.forceActiveFocus()

  Component.onCompleted: input.forceActiveFocus()
}
