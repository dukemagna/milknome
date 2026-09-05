#!/usr/bin/env bash
# milknome uninstall — does not touch the rest of the user's gtk.css
set -euo pipefail

THEME_NAME="milknome"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
THEME_DEST="${DATA_HOME}/themes/${THEME_NAME}"
GTK3_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0"
GTK4_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-4.0"

remove_import() {
  local gtk_css="$1"
  [[ -f "$gtk_css" ]] || return 0
  if grep -q "milknome:begin" "$gtk_css"; then
    sed -i '/\/\* milknome:begin \*\//,/\/\* milknome:end \*\//d' "$gtk_css"
  fi
}

remove_import "$GTK4_DIR/gtk.css"
remove_import "$GTK3_DIR/gtk.css"

rm -f "$GTK4_DIR/milknome.css" "$GTK4_DIR/milknome-palette.css"
rm -f "$GTK3_DIR/milknome.css"

if command -v gsettings >/dev/null 2>&1; then
  if gsettings writable org.gnome.shell.extensions.user-theme name >/dev/null 2>&1; then
    current="$(gsettings get org.gnome.shell.extensions.user-theme name | tr -d "'")"
    if [[ "$current" == "$THEME_NAME" ]]; then
      gsettings reset org.gnome.shell.extensions.user-theme name
    fi
  fi
fi

if [[ -d "$THEME_DEST/.git" ]]; then
  echo "Theme directory is a git repo; left in place: $THEME_DEST"
elif [[ -d "$THEME_DEST" ]]; then
  rm -rf "$THEME_DEST"
  echo "Removed: $THEME_DEST"
fi

echo "milknome overlay removed."
echo "If system dark style is still on, reset with:"
echo "  gsettings reset org.gnome.desktop.interface color-scheme"
