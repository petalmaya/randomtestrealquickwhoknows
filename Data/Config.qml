pragma ComponentBehavior: Bound
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

import qs.Data as Dat

Singleton {
  id: root

  property alias data: jsonData
  property alias fgGenProc: generateFg
  property string wallFg: ""

  FileView {
    path: Dat.Paths.config + "/config.json"
    watchChanges: true

    onAdapterUpdated: writeAdapter()
    onFileChanged: reload()

    JsonAdapter {
      id: jsonData

      property bool mousePsystem: false
      property bool reservedShell: false
      property bool setWallpaper: true
      property bool wallFgLayer: false
      property string wallSrc: Quickshell.env("HOME") + "/.config/background"
      // output name -> wallpaper path, overrides wallSrc for that monitor
      property var wallpapersByOutput: ({})
      property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    }
  }

  // resolves the effective wallpaper for a given output name, falling
  // back to the global wallSrc when that output has no override
  function wallpaperFor(outputName) {
    if (outputName && jsonData.wallpapersByOutput && jsonData.wallpapersByOutput[outputName]) {
      return jsonData.wallpapersByOutput[outputName];
    }
    return jsonData.wallSrc;
  }

  function setWallpaperFor(outputName, path) {
    if (!outputName) {
      jsonData.wallSrc = path;
      return;
    }
    const updated = Object.assign({}, jsonData.wallpapersByOutput);
    updated[outputName] = path;
    jsonData.wallpapersByOutput = updated;
  }

  function clearWallpaperFor(outputName) {
    if (!outputName || !jsonData.wallpapersByOutput)
      return;
    const updated = Object.assign({}, jsonData.wallpapersByOutput);
    delete updated[outputName];
    jsonData.wallpapersByOutput = updated;
  }

  IpcHandler {
    function setWallpaper(path: string) {
      path = Qt.resolvedUrl(path);
      jsonData.wallSrc = path;
    }

    // e.g. `qs ipc call config setWallpaperFor eDP-1 /path/to/img.png`
    function setWallpaperFor(outputName: string, path: string) {
      path = Qt.resolvedUrl(path);
      root.setWallpaperFor(outputName, path);
    }

    target: "config"
  }

  Process {
    id: generateFg

    property string script: Dat.Paths.urlToPath(Qt.resolvedUrl("../scripts/extractFg.sh"))

    command: ["bash", script, Dat.Paths.urlToPath(jsonData.wallSrc), Dat.Paths.urlToPath(Dat.Paths.cache)]

    stdout: SplitParser {
      onRead: data => {
        if (/\[.*\]/.test(data)) {
          console.log(data);
        } else if (/FOREGROUND/.test(data)) {
          root.wallFg = data.split(" ")[1];
        } else {
          console.log("[EXT] " + data);
        }
      }
    }
  }

  Connections {
    function onWallFgLayerChanged() {
      onWallSrcChanged();
    }

    function onWallSrcChanged() {
      if (jsonData.wallSrc != "" && jsonData.wallFgLayer) {
        if (!generateFg.running) {
          generateFg.running = true;
        }
      }
    }

    target: jsonData
  }
}
