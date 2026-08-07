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

      property bool matugenEnabled: true
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
    } else {
      const updated = Object.assign({}, jsonData.wallpapersByOutput);
      updated[outputName] = path;
      jsonData.wallpapersByOutput = updated;
    }
    // theme off whatever was actually just picked, not only the global
    // default - previously this only fired via wallSrc's onChanged, so
    // picking a per-output ("This Display") wallpaper never re-themed at
    // all, only picking "Default" did
    root.runMatugenFor(path);
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
      root.runMatugenFor(path);
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

  // Runs matugen against whichever wallpaper was actually just picked
  // (default or per-output - see setWallpaperFor/IpcHandler) to
  // (re)generate the system theme. Non-interactive (see
  // scripts/applyMatugen.sh - --source-color-index 0 skips matugen's
  // color-picker prompt) and fails gracefully: if matugen isn't
  // installed the script logs and exits 0, it never blocks wallpaper
  // changes or errors the shell.
  property string matugenTargetPath: ""

  Process {
    id: matugenProc

    property string script: Dat.Paths.urlToPath(Qt.resolvedUrl("../scripts/applyMatugen.sh"))

    command: ["bash", script, Dat.Paths.urlToPath(root.matugenTargetPath), Dat.Paths.urlToPath(Dat.Paths.cache)]

    stdout: SplitParser {
      onRead: data => console.log("[MATUGEN] " + data)
    }
    stderr: SplitParser {
      onRead: data => console.log("[MATUGEN] " + data)
    }
  }

  function runMatugenFor(path) {
    if (path == "" || !jsonData.matugenEnabled) {
      return;
    }
    root.matugenTargetPath = path;
    if (matugenProc.running) {
      // command is bound to matugenTargetPath so it'll already reflect
      // the new path - just needs a restart to actually re-run with it
      matugenProc.running = false;
    }
    matugenProc.running = true;
  }

  Connections {
    // re-theme immediately if the toggle gets flipped back on, using
    // whatever the currently-effective default wallpaper is
    function onMatugenEnabledChanged() {
      root.runMatugenFor(jsonData.wallSrc);
    }

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
