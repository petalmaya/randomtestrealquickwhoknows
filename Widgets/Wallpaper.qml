import QtQuick
import qs.Data as Dat

Image {
  // when set, resolves this output's wallpaper override (falling back to
  // the global wallSrc); leave empty to always use the global wallSrc
  property string outputName: ""

  antialiasing: true
  asynchronous: true
  fillMode: Image.PreserveAspectCrop
  layer.enabled: true
  retainWhileLoading: true
  smooth: true
  source: Dat.Config.wallpaperFor(outputName)

  onStatusChanged: {
    if (this.status == Image.Error) {
      console.log("[ERROR] Wallpaper source invalid");
      console.log("[INFO] Please disable set wallpaper if not required");
    }
  }
}
