# milknome

A dark overlay for GNOME 50–51 using an expanded [Tailwind Neutral](https://tailwindcss.com/docs/colors) scale. Adwaita geometry stays; stock dark colors are replaced.

## What it changes

| Surface | How |
|---|---|
| Top bar, menus, overview, OSD | `gnome-shell/gnome-shell.css` (User Themes) |
| Files, Settings, and other libadwaita apps | `~/.config/gtk-4.0/` |
| Legacy GTK3 apps | `~/.config/gtk-3.0/` |

Picking the theme in Tweaks alone will not recolor Files or Settings. libadwaita ignores theme directories; the installer writes user CSS.

## Requirements

- GNOME 50 or 51
- [User Themes](https://extensions.gnome.org/extension/19/user-themes/)  
  (`gnome-shell-extension-user-theme` / `gnome-shell-extensions`)

Icons are not bundled. Yaru is recommended and selected separately.

## Install

```bash
git clone https://github.com/dukemagna/milknome.git
cd milknome
./install.sh
```

Let Flatpak apps read the palette too:

```bash
./install.sh --flatpak
```

Then:

- Files: `nautilus -q` and reopen
- Shell: log out on Wayland; on X11 use `Alt+F2` → `r`

Optional icons:

```bash
gsettings set org.gnome.desktop.interface icon-theme 'Yaru'
```

## GNOME 51 Shell

The Shell surfaces are fully opaque (0% transparency), including menus,
notifications, panel, dash, OSD and dialogs. Floating surfaces use a subtle
1px-offset, 4px-blur shadow at 10% opacity;
keyboard focus rings remain visible. Text and icons stay opaque.
Empty notification and libadwaita status pages use 32px icons, smaller regular
text, and tighter spacing. Loading spinners keep their original styling.
A faint border separates floating menus from the wallpaper; nested controls
keep solid fills for a consistent appearance.

Update only Shell (including selecting milknome in User Themes):

```bash
./install.sh --shell-only
```

The CSS was checked with GNOME Shell 51.1's St parser. Opaque backgrounds conceal any blur supplied by extensions such as Blur My Shell.
The theme deliberately uses St-compatible CSS rather than browser filters.

When Blur My Shell is enabled, the installer disables its popup and panel
background overrides and enables `preserve-shell-theme` when available.
This prevents the extension's automatic light/dark styling from replacing
milknome's colors and corners. Blur masks are matched to the theme (16px outer surfaces, 12px quick-settings
submenus, all corners rounded). Blur enablement and pipelines are left alone.
These preferences remain after uninstall; they can be changed again in Blur
My Shell preferences (popup/panel background override, preserve Shell theme).

Reselect the Shell theme or log out and back in if the previous stylesheet
is still cached. GNOME 50 remains a compatibility target, but this update
was validated against the installed 51.1 libraries, not a GNOME 50 session.

## Uninstall

```bash
./uninstall.sh
```

If the repo lives in `~/.local/share/themes/milknome`, that folder is not deleted (git checkout is kept). `color-scheme` is left as-is.

## Palette

Source: [`palette.css`](palette.css)

Official Tailwind stops: 50–950. Extra steps: 0, 25, 75, 150, 250, 350, 450, 550, 650, 750, 850, 875, 925, 975, 1000.

| Role | Token | Hex |
|---|---|---|
| Primary (action) | GNOME Settings accent | system |
| Warning | `--warning` | `#ff9f0a` |
| Text | 50 | `#fafafa` |
| Menu / card | 800 | `#262626` |
| Header bar | 850 | `#1e1e1e` |
| Window | 900 | `#171717` |
| Sidebar | | `#151515` |
| View / list | 925 | `#111111` |

Install sets `org.gnome.desktop.interface color-scheme` to `prefer-dark`. That is the dark widget skeleton, not GNOME’s stock palette. Visible colors come from milknome.

## Layout

```
palette.css                 # GTK4 variables (source of truth)
gtk-4.0/milknome.css        # libadwaita copy
gtk-3.0/milknome.css        # GTK3 @define-color
gnome-shell/gnome-shell.css # shell overlay
install.sh / uninstall.sh
```
