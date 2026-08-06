import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Bluetooth

import qs.Data as Dat
import qs.Generics as Gen

// Content of the network panel: WiFi list w/ password entry, and a
// Bluetooth device list. Lives inside Layers/NetPanel.qml, which handles
// the actual popup surface + click-outside-to-close behaviour.
ColumnLayout {
  id: root

  property string expandedSsid: ""
  property string passwordDraft: ""

  spacing: 14

  // --- WiFi ---
  ColumnLayout {
    Layout.fillWidth: true
    spacing: 6

    RowLayout {
      Layout.fillWidth: true

      Gen.MatIcon {
        color: Dat.Colors.current.primary
        font.pointSize: 16
        icon: Dat.Network.wifiEnabled ? "wifi" : "wifi_off"
      }

      Text {
        Layout.fillWidth: true
        color: Dat.Colors.current.on_surface
        font.pointSize: 12
        font.weight: Font.Medium
        text: "Wi-Fi"
      }

      Item {
        Layout.preferredHeight: 20
        Layout.preferredWidth: 20
        visible: Dat.Network.scanning

        Gen.MatIcon {
          anchors.centerIn: parent
          color: Dat.Colors.current.on_surface
          font.pointSize: 14
          icon: "progress_activity"

          RotationAnimation on rotation {
            duration: 900
            from: 0
            loops: Animation.Infinite
            running: Dat.Network.scanning
            to: 360
          }
        }
      }

      Rectangle {
        Layout.preferredHeight: 22
        Layout.preferredWidth: 22
        color: "transparent"
        radius: 11

        Gen.MatIcon {
          anchors.centerIn: parent
          color: Dat.Colors.current.on_surface
          font.pointSize: 13
          icon: "refresh"
        }

        Gen.MouseArea {
          layerColor: Dat.Colors.current.on_surface
          layerRadius: 11

          onClicked: Dat.Network.scan()
        }
      }

      Rectangle {
        Layout.preferredHeight: 20
        Layout.preferredWidth: 34
        color: Dat.Network.wifiEnabled ? Dat.Colors.current.primary : Dat.Colors.current.surface_container_high
        radius: 10

        Rectangle {
          anchors.margins: 2
          anchors.verticalCenter: parent.verticalCenter
          color: Dat.Network.wifiEnabled ? Dat.Colors.current.on_primary : Dat.Colors.current.on_surface
          height: 16
          radius: 8
          width: 16
          x: Dat.Network.wifiEnabled ? parent.width - width - 2 : 2

          Behavior on x {
            NumberAnimation {
              duration: Dat.MaterialEasing.standardTime
              easing.bezierCurve: Dat.MaterialEasing.standard
            }
          }
        }

        Gen.MouseArea {
          layerColor: Dat.Colors.current.on_surface
          layerRadius: 10

          onClicked: Dat.Network.toggleWifi()
        }
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 3
      visible: Dat.Network.wifiEnabled

      Repeater {
        model: Dat.Network.networks

        ColumnLayout {
          id: netEntry

          required property var modelData

          Layout.fillWidth: true
          spacing: 0

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            color: netEntry.modelData.active ? Dat.Colors.current.primary_container : "transparent"
            radius: 10

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 8
              anchors.rightMargin: 8

              Gen.MatIcon {
                color: netEntry.modelData.active ? Dat.Colors.current.on_primary_container : Dat.Colors.current.on_surface
                fill: netEntry.modelData.signal >= 50 ? 1 : 0
                font.pointSize: 13
                icon: "wifi"
              }

              Text {
                Layout.fillWidth: true
                color: netEntry.modelData.active ? Dat.Colors.current.on_primary_container : Dat.Colors.current.on_surface
                elide: Text.ElideRight
                font.pointSize: 11
                text: netEntry.modelData.ssid
              }

              Text {
                color: Dat.Colors.current.primary
                font.pointSize: 9
                text: "Connected"
                visible: netEntry.modelData.active
              }

              Gen.MatIcon {
                color: netEntry.modelData.active ? Dat.Colors.current.on_primary_container : Dat.Colors.current.on_surface
                font.pointSize: 13
                icon: "lock"
                visible: netEntry.modelData.security && netEntry.modelData.security.length > 0
              }
            }

            Gen.MouseArea {
              layerColor: Dat.Colors.current.on_surface
              layerRadius: 10

              onClicked: {
                if (netEntry.modelData.active) {
                  Dat.Network.disconnectNetwork(netEntry.modelData.ssid);
                  return;
                }

                if (netEntry.modelData.known || !netEntry.modelData.security || netEntry.modelData.security.length == 0) {
                  Dat.Network.connectToNetwork(netEntry.modelData.ssid, "");
                  return;
                }

                root.expandedSsid = (root.expandedSsid == netEntry.modelData.ssid) ? "" : netEntry.modelData.ssid;
                root.passwordDraft = "";
              }
            }
          }

          RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            visible: root.expandedSsid == netEntry.modelData.ssid

            TextField {
              id: pwField

              Layout.fillWidth: true
              echoMode: TextInput.Password
              placeholderText: "Password"
              text: root.passwordDraft

              onAccepted: Dat.Network.connectToNetwork(netEntry.modelData.ssid, pwField.text)
              onTextChanged: root.passwordDraft = pwField.text
            }

            Rectangle {
              Layout.preferredHeight: 28
              Layout.preferredWidth: 60
              color: Dat.Colors.current.primary
              radius: 8

              Text {
                anchors.centerIn: parent
                color: Dat.Colors.current.on_primary
                font.pointSize: 9
                text: Dat.Network.connecting ? "..." : "Connect"
              }

              Gen.MouseArea {
                layerColor: Dat.Colors.current.on_primary
                layerRadius: 8

                onClicked: Dat.Network.connectToNetwork(netEntry.modelData.ssid, pwField.text)
              }
            }
          }

          Text {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            color: Dat.Colors.current.error
            font.pointSize: 9
            text: Dat.Network.connectError
            visible: root.expandedSsid == netEntry.modelData.ssid && Dat.Network.connectError.length > 0
            wrapMode: Text.Wrap
          }
        }
      }

      Text {
        Layout.fillWidth: true
        color: Dat.Colors.current.on_surface
        font.pointSize: 9
        horizontalAlignment: Text.AlignHCenter
        opacity: 0.7
        text: "No networks found"
        visible: Dat.Network.networks.length == 0 && !Dat.Network.scanning
      }
    }
  }

  Rectangle {
    Layout.fillWidth: true
    color: Dat.Colors.current.outline
    height: 1
    opacity: 0.4
  }

  // --- Bluetooth ---
  ColumnLayout {
    id: btSection

    Layout.fillWidth: true
    spacing: 6

    readonly property var adapter: Bluetooth.defaultAdapter

    RowLayout {
      Layout.fillWidth: true

      Gen.MatIcon {
        color: Dat.Colors.current.primary
        font.pointSize: 16
        icon: btSection.adapter?.enabled ? "bluetooth" : "bluetooth_disabled"
      }

      Text {
        Layout.fillWidth: true
        color: Dat.Colors.current.on_surface
        font.pointSize: 12
        font.weight: Font.Medium
        text: "Bluetooth"
      }

      Rectangle {
        Layout.preferredHeight: 20
        Layout.preferredWidth: 34
        color: (btSection.adapter?.enabled ?? false) ? Dat.Colors.current.primary : Dat.Colors.current.surface_container_high
        radius: 10

        Rectangle {
          anchors.margins: 2
          anchors.verticalCenter: parent.verticalCenter
          color: (btSection.adapter?.enabled ?? false) ? Dat.Colors.current.on_primary : Dat.Colors.current.on_surface
          height: 16
          radius: 8
          width: 16
          x: (btSection.adapter?.enabled ?? false) ? parent.width - width - 2 : 2

          Behavior on x {
            NumberAnimation {
              duration: Dat.MaterialEasing.standardTime
              easing.bezierCurve: Dat.MaterialEasing.standard
            }
          }
        }

        Gen.MouseArea {
          layerColor: Dat.Colors.current.on_surface
          layerRadius: 10

          onClicked: {
            const adapter = Bluetooth.defaultAdapter;
            if (adapter)
              adapter.enabled = !adapter.enabled;
          }
        }
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 3
      visible: Bluetooth.defaultAdapter?.enabled ?? false

      Repeater {
        model: Bluetooth.defaultAdapter?.devices ?? []

        Rectangle {
          id: btEntry

          required property BluetoothDevice modelData

          Layout.fillWidth: true
          Layout.preferredHeight: 34
          color: btEntry.modelData.connected ? Dat.Colors.current.primary_container : "transparent"
          radius: 10

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8

            Gen.MatIcon {
              color: btEntry.modelData.connected ? Dat.Colors.current.on_primary_container : Dat.Colors.current.on_surface
              font.pointSize: 13
              icon: "bluetooth"
            }

            Text {
              Layout.fillWidth: true
              color: btEntry.modelData.connected ? Dat.Colors.current.on_primary_container : Dat.Colors.current.on_surface
              elide: Text.ElideRight
              font.pointSize: 11
              text: btEntry.modelData.name || btEntry.modelData.deviceName || "Unknown device"
            }

            Text {
              color: Dat.Colors.current.primary
              font.pointSize: 9
              text: "Connected"
              visible: btEntry.modelData.connected
            }

            Rectangle {
              Layout.preferredHeight: 20
              Layout.preferredWidth: 20
              color: "transparent"
              radius: 10
              visible: btEntry.modelData.paired

              Gen.MatIcon {
                anchors.centerIn: parent
                color: Dat.Colors.current.on_surface
                font.pointSize: 12
                icon: "delete"
              }

              Gen.MouseArea {
                layerColor: Dat.Colors.current.on_surface
                layerRadius: 10

                onClicked: btEntry.modelData.forget()
              }
            }
          }

          Gen.MouseArea {
            layerColor: Dat.Colors.current.on_surface
            layerRadius: 10
            z: -1

            onClicked: {
              if (btEntry.modelData.connected) {
                btEntry.modelData.disconnect();
              } else {
                btEntry.modelData.connect();
              }
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
        text: "No devices found"
        visible: (Bluetooth.defaultAdapter?.devices?.length ?? 0) == 0
      }
    }

    Text {
      Layout.fillWidth: true
      color: Dat.Colors.current.on_surface
      font.pointSize: 9
      horizontalAlignment: Text.AlignHCenter
      opacity: 0.7
      text: "No Bluetooth adapter found"
      visible: !Bluetooth.defaultAdapter
    }
  }
}
