import QtQuick

import qs.Data as Dat
import qs.Generics as Gen

Rectangle {
  color: Dat.Colors.current.surface_container_high

  Gen.NerdIcon {
    anchors.centerIn: parent
    color: Dat.Colors.current.tertiary
    font.pointSize: 11
    icon: "󰃠"
  }

  Gen.MouseArea {
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    layerColor: Dat.Colors.current.tertiary

    onClicked: mevent => {
      switch (mevent.button) {
      case Qt.RightButton:
        Dat.Brightness.increase();
        break;
      case Qt.LeftButton:
        Dat.Brightness.decrease();
        break;
      }
    }
    onWheel: event => {
      if (event.angleDelta.y > 0) {
        Dat.Brightness.increase();
      } else {
        Dat.Brightness.decrease();
      }
    }
  }
}
