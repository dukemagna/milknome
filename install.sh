#!/usr/bin/env bash
# milknome — GNOME 50–51 overlay installer
set -euo pipefail

THEME_NAME="milknome"
USER_THEME_UUID="user-theme@gnome-shell-extensions.gcampax.github.com"
IMPORT_BEGIN="/* milknome:begin */"
IMPORT_END="/* milknome:end */"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
THEME_DEST="${DATA_HOME}/themes/${THEME_NAME}"
GTK3_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0"
GTK4_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-4.0"
FLATPAK=0

usage() {
  cat <<EOF
Usage: ./install.sh [--flatpak]

  --flatpak   Allow Flatpak apps to read gtk-4.0 CSS
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --flatpak) FLATPAK=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing command: $1" >&2
    exit 1
  }
}

need gsettings

require_writable_dir() {
  local dir="$1"
  mkdir -p "$dir" 2>/dev/null || true
  if [[ -w "$dir" ]]; then
    return 0
  fi
  local owner
  owner="$(stat -c '%U:%G' "$dir" 2>/dev/null || echo '?')"
  cat >&2 <<EOF
Cannot write: $dir (owner: $owner)
This directory is not writable by your user, so milknome.css cannot be installed.

Fix and re-run:

  sudo chown -R "$USER:$USER" "$GTK3_DIR" "$GTK4_DIR"

EOF
  exit 1
}

ensure_import() {
  local gtk_css="$1"
  local block
  block="$(printf '%s\n@import url("milknome.css");\n%s' "$IMPORT_BEGIN" "$IMPORT_END")"

  mkdir -p "$(dirname "$gtk_css")"

  if [[ -f "$gtk_css" ]] && grep -q "milknome:begin" "$gtk_css"; then
    return 0
  fi

  if [[ -f "$gtk_css" ]] && grep -q 'milknome.css' "$gtk_css"; then
    return 0
  fi

  # Later @import wins; append after an existing colors.css import.
  if [[ -f "$gtk_css" ]]; then
    printf '\n%s\n' "$block" >>"$gtk_css"
  else
    printf '%s\n' "$block" >"$gtk_css"
  fi
}

install_shell_theme() {
  mkdir -p "$THEME_DEST/gnome-shell"

  if [[ "$ROOT" == "$THEME_DEST" ]]; then
    echo "Shell theme already in place: $THEME_DEST"
    return 0
  fi

  cp "$ROOT/index.theme" "$THEME_DEST/index.theme"
  cp "$ROOT/gnome-shell/gnome-shell.css" "$THEME_DEST/gnome-shell/gnome-shell.css"
  echo "Shell theme copied to: $THEME_DEST"
}

install_gtk_overlays() {
  require_writable_dir "$GTK4_DIR"
  require_writable_dir "$GTK3_DIR"

  cp "$ROOT/palette.css" "$GTK4_DIR/milknome.css"
  ensure_import "$GTK4_DIR/gtk.css"

  cp "$ROOT/gtk-3.0/milknome.css" "$GTK3_DIR/milknome.css"
  ensure_import "$GTK3_DIR/gtk.css"

  echo "GTK overlay written: $GTK4_DIR/milknome.css"
}

enable_dark_skeleton() {
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
  echo "color-scheme = prefer-dark (skeleton; colors from milknome)"
}

enable_user_theme() {
  if ! command -v gnome-extensions >/dev/null 2>&1; then
    echo "Warning: gnome-extensions not found. Enable User Themes manually." >&2
    return 0
  fi

  if ! gnome-extensions list --enabled 2>/dev/null | grep -qx "$USER_THEME_UUID"; then
    if gnome-extensions list 2>/dev/null | grep -qx "$USER_THEME_UUID"; then
      gnome-extensions enable "$USER_THEME_UUID" || true
    else
      cat >&2 <<EOF
Warning: User Themes extension was not found.
Install it, then run this script again:

  # Fedora
  sudo dnf install gnome-shell-extension-user-theme
  # Ubuntu / Debian
  sudo apt install gnome-shell-extension-user-theme
  # Arch / CachyOS
  sudo pacman -S gnome-shell-extensions

EOF
      return 0
    fi
  fi

  gsettings set org.gnome.shell.extensions.user-theme name "$THEME_NAME"
  echo "Shell theme set to: $THEME_NAME"
}

maybe_flatpak() {
  if [[ "$FLATPAK" -ne 1 ]]; then
    if command -v flatpak >/dev/null 2>&1; then
      echo "For Flatpak apps: ./install.sh --flatpak"
    fi
    return 0
  fi

  if ! command -v flatpak >/dev/null 2>&1; then
    echo "Warning: flatpak not found, --flatpak skipped." >&2
    return 0
  fi

  flatpak override --user --filesystem=xdg-config/gtk-4.0:ro
  echo "Flatpak can read xdg-config/gtk-4.0."
}

install_shell_theme
install_gtk_overlays
enable_dark_skeleton
enable_user_theme
maybe_flatpak

cat <<EOF

Installed.

- Files / Settings: fully quit the app (nautilus -q) and reopen.
- Shell: log out on Wayland. On X11, Alt+F2 → r.
- Optional icons: gsettings set org.gnome.desktop.interface icon-theme 'Yaru'

To remove: ./uninstall.sh
EOF
