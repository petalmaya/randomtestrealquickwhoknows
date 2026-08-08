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
      // NOTE: despite the name, this is no longer a desktop-wallpaper
      // fallback - it's the lock screen's background image specifically
      // (see wallpaperFor()/lockWallpaper below). Kept the JSON key as
      // "wallSrc" rather than renaming it so existing config.json files
      // don't silently lose their picked image on upgrade.
      property string wallSrc: Quickshell.env("HOME") + "/.config/background"
      // output name -> wallpaper path. This is the *only* source for a
      // given monitor's desktop background now - there is deliberately no
      // shared/global fallback for the desktop layer, each output needs
      // its own entry (picked via the launcher's "This Display" chip) or
      // it just shows nothing. See handoff.md for why.
      property var wallpapersByOutput: ({})
      property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    }
  }

  // convenience name for reading the lock screen's background - same
  // storage as wallSrc, just spelled out for readability at call sites
  // that care specifically about the lock screen rather than desktop bg
  readonly property alias lockWallpaper: jsonData.wallSrc

  // resolves the effective *desktop* wallpaper for a given output name.
  // Strictly per-monitor: no outputName (or one with no override) means
  // "no wallpaper for this monitor", not "fall back to the lock screen's
  // image" - that fallback used to exist and was the source of desktop
  // and lock screen backgrounds getting tangled together. The one
  // exception is an explicitly empty/falsy outputName, which resolves to
  // the lock wallpaper - that's what lets the launcher's "Default" chip
  // (Generics/LauncherWallpaper.qml, targetOutput == "") preview/compare
  // against the lock image it's actually editing.
  function wallpaperFor(outputName) {
    if (!outputName) {
      return jsonData.wallSrc;
    }
    if (jsonData.wallpapersByOutput && jsonData.wallpapersByOutput[outputName]) {
      return jsonData.wallpapersByOutput[outputName];
    }
    return "";
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
    // sets the lock screen background (not a desktop wallpaper - desktop
    // backgrounds are per-output only now, use setWallpaperFor for those)
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
    // whatever the currently-effective lock screen wallpaper is
    function onMatugenEnabledChanged() {
      root.runMatugenFor(jsonData.wallSrc);
    }

    function onWallFgLayerChanged() {
      onWallSrcChanged();
    }

    // wallSrc is the lock screen's background now (see wallpaperFor()),
    // so this only ever re-extracts a foreground cutout for whatever's
    // actually behind the lock screen - it deliberately does NOT fire
    // off of per-output desktop wallpaper changes (setWallpaperFor with a
    // real outputName). If that behavior's ever wanted too, it'd need its
    // own per-output extractFg run + wallFg storage keyed by output,
    // rather than the single global wallFg this generates today.
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
