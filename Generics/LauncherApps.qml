pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

import qs.Data as Dat
import qs.Generics as Gen

// Content for Dat.Launcher.mode == "apps". Deliberately self-contained
// (owns its own selection index, filters DesktopEntries itself) so it
// can be dropped into Layers/Launcher.qml behind a Loader and swapped
// for a different mode's component without either side needing to know
// about the other's internals.
Item {
  id: root

  // pulses when the panel wants the search field focused/refocused
  // (e.g. right after the launcher opens)
  signal requestFocus

  function launchSelected() {
    const entry = filtered[list.currentIndex];
    if (!entry)
      return;
    entry.execute();
    Dat.Launcher.hide();
  }

  readonly property var allApps: {
    const apps = [...DesktopEntries.applications.values].filter(e => e.name && !e.noDisplay);
    apps.sort((a, b) => a.name.localeCompare(b.name));
    return apps;
  }

  readonly property var filtered: {
    const q = Dat.Launcher.query.trim().toLowerCase();
    if (q == "")
      return root.allApps;

    return root.allApps.filter(e => {
        const name = (e.name ?? "").toLowerCase();
        const comment = (e.comment ?? "").toLowerCase();
        const keywords = (e.keywords ?? []).join(" ").toLowerCase();
        const generic = (e.genericName ?? "").toLowerCase();
        return name.includes(q) || comment.includes(q) || keywords.includes(q) || generic.includes(q);
      });
  }

  implicitHeight: col.implicitHeight

  onFilteredChanged: list.currentIndex = root.filtered.length > 0 ? 0 : -1

  ColumnLayout {
    id: col

    anchors.fill: parent
    spacing: 8

    Rectangle {
      id: resultsBox

      Layout.fillWidth: true
      Layout.preferredHeight: Math.min(list.contentHeight, 5 * 56) + (list.contentHeight > 0 ? 8 : 0)
      clip: true
      color: Dat.Colors.current.surface_container
      radius: 16
      visible: list.contentHeight > 0

      Behavior on Layout.preferredHeight {
        NumberAnimation {
          duration: Dat.MaterialEasing.standardTime
          easing.bezierCurve: Dat.MaterialEasing.standard
        }
      }

      ListView {
        id: list

        anchors.fill: parent
        anchors.margins: 4
        boundsBehavior: Flickable.StopAtBounds
        // keep a few rows' worth of icons warm just off-screen so small
        // scroll wobbles don't drop/re-issue their IconImage pixmap
        // requests
        cacheBuffer: 300
        clip: true
        currentIndex: root.filtered.length > 0 ? 0 : -1
        model: root.filtered
        spacing: 2

        delegate: Rectangle {
          id: entryDelegate

          required property var modelData
          required property int index

          color: (list.currentIndex == index) ? Dat.Colors.current.primary_container : "transparent"
          height: 52
          radius: 12
          width: list.width

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 12

            IconImage {
              id: appIcon

              Layout.preferredHeight: 32
              Layout.preferredWidth: 32
              // explicit implicitSize is what actually constrains the
              // rasterized buffer - without it IconImage/QtSvg renders
              // scalable icons at a huge native size first and then
              // scales down, which is what throws the "requested buffer
              // size is too big" warnings on some icon themes
              implicitSize: 32
              source: Quickshell.iconPath(entryDelegate.modelData.icon, true)

              Gen.MatIcon {
                anchors.centerIn: parent
                color: Dat.Colors.current.on_surface_variant
                font.pointSize: 16
                icon: "apps"
                visible: appIcon.status != Image.Ready
              }
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 0

              Text {
                Layout.fillWidth: true
                color: (list.currentIndex == entryDelegate.index) ? Dat.Colors.current.on_primary_container : Dat.Colors.current.on_surface
                elide: Text.ElideRight
                font.pointSize: 10
                text: entryDelegate.modelData.name
              }

              Text {
                Layout.fillWidth: true
                color: (list.currentIndex == entryDelegate.index) ? Dat.Colors.current.on_primary_container : Dat.Colors.current.on_surface_variant
                elide: Text.ElideRight
                font.pointSize: 8
                opacity: 0.8
                text: entryDelegate.modelData.comment ?? ""
                visible: text.length > 0
              }
            }
          }

          Gen.MouseArea {
            hoverEnabled: true
            layerColor: Dat.Colors.current.on_surface
            layerRadius: 12

            onClicked: {
              list.currentIndex = entryDelegate.index;
              root.launchSelected();
            }

            onContainsMouseChanged: {
              if (containsMouse)
                list.currentIndex = entryDelegate.index;
            }
          }
        }
      }
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

          onAccepted: root.launchSelected()

          Keys.onDownPressed: {
            list.incrementCurrentIndex();
            if (list.currentIndex >= 0)
              list.positionViewAtIndex(list.currentIndex, ListView.Contain);
          }
          Keys.onEscapePressed: event => {
            if (input.text.length > 0) {
              input.text = "";
            } else {
              event.accepted = false;
            }
          }
          Keys.onUpPressed: {
            list.decrementCurrentIndex();
            if (list.currentIndex >= 0)
              list.positionViewAtIndex(list.currentIndex, ListView.Contain);
          }

          Text {
            anchors.fill: parent
            color: Dat.Colors.current.on_surface_variant
            font.pointSize: 11
            opacity: 0.6
            text: "Search apps..."
            verticalAlignment: Text.AlignVCenter
            visible: input.text.length == 0
          }
        }
      }
    }
  }

  onRequestFocus: input.forceActiveFocus()

  Component.onCompleted: input.forceActiveFocus()
}
