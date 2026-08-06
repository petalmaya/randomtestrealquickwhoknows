// a thin wrapper for placing raw Nerd Font glyphs (nf-md-*, nf-linux-*, etc)
// keeps every glyph icon in the shell on the same patched typeface instead of
// silently falling back to whatever the system default happens to be.
// "Propo" variant is used since these glyphs sit inline in proportional UI
// text, not a fixed-width terminal grid.
import QtQuick

Text {
  id: root

  required property string icon

  font.family: "NotoSansM Nerd Font Propo"
  renderType: Text.NativeRendering
  text: root.icon
}
