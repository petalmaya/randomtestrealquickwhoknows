pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.Generics as Gen
import qs.Data as Dat
import qs.Widgets as Wid

Item {
  id: root

  property string outputName: ""

  RowLayout {
    anchors.fill: parent
    spacing: 8

    Rectangle {
      // the page indicator
      Layout.leftMargin: 8
      color: Dat.Colors.current.surface_container_low
      implicitHeight: tabCols.height + 10
      implicitWidth: 28
      radius: 20

      ColumnLayout {
        id: tabCols

        anchors.verticalCenter: parent.verticalCenter
        spacing: 10
        width: parent.width

        Repeater {
          model: ["󰋜", "󰃭", "󱄅", "󰎇", "󰒓"]

          Item {
            id: tabDot

            required property int index
            required property string modelData

            Layout.alignment: Qt.AlignCenter
            implicitHeight: this.implicitWidth
            implicitWidth: 20

            Gen.NerdIcon {
              id: dotText

              anchors.centerIn: parent
              color: Dat.Colors.current.on_surface
              font.pointSize: 11
              // NerdIcon defaults to Text.NativeRendering, which rasterizes
              // the glyph once via the platform font engine (freetype
              // bitmap, no mipmaps) at font.pointSize. The ACTIVE state
              // below scales that fixed bitmap up 1.6x with a GPU
              // transform, which is what pixelates - NativeRendering has no
              // smooth-scaling path. QtRendering instead draws the glyph as
              // a distance-field texture, which samples cleanly at any
              // scale and is actually cheaper here since nothing needs to
              // re-rasterize per animation frame.
              renderType: Text.QtRendering
              state: (swipeArea.currentIndex == tabDot.index) ? "ACTIVE" : "INACTIVE"
              icon: tabDot.modelData

              states: [
                State {
                  name: "ACTIVE"

                  PropertyChanges {
                    dotText.scale: 1.6
                  }
                },
                State {
                  name: "INACTIVE"

                  PropertyChanges {
                    dotText.scale: 1
                  }
                }
              ]
              transitions: [
                Transition {
                  from: "INACTIVE"
                  to: "ACTIVE"

                  NumberAnimation {
                    duration: Dat.MaterialEasing.standardAccelTime
                    easing.bezierCurve: Dat.MaterialEasing.standardAccel
                    property: "scale"
                  }
                },
                Transition {
                  from: "ACTIVE"
                  to: "INACTIVE"

                  NumberAnimation {
                    duration: Dat.MaterialEasing.standardDecelTime
                    easing.bezierCurve: Dat.MaterialEasing.standardDecel
                    property: "scale"
                  }
                }
              ]
            }

            Gen.MouseArea {
              layerRadius: parent.width
              layerRect.scale: dotText.scale

              onClicked: swipeArea.setCurrentIndex(tabDot.index)
            }
          }
        }
      }
    }

    Rectangle {
      id: swipeRect

      Layout.fillHeight: true
      Layout.fillWidth: true
      // Pages
      clip: true
      color: Dat.Colors.current.surface_container_low
      radius: 20

      SwipeView {
        id: swipeArea

        readonly property int globalSwipeIndex: Dat.Globals.swipeIndex(root.outputName)

        anchors.fill: parent
        orientation: Qt.Horizontal

        Connections {
          function onGlobalSwipeIndexChanged() {
            if (swipeArea.currentIndex != swipeArea.globalSwipeIndex) {
              swipeArea.currentIndex = swipeArea.globalSwipeIndex;
            }
          }

          target: swipeArea
        }
        onCurrentIndexChanged: () => {
          if (swipeArea.currentIndex != swipeArea.globalSwipeIndex) {
            Dat.Globals.setSwipeIndex(root.outputName, swipeArea.currentIndex);
          }
        }

        Wid.HomeView {
          height: swipeRect.height
          outputName: root.outputName
          width: swipeRect.width
        }

        Wid.CalendarView {
          height: swipeRect.height
          width: swipeRect.width
        }

        Wid.SystemView {
          height: swipeRect.height
          outputName: root.outputName
          width: swipeRect.width
        }

        Wid.MusicView {
          height: swipeRect.height
          outputName: root.outputName
          width: swipeRect.width
        }

        Wid.SettingsView {
          height: swipeRect.height
          outputName: root.outputName
          width: swipeRect.width
        }
      }
    }
  }
}
