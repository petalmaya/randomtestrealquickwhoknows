#!/usr/bin/env bash
SRCIMG=$1
CACHEDIR=$(realpath $2)

mkdir -p "$CACHEDIR"

# matugen is an optional dependency - if it's not on PATH just bow out
# quietly instead of spamming the log every wallpaper change
if ! command -v matugen &> /dev/null; then
  echo "[INFO] matugen not installed, skipping theme generation"
  exit 0
fi

echo "[INFO] Generating matugen theme from wallpaper"
# matugen's interactive color-picker prompt (added in newer CLI
# versions) reads straight from /dev/tty via a terminal library, not
# from whatever's piped to stdin - so piping an answer in doesn't work
# when there's no controlling terminal (this is what threw the
# "IO error: not a terminal" failure). --source-color-index 0 skips
# the prompt entirely and picks the same first/primary source color
# the old non-interactive behavior used.
if matugen image "$SRCIMG" --source-color-index 0 &> "$CACHEDIR/matugen.log"; then
  echo "[INFO] matugen theme applied"
else
  echo "[ERROR] matugen failed, see ${CACHEDIR}/matugen.log"
  exit 1
fi
