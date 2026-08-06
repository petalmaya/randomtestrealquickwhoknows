import QtQuick
import QtQuick.Layouts

import qs.Data as Dat
import qs.Containers as Con

Rectangle {
  id: root

  property string outputName: ""

  color: Dat.Colors.withAlpha(Dat.Colors.current.surface, 0.9)
  radius: 20

  RowLayout {
    anchors.fill: parent
    spacing: 0

    Con.CentralSwipable {
      Layout.fillHeight: true
      Layout.fillWidth: true
      outputName: root.outputName
    }

    KuruKuru {
      Layout.fillHeight: true
      Layout.fillWidth: true
      outputName: root.outputName
    }
  }
}
