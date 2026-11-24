#!/usr/bin/env bash
# Downloads Waywallen, its KDE plugin and the web wallpaper plugin (x86_64), and checks each file.
# These are other people's projects: https://github.com/waywallen   No root needed.
set -euo pipefail
[ "$(id -u)" -ne 0 ] || { echo "Run this as yourself, not root."; exit 1; }
[ "$(uname -m)" = x86_64 ] || { echo "This helper only supports x86_64 computers."; exit 1; }
for c in curl sha256sum unzip kpackagetool6; do command -v $c >/dev/null || { echo "Please install '$c' first."; exit 1; }; done
G=https://github.com/waywallen; t="$(mktemp -d)"; trap 'rm -rf "$t"' EXIT
get() { echo "Downloading $2 ..."; curl -fL --progress-bar -o "$t/$2" "$1"; echo "$3  $t/$2" | sha256sum -c --quiet || { echo "Download was damaged or changed. Stopping."; exit 1; }; }
get $G/waywallen/releases/download/v0.6.1/waywallen-0.6.1-x86_64.AppImage waywallen.AppImage dd1c58c7eacdee1291fc3ad9b0e0bcd864d6b5feb1c5065b8ab17378d176e62d
get $G/waywallen-display/releases/download/v0.4.6/waywallen-kde-0.4.6-x86_64.zip waywallen-kde.zip f98647b301d16c00f711adc7dcbf8ca6d23f237fad1835f13916079ad9c032ce
get $G/open-wallpaper-engine/releases/download/v0.3.4/org.waywallen.open-wallpaper-engine-0.3.4-linux-x86_64.zip web-wallpaper-plugin.zip 94db107147c62ca29a1b44ca99a32d809ed9f0f889f381ca268f66e9cd087ae2
mkdir -p "$HOME/Applications" "$HOME/Downloads" "$HOME/.local/share/applications" "$HOME/.config/autostart"
install -m 755 "$t/waywallen.AppImage" "$HOME/Applications/waywallen.AppImage"; cp "$t/web-wallpaper-plugin.zip" "$HOME/Downloads/"
unzip -q "$t/waywallen-kde.zip" -d "$t/kde"
kpackagetool6 --type Plasma/Wallpaper -i "$t/kde/org.waywallen.kde" 2>/dev/null || kpackagetool6 --type Plasma/Wallpaper -u "$t/kde/org.waywallen.kde"
printf '[Desktop Entry]\nType=Application\nName=Waywallen\nExec=%s/Applications/waywallen.AppImage\nIcon=preferences-desktop-wallpaper\nCategories=Graphics;\n' "$HOME" > "$HOME/.local/share/applications/waywallen.desktop"
printf '[Desktop Entry]\nType=Application\nName=Waywallen\nExec=sh -c "sleep 5; exec %s/Applications/waywallen.AppImage --no-ui"\n' "$HOME" > "$HOME/.config/autostart/waywallen.desktop"
[ -n "${FD_TEST:-}" ] || systemctl --user restart plasma-plasmashell
echo; echo "Done. Now follow steps 2 to 5 under 'Moving wallpaper' in the README."
