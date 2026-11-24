#!/usr/bin/env bash
# ./install.sh [--layout]   Plasma 6 theme install for the current user. No root needed.
set -euo pipefail
[ "$(id -u)" -ne 0 ] || { echo "Run this as yourself, not root."; exit 1; }
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; S="$HOME/.local/share"; C="$HOME/.config"
bak="$S/framework-dots-backup-$(date +%Y%m%d-%H%M%S)"; mkdir -p "$bak"
for f in kdeglobals kwinrc breezerc dolphinrc ksplashrc plasmarc kitty/kitty.conf plasmashellrc plasma-org.kde.plasma.desktop-appletsrc; do
  [ -e "$C/$f" ] && { mkdir -p "$bak/$(dirname "$f")"; cp -a "$C/$f" "$bak/$f"; }; done
put() { mkdir -p "$2"; cp -a "$1" "$2/"; }
put "$here/icons/nothing-dots" "$S/icons"; mkdir -p "$S/icons/hicolor/scalable/apps"; cp "$here"/icons/hicolor/*.svg "$S/icons/hicolor/scalable/apps/"
for p in "$here"/plasmoids/*; do put "$p" "$S/plasma/plasmoids"; done
put "$here/theme/breeze-rounded-dock" "$S/plasma/desktoptheme"; put "$here/splash/framework.dots.desktop" "$S/plasma/look-and-feel"
put "$here/colors/FrameworkGraphite.colors" "$S/color-schemes"; put "$here/fonts/space-mono" "$S/fonts"
mkdir -p "$HOME/Pictures/Wallpapers"; cp "$here"/wallpapers/still/* "$HOME/Pictures/Wallpapers/"
put "$here/bin/claude-usage" "$HOME/.local/bin"; mkdir -p "$C/kitty"; cp "$here/kitty/kitty.conf" "$C/kitty/kitty.conf"
# Waywallen looks for this folder layout; Steam itself is not needed
we="$HOME/FrameworkDots-Wallpapers/steamapps/common/wallpaper_engine/projects/myprojects"; mkdir -p "$we"; cp -a "$here"/wallpapers/live/* "$we/"
# Dotted volume/brightness pop-up: overrides one QML module for plasmashell only
sys=/usr/lib/qt6/qml/org/kde/plasma/workspace/osd
if [ -f "$sys/Osd.qml" ]; then o="$S/plasma-qml/org/kde/plasma/workspace/osd"; mkdir -p "$o" "$C/systemd/user/plasma-plasmashell.service.d"
  grep -v '^prefer' "$sys/qmldir" > "$o/qmldir"; cp "$sys/Osd.qml" "$sys/plasmashell_osd.qmltypes" "$o/"; cp "$here/osd/OsdItem.qml" "$o/"; ln -sf "$sys/libplasmashell_osd.so" "$o/"
  printf '[Service]\nEnvironment=QML_IMPORT_PATH=%%h/.local/share/plasma-qml\n' > "$C/systemd/user/plasma-plasmashell.service.d/dot-osd.conf"; fi
k() { kwriteconfig6 --file "$1" --group "$2" --key "$3" "$4"; }
F="Space Mono,9,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"; for x in font menuFont toolBarFont fixed; do k kdeglobals General $x "$F"; done
k kdeglobals General smallestReadableFont "Space Mono,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"; k kdeglobals WM activeFont "$F"
k kdeglobals KDE frameContrast 0.1; k breezerc Windeco TitleAlignment AlignCenter; k breezerc Windeco DrawBackgroundGradient false; k breezerc Common OutlineIntensity OutlineLow
k dolphinrc General ShowStatusBar Small; k dolphinrc General ShowZoomSlider false; k dolphinrc IconsMode IconSize 80; k dolphinrc IconsMode PreviewSize 96
k ksplashrc KSplash Engine KSplashQML; k ksplashrc KSplash Theme framework.dots.desktop; k plasmarc Theme name breeze-rounded-dock
fc-cache -f "$S/fonts" 2>/dev/null || true
if [ -z "${FD_TEST:-}" ]; then
  plasma-apply-colorscheme FrameworkGraphite || true
  ci="$(find /usr/lib /usr/libexec -name plasma-changeicons 2>/dev/null | head -1 || true)"; if [ -n "$ci" ]; then "$ci" nothing-dots; else k kdeglobals Icons Theme nothing-dots; fi
  rm -f "$HOME"/.cache/plasma_theme_breeze-rounded-dock* "$HOME/.cache/ksvg-elements"; systemctl --user daemon-reload; systemctl --user restart plasma-plasmashell; sleep 8
  if [ "${1:-}" = "--layout" ]; then qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$(cat "$here/layout.js")"; fi
fi
echo "Done. Log out and back in. Your previous settings are in $bak"
