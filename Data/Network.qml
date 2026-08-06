pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// WiFi via nmcli (NetworkManager). Quickshell doesn't ship a native
// NetworkManager service the way it does Bluetooth/Mpris/UPower, so this
// just shells out to `nmcli` and parses its terse (-t) output.
//
// Requires NetworkManager + nmcli on the system. If you're on
// iwd/systemd-networkd instead this won't do anything useful - shout and
// this can be reworked around iwctl instead.
Singleton {
  id: root

  property bool wifiEnabled: false
  property bool scanning: false
  property bool connecting: false
  property string connectError: ""
  // [{ssid, signal, security, active, known}], sorted strongest-first,
  // deduped by ssid (nmcli lists one row per BSSID otherwise)
  property var networks: []

  function refreshStatus() {
    statusProc.running = true;
  }

  function scan() {
    root.scanning = true;
    scanProc.running = true;
  }

  function toggleWifi() {
    Quickshell.execDetached(["nmcli", "radio", "wifi", root.wifiEnabled ? "off" : "on"]);
    root.wifiEnabled = !root.wifiEnabled;
    settleTimer.restart();
  }

  function connectToNetwork(ssid, password) {
    root.connecting = true;
    root.connectError = "";
    if (password && password.length > 0) {
      connectProc.command = ["nmcli", "device", "wifi", "connect", ssid, "password", password];
    } else {
      connectProc.command = ["nmcli", "device", "wifi", "connect", ssid];
    }
    connectProc.running = true;
  }

  function disconnectNetwork(ssid) {
    Quickshell.execDetached(["nmcli", "connection", "down", ssid]);
    settleTimer.restart();
  }

  function forget(ssid) {
    Quickshell.execDetached(["nmcli", "connection", "delete", ssid]);
    settleTimer.restart();
  }

  // nmcli terse mode escapes literal colons in field values as "\:" -
  // split only on colons that aren't preceded by a backslash, then
  // unescape.
  function _splitTerse(line) {
    return line.split(/(?<!\\):/).map(f => f.replace(/\\:/g, ":"));
  }

  Timer {
    id: settleTimer

    interval: 800

    onTriggered: {
      root.refreshStatus();
      root.scan();
    }
  }

  Timer {
    interval: 15000
    repeat: true
    running: true
    triggeredOnStart: true

    onTriggered: root.refreshStatus()
  }

  Process {
    id: statusProc

    command: ["nmcli", "-t", "-f", "WIFI", "radio"]

    stdout: StdioCollector {
      onStreamFinished: {
        root.wifiEnabled = this.text.trim() == "enabled";
      }
    }
  }

  Process {
    id: scanProc

    command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", "yes"]

    stdout: StdioCollector {
      onStreamFinished: {
        knownProc.running = true;

        const seen = {};
        const list = [];
        for (const line of this.text.split("\n")) {
          if (!line)
            continue;

          const [inUse, ssid, signal, security] = root._splitTerse(line);
          if (!ssid)
            continue;

          const existing = seen[ssid];
          const signalNum = parseInt(signal) || 0;
          if (existing && existing.signal >= signalNum)
            continue;

          const entry = {
            "ssid": ssid,
            "signal": signalNum,
            "security": security,
            "active": inUse == "*",
            "known": false
          };
          if (!existing)
            list.push(entry);
          else
            Object.assign(existing, entry);
          seen[ssid] = existing ?? entry;
        }

        list.sort((a, b) => (b.active - a.active) || (b.signal - a.signal));
        root.networks = list;
        root.scanning = false;
      }
    }
  }

  // cross-references saved connection names against the scan results so
  // known networks skip the password prompt
  Process {
    id: knownProc

    command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]

    stdout: StdioCollector {
      onStreamFinished: {
        const knownNames = new Set();
        for (const line of this.text.split("\n")) {
          if (!line)
            continue;
          const [name, type] = root._splitTerse(line);
          if (type && type.includes("wireless")) {
            knownNames.add(name);
          }
        }

        root.networks = root.networks.map(n => Object.assign({}, n, {
              "known": knownNames.has(n.ssid)
            }));
      }
    }
  }

  Process {
    id: connectProc

    stdout: StdioCollector {}

    stderr: StdioCollector {
      onStreamFinished: {
        root.connecting = false;
        if (this.text.trim().length > 0) {
          root.connectError = this.text.trim();
        } else {
          settleTimer.restart();
        }
      }
    }
  }

  Component.onCompleted: {
    root.refreshStatus();
    root.scan();
  }
}
