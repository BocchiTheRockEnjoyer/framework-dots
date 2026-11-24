#!/usr/bin/env bash
# Framework Dots installer for KDE Plasma 6. Installs for the current user; no root needed.
#   ./install.sh                 asks a few questions first
#   ./install.sh --yes           no questions: theme only, unless you add the options below
#   --layout / --no-layout       add (or don't add) the top bar, dock and desktop widgets
#   --wallpaper still|moving|none
#   --kitty / --no-kitty         use (or don't use) the kitty terminal colours
set -euo pipefail

yes=0 layout="" wall="" kitty=""
usage() { sed -n '2,8s/^# \{0,1\}//p' "${BASH_SOURCE[0]}"; }
while [ $# -gt 0 ]; do
  case "$1" in
    -y|--yes) yes=1 ;;
    --layout) layout=y ;; --no-layout) layout=n ;;
    --kitty) kitty=y ;; --no-kitty) kitty=n ;;
    --wallpaper) wall="${2:-}"; case "$wall" in still|moving|none) shift ;; *) echo "--wallpaper needs still, moving or none."; exit 2 ;; esac ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 2 ;;
  esac
  shift
done

# ---- checks: nothing is changed before these pass ----
[ "$(id -u)" -ne 0 ] || { echo "Run this as yourself, not with sudo."; exit 1; }
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
S="$HOME/.local/share"; C="$HOME/.config"; state="$S/framework-dots"
v="${KDE_SESSION_VERSION:-}"
[ -n "$v" ] || v="$(QT_QPA_PLATFORM=offscreen plasmashell --version 2>/dev/null | sed -n 's/[^0-9]*\([0-9]*\).*/\1/p' | head -1 || true)"
if [ -z "${FD_TEST:-}" ] && [ "$v" != 6 ]; then
  echo "This needs KDE Plasma 6${v:+, and this looks like Plasma $v}. Nothing was changed."; exit 1
fi
for c in kwriteconfig6 plasma-apply-colorscheme awk; do
  command -v "$c" >/dev/null || { echo "Missing '$c', which comes with Plasma 6. Nothing was changed."; exit 1; }
done

# Runs a Plasma script and prints its output on one line
plasma() {
  local q
  for q in qdbus6 qdbus-qt6 /usr/lib/qt6/bin/qdbus; do
    if command -v "$q" >/dev/null; then "$q" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$1" 2>/dev/null; return; fi
  done
  busctl --user call org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell evaluateScript s "$1" 2>/dev/null | sed 's/^s "//; s/"$//; s/\\n/ /g'
}
ask() {  # question, default y or n
  local a
  if [ "$yes" = 1 ]; then [ "$2" = y ]; return; fi
  while :; do
    if [ "$2" = y ]; then printf '%s [Y/n] ' "$1"; else printf '%s [y/N] ' "$1"; fi
    read -r a || { echo; echo "No answer, so nothing more was done."; exit 1; }
    case "${a:-$2}" in [Yy]*) return 0 ;; [Nn]*) return 1 ;; *) echo "Please type y or n." ;; esac
  done
}
if [ "$yes" = 0 ] && [ ! -t 0 ] && [ -z "${FD_ANSWERS:-}" ]; then
  echo "There's no keyboard to answer questions with. Run it in a terminal, or add --yes."; exit 1
fi

# ---- questions ----
cat <<'T'

  Framework Dots

  This changes your KDE colours, icons, fonts, splash screen, panel style, volume
  pop-up and a few Dolphin settings. Your current settings are saved first, and
  the uninstaller can put them back. No password is needed.

T
has_layout=0
if [ -z "${FD_TEST:-}" ]; then
  case "$(plasma 'var n = 0; panels().forEach(function(p) { n += p.widgets("local.dotdesktops").length }); print("FDN" + n)' || true)" in *FDN0*|"") ;; *FDN*) has_layout=1 ;; esac
fi
if [ "$has_layout" = 1 ]; then
  [ "$layout" != y ] || echo "The bar and dock are already there, so they won't be added again."
  layout=n
elif [ -z "$layout" ]; then
  if [ "$yes" = 0 ] && ask "Add the top bar, dock and desktop widgets? (your own panels stay)" y; then layout=y; else layout=n; fi
fi
if [ -z "$kitty" ]; then
  kitty=n
  if [ "$yes" = 0 ] && command -v kitty >/dev/null; then
    d=y; [ ! -e "$C/kitty/kitty.conf" ] || d=n
    ! ask "Use the kitty terminal colours? (replaces kitty.conf)" "$d" || kitty=y
  fi
fi
if [ -z "$wall" ]; then
  wall=none
  if [ "$yes" = 0 ]; then
    if ask "Set the black hole picture as your wallpaper?" y; then wall=still; fi
    if [ "$(uname -m)" = x86_64 ] && ask "Also download the moving wallpaper app? (about 235 MB, a few manual steps)" n; then wall="$wall+moving"; fi
  fi
fi
[ "$wall" != moving ] || wall=none+moving
if [ "$yes" = 0 ]; then
  echo; echo "  Theme:      yes"
  echo "  Bar, dock:  $([ "$layout" = y ] && echo yes || { [ "$has_layout" = 1 ] && echo "already there" || echo no; })"
  echo "  Kitty:      $([ "$kitty" = y ] && echo yes || echo no)"
  case "$wall" in none) w=no ;; still) w=picture ;; none+moving) w="moving wallpaper app" ;; *) w="picture, and the moving wallpaper app" ;; esac
  echo "  Wallpaper:  $w"; echo
  ask "Install now?" y || { echo "Nothing was changed."; exit 0; }
fi

# ---- save the original settings (only the first time, so a reinstall can't replace them) ----
trap 'echo; echo "Something failed, so the install stopped partway. To go back, run:  bash $state/uninstall.sh"' ERR
conf="kdeglobals kwinrc breezerc dolphinrc ksplashrc plasmarc kitty/kitty.conf plasmashellrc plasma-org.kde.plasma.desktop-appletsrc kdedefaults"
save() { local f; for f in $conf; do if [ -e "$C/$f" ]; then mkdir -p "$1/$(dirname "$f")"; cp -a "$C/$f" "$1/$f"; fi; done; }
bak="$S/framework-dots-backup-$(date +%Y%m%d-%H%M%S)"; mkdir -p "$bak" "$state"; save "$bak"
cp "$here/uninstall.sh" "$state/uninstall.sh"
if [ ! -d "$state/original" ]; then
  # Installed earlier with the old installer? Then its oldest backup has the real originals.
  old=""; if [ -d "$S/icons/nothing-dots" ]; then old="$(find "$S" -maxdepth 1 -type d -name 'framework-dots-backup-*' ! -path "$bak" | sort | head -1)"; fi
  rm -rf "$state/original.new"; mkdir -p "$state/original.new"; cp -a "${old:-$bak}/." "$state/original.new/"
  # Fonts that were already here are not ours to remove
  if [ -z "$old" ] && [ -d "$S/fonts/space-mono" ]; then touch "$state/keep-space-mono"; fi
  mv "$state/original.new" "$state/original"
fi

# ---- files ----
echo "Copying files ..."
put() { mkdir -p "$2"; rm -rf "${2:?}/$(basename "$1")"; cp -a "$1" "$2/"; }
put "$here/icons/nothing-dots" "$S/icons"; put "$here/icons/nothing-dots-light" "$S/icons"
mkdir -p "$S/icons/hicolor/scalable/apps"; cp "$here"/icons/hicolor/*.svg "$S/icons/hicolor/scalable/apps/"
for p in "$here"/plasmoids/*; do put "$p" "$S/plasma/plasmoids"; done
for x in "" -light; do put "$here/theme/breeze-rounded-dock$x" "$S/plasma/desktoptheme"; done
for x in "" light.; do put "$here/splash/framework.dots.${x}desktop" "$S/plasma/look-and-feel"; done
for x in "" Light; do put "$here/colors/FrameworkGraphite$x.colors" "$S/color-schemes"; done
[ -e "$state/keep-space-mono" ] || put "$here/fonts/space-mono" "$S/fonts"
put "$here/fonts/fd-dots" "$S/fonts"
mkdir -p "$HOME/Pictures/Wallpapers"
for f in "$here"/wallpapers/still/*; do
  t="$HOME/Pictures/Wallpapers/$(basename "$f")"
  if [ ! -e "$t" ]; then cp "$f" "$t"; fi
  ! cmp -s "$f" "$t" || (cd "$HOME" && sha256sum "Pictures/Wallpapers/$(basename "$f")")
done > "$state/pictures.sha256"
put "$here/bin/claude-usage" "$HOME/.local/bin"; put "$here/bin/framework-dots-mode" "$HOME/.local/bin"
mkdir -p "$C/systemd/user"; cp "$here"/systemd/* "$C/systemd/user/"
if [ "$kitty" = y ]; then mkdir -p "$C/kitty"; rm -f "$C/kitty/kitty.conf"; cp "$here/kitty/kitty.conf" "$C/kitty/kitty.conf"; cp "$here/kitty/kitty.conf" "$state/kitty.conf.ours"; fi
# Waywallen looks for this folder layout; Steam itself is not needed
we="$HOME/FrameworkDots-Wallpapers/steamapps/common/wallpaper_engine/projects/myprojects"; mkdir -p "$we"; cp -a "$here"/wallpapers/live/* "$we/"
# Dotted volume/brightness pop-up: overrides one QML module for plasmashell only
sys=/usr/lib/qt6/qml/org/kde/plasma/workspace/osd
if [ -f "$sys/Osd.qml" ]; then
  o="$S/plasma-qml/org/kde/plasma/workspace/osd"; mkdir -p "$o" "$C/systemd/user/plasma-plasmashell.service.d"
  grep -v '^prefer' "$sys/qmldir" > "$o/qmldir"; cp "$sys/Osd.qml" "$sys/plasmashell_osd.qmltypes" "$o/"; cp "$here/osd/OsdItem.qml" "$o/"; ln -sf "$sys/libplasmashell_osd.so" "$o/"
  printf '[Service]\nEnvironment=QML_IMPORT_PATH=%%h/.local/share/plasma-qml\n' > "$C/systemd/user/plasma-plasmashell.service.d/dot-osd.conf"
else
  echo "Skipping the dotted volume pop-up: KDE keeps its files somewhere else on this system."
fi
fc-cache -f "$S/fonts" 2>/dev/null || true

# ---- settings (uninstall.sh has the same list) ----
echo "Changing settings ..."
k() { kwriteconfig6 --file "$1" --group "$2" --key "$3" "$4"; }
F="Space Mono,9,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"; for x in font menuFont toolBarFont fixed; do k kdeglobals General $x "$F"; done
k kdeglobals General smallestReadableFont "Space Mono,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"; k kdeglobals WM activeFont "$F"
k kdeglobals KDE frameContrast 0.1; k breezerc Windeco TitleAlignment AlignCenter; k breezerc Windeco DrawBackgroundGradient false; k breezerc Common OutlineIntensity OutlineLow
k dolphinrc General ShowStatusBar Small; k dolphinrc General ShowZoomSlider false; k dolphinrc IconsMode IconSize 80; k dolphinrc IconsMode PreviewSize 96
k ksplashrc KSplash Engine KSplashQML; k ksplashrc KSplash Theme framework.dots.desktop; k plasmarc Theme name breeze-rounded-dock
k kdeglobals KDE LookAndFeelPackage framework.dots.desktop; k kdeglobals KDE DefaultDarkLookAndFeel framework.dots.desktop; k kdeglobals KDE DefaultLightLookAndFeel framework.dots.light.desktop
if [ -n "${FD_TEST:-}" ]; then k kdeglobals General ColorScheme FrameworkGraphite; k kdeglobals Icons Theme nothing-dots; echo "Done (test mode)."; exit 0; fi

plasma-apply-colorscheme FrameworkGraphite >/dev/null || true
ci="$(find /usr/lib /usr/lib64 /usr/libexec -name plasma-changeicons 2>/dev/null | head -1 || true)"
if [ -n "$ci" ]; then "$ci" nothing-dots >/dev/null 2>&1 || k kdeglobals Icons Theme nothing-dots; else k kdeglobals Icons Theme nothing-dots; fi
rm -f "$HOME"/.cache/plasma_theme_breeze-rounded-dock* "$HOME/.cache/ksvg-elements"
systemctl --user daemon-reload 2>/dev/null || true
systemctl --user enable --now framework-dots-mode.path framework-dots-mode.service >/dev/null 2>&1 || true
echo "Restarting the taskbar ..."
systemctl --user restart plasma-plasmashell 2>/dev/null || echo "Couldn't restart the taskbar. Logging out and back in will do it."
ready=0; for _ in $(seq 30); do sleep 1; case "$(plasma 'print("FDOK")' || true)" in *FDOK*) ready=1; break ;; esac; done

if [ "$ready" = 1 ]; then
  sleep 4
  if [ "$layout" = y ]; then
    ids="$(plasma "$(cat "$here/layout.js")" | sed -n 's/.*FDIDS \([0-9]* [0-9]*\).*/\1/p' || true)"
    case "$ids" in *[0-9]*) echo "$ids" >> "$state/panels"; echo "Added the bar, dock and widgets." ;; *) echo "The bar and dock may not have been added. Run this installer again to retry." ;; esac
  fi
  case "$wall" in still*)
    # Remember the old wallpaper, unless it's already ours
    if [ ! -e "$state/wallpaper" ]; then
      plasma 'desktops().forEach(function(d) { d.currentConfigGroup = ["Wallpaper", d.wallpaperPlugin, "General"]; print("FDW|" + d.id + "|" + d.wallpaperPlugin + "|" + (d.readConfig("Image") || "") + "|\n") })' | grep '^FDW' > "$state/wallpaper" || true
    fi
    plasma-apply-wallpaperimage "$HOME/Pictures/Wallpapers/dot-matrix-blackhole.png" >/dev/null 2>&1 || echo "Couldn't set the wallpaper. Right-click the desktop to choose it." ;;
  esac
elif [ "$layout" = y ]; then
  echo "The taskbar took too long to come back, so the bar and dock weren't added. Log in again and rerun this."
fi
trap - ERR
case "$wall" in *moving) bash "$here/wallpaper-setup.sh" || echo "The moving wallpaper didn't install. Everything else did." ;; esac
echo
echo "Done. Log out and back in to finish."
[ "$layout" != y ] || echo "To remove your old panel: right-click it, choose Show Panel Configuration, then Remove."
echo "To undo everything:  bash ~/.local/share/framework-dots/uninstall.sh"
echo "A copy of your settings from before this run is in ~/.local/share/$(basename "$bak")"
