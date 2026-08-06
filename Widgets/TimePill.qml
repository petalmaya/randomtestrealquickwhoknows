import QtQuick

import qs.Data as Dat
import qs.Generics as Gen

Text {
  id: timeText

  property string outputName: ""

  anchors.centerIn: parent
  color: Dat.Colors.current.secondary
  font.pointSize: 11
  text: Qt.formatDateTime(Dat.Clock.date, "h:mm:ss AP")

  Gen.MouseArea {
    anchors.centerIn: parent
    anchors.fill: null
    height: 20
    layerColor: Dat.Colors.current.secondary
    layerRadius: 20
    width: timeText.contentWidth + 12

    onClicked: {
      if (Dat.Globals.notchState(timeText.outputName) == "FULLY_EXPANDED" && Dat.Globals.swipeIndex(timeText.outputName) == 1) {
        Dat.Globals.setNotchState(timeText.outputName, "EXPANDED");
      } else {
        Dat.Globals.setNotchState(timeText.outputName, "FULLY_EXPANDED");
        Dat.Globals.setSwipeIndex(timeText.outputName, 1);
      }
    }
  }
}
