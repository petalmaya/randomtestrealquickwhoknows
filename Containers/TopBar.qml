import QtQuick
import QtQuick.Layouts

import qs.Data as Dat
import qs.Generics as Gen
import qs.Widgets as Wid

RowLayout {
  id: root

  property string outputName: ""

  // Left
  Item {
    Layout.fillHeight: true
    Layout.fillWidth: true

    RowLayout {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter

      Wid.WorkspacePill {
        Layout.leftMargin: 5
        outputName: root.outputName
      }

      Wid.MprisDot {
        implicitHeight: 20
        implicitWidth: 20
        outputName: root.outputName
        radius: 20
      }

      Wid.RecordingDot {
        implicitHeight: 20
        implicitWidth: 20
        outputName: root.outputName
      }
    }
  }

  // Center
  Item {
    Layout.fillHeight: true
    Layout.fillWidth: true

    Wid.TimePill {
      outputName: root.outputName
    }
  }

  // Right
  Item {
    Layout.fillHeight: true
    Layout.fillWidth: true

    RowLayout {
      anchors.bottom: parent.bottom
      anchors.right: parent.right
      anchors.top: parent.top
      layoutDirection: Qt.RightToLeft
      spacing: 8

      Gen.NerdIcon {
        Layout.fillWidth: false
        // little arrow to toggle notch expand states
        Layout.rightMargin: 5
        color: Dat.Colors.current.primary
        font.pointSize: 11
        icon: (Dat.Globals.notchState(root.outputName) == "FULLY_EXPANDED") ? "" : ""
        verticalAlignment: Text.AlignVCenter

        MouseArea {
          anchors.fill: parent

          onClicked: mevent => {
            if (Dat.Globals.notchState(root.outputName) == "EXPANDED") {
              Dat.Globals.setNotchState(root.outputName, "FULLY_EXPANDED");
              return;
            }

            Dat.Globals.setNotchState(root.outputName, "EXPANDED");
          }
        }
      }

      Wid.BatteryPill {
        implicitHeight: 20
        outputName: root.outputName
        radius: 20
      }

      Wid.AudioSwiper {
        implicitHeight: 20
        outputName: root.outputName
        radius: 20
      }

      Wid.BrightnessDot {
        implicitHeight: 20
        implicitWidth: 20
        radius: 20
      }
    }
  }
}
