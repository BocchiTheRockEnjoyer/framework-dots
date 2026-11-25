#!/usr/bin/env bash
# Framework Dots installer for KDE Plasma 6. Installs for the current user; no root needed.
#   ./install.sh                 asks a few questions first
#   ./install.sh --yes           no questions: theme only, unless you add the options below
#   --layout / --no-layout       add (or don't add) the top bar, dock and desktop widgets
#   --wallpaper still|moving|none
#   --kitty / --no-kitty         use (or don't use) the kitty terminal colours
#   --terminal / --no-terminal   add (or don't add) the looks for fastfetch, fish, btop, cava, bat, delta, lazygit, fzf, eza, micro and nvim
set -euo pipefail

yes=0 layout="" wall="" kitty="" term=""
usage() { sed -n '2,9s/^# \{0,1\}//p' "${BASH_SOURCE[0]}"; }
while [ $# -gt 0 ]; do
  case "$1" in
    -y|--yes) yes=1 ;;
    --layout) layout=y ;; --no-layout) layout=n ;;
    --terminal) term=y ;; --no-terminal) term=n ;;
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

  This changes your KDE colours, icons, pointer, fonts, splash screen, panel style, volume
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
if [ -z "$term" ]; then
  term=n
  if [ "$yes" = 0 ] && ask "Add the terminal looks (fastfetch, fish, btop, cava, bat, delta, lazygit, fzf, eza, micro, nvim)? (your own configs are never replaced)" y; then term=y; fi
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
  echo "  Terminal:   $([ "$term" = y ] && echo yes || echo no)"
  case "$wall" in none) w=no ;; still) w=picture ;; none+moving) w="moving wallpaper app" ;; *) w="picture, and the moving wallpaper app" ;; esac
  echo "  Wallpaper:  $w"; echo
  ask "Install now?" y || { echo "Nothing was changed."; exit 0; }
fi

# ---- save the original settings (only the first time, so a reinstall can't replace them) ----
trap 'echo; echo "Something failed, so the install stopped partway. To go back, run:  bash $state/uninstall.sh"' ERR
conf="kdeglobals kwinrc breezerc dolphinrc ksplashrc plasmarc kcminputrc kitty/kitty.conf plasmashellrc plasma-org.kde.plasma.desktop-appletsrc kdedefaults"
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

# Installed before the pointer was added? Then keep a note of the one in use now.
if [ ! -e "$state/original/kcminputrc" ] && [ -e "$C/kcminputrc" ] && ! grep -qs '^cursorTheme=framework-dots$' "$C/kcminputrc"; then cp -a "$C/kcminputrc" "$state/original/kcminputrc"; fi

# A changed accent colour goes back to orange while files are compared and copied, and is put back after
accent="$HOME/.local/bin/framework-dots-accent"
if [ -e "$C/framework-dots/accent" ] && [ -x "$accent" ]; then "$accent" reset --files-only --keep-choice --quiet || true; fi

# ---- files ----
echo "Copying files ..."
put() { mkdir -p "$2"; rm -rf "${2:?}/$(basename "$1")"; cp -a "$1" "$2/"; }
put "$here/icons/nothing-dots" "$S/icons"; put "$here/icons/nothing-dots-light" "$S/icons"
put "$here/cursors/framework-dots" "$S/icons"
# KDE looks for pointers in ~/.icons
if [ ! -e "$HOME/.icons/framework-dots" ]; then mkdir -p "$HOME/.icons"; rm -f "$HOME/.icons/framework-dots"; ln -s "$S/icons/framework-dots" "$HOME/.icons/framework-dots"; fi
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
for f in claude-usage framework-dots-mode framework-dots-accent framework-dots-wallpaper-fix; do put "$here/bin/$f" "$HOME/.local/bin"; done; put "$here/applications/framework-dots-accent.desktop" "$S/applications"
mkdir -p "$C/systemd/user"; cp "$here"/systemd/* "$C/systemd/user/"
if [ "$kitty" = y ]; then mkdir -p "$C/kitty"; rm -f "$C/kitty/kitty.conf"; cp "$here/kitty/kitty.conf" "$C/kitty/kitty.conf"; cp "$here/kitty/kitty.conf" "$state/kitty.conf.ours"
  # kitty switches between these by itself
  for f in "$here"/kitty/*-theme.auto.conf; do
    t="$C/kitty/$(basename "$f")"; if [ ! -e "$t" ] || cmp -s "$t" "$state/$(basename "$f")"; then cp "$f" "$t"; cp "$f" "$state/"; else echo "Kept your own: $t"; fi
  done
fi
# Terminal looks: only where nothing exists yet, or where it's an unedited copy from an earlier run
if [ "$term" = y ]; then
  skipped=""; new="$state/terminal.new"; : > "$new"
  while IFS= read -r f; do
    case "$f" in bin/*) t=".local/$f" ;; *) t=".config/$f" ;; esac
    if [ -e "$HOME/$t" ] && ! cmp -s "$here/terminal/$f" "$HOME/$t"; then
      h="$(sha256sum < "$HOME/$t" | cut -d' ' -f1)"
      if ! grep -qsF "$h  $t" "$state/terminal.sha256"; then skipped="$skipped ~/$t"; continue; fi
    fi
    # A second Neovim config would clash with the first
    if [ "$f" = nvim/init.lua ] && [ -e "$C/nvim/init.vim" ]; then skipped="$skipped ~/.config/nvim/init.vim"; continue; fi
    if [ ! -e "$HOME/$t" ] || grep -qsF "  $t" "$state/terminal.sha256"; then
      mkdir -p "$(dirname "$HOME/$t")"; cp "$here/terminal/$f" "$HOME/$t"; (cd "$HOME" && sha256sum "$t") >> "$new"
    fi
  done < <(cd "$here/terminal" && find . -type f | sed 's#^\./##' | sort)
  mv "$new" "$state/terminal.sha256"
  [ -z "$skipped" ] || echo "Kept your own:$skipped"
  if command -v bat >/dev/null; then bat cache --build >/dev/null 2>&1 || true; fi
  # Only a pointer to our colours is added to your git settings
  if command -v delta >/dev/null && command -v git >/dev/null && ! git config --global --get-all include.path 2>/dev/null | grep -qx '~/.config/delta/framework-dots.gitconfig'; then
    git config --global --add include.path '~/.config/delta/framework-dots.gitconfig' || true
  fi
fi
for x in dissolve minimize; do put "$here/effects/framework_dots_$x" "$S/kwin/effects"; done
put "$here/tabbox/framework_dots" "$S/kwin/tabbox"
mkdir -p "$S/org.kde.syntax-highlighting/themes"; cp "$here"/kate/*.theme "$S/org.kde.syntax-highlighting/themes/"
# Title bars: need KDE's Aurorae engine, which some systems don't install
for x in "" -light; do put "$here/aurorae/framework-dots$x" "$S/aurorae/themes"; done
deco=y; if [ -z "$(find /usr/lib /usr/lib64 -name 'org.kde.kwin.aurorae.so' 2>/dev/null | head -1)" ]; then
  deco=n; echo "Skipping the dotted title bars: KDE's Aurorae engine isn't installed."
  for x in "" light.; do sed -i 's/^library=org.kde.kwin.aurorae$/library=org.kde.breeze/; s/^theme=__aurorae__svg__framework-dots.*$/theme=Breeze/' "$S/plasma/look-and-feel/framework.dots.${x}desktop/contents/defaults"; done
fi
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

if [ -e "$C/framework-dots/accent" ]; then "$accent" reapply --files-only --quiet || echo "Couldn't put your accent colour back. Run: framework-dots-accent reapply"; fi

# ---- settings (uninstall.sh has the same list) ----
echo "Changing settings ..."
k() { kwriteconfig6 --file "$1" --group "$2" --key "$3" "$4"; }
F="Space Mono,9,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"; for x in font menuFont toolBarFont fixed; do k kdeglobals General $x "$F"; done
k kdeglobals General smallestReadableFont "Space Mono,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"; k kdeglobals WM activeFont "$F"
k kdeglobals KDE frameContrast 0.1; k breezerc Windeco TitleAlignment AlignCenter; k breezerc Windeco DrawBackgroundGradient false; k breezerc Common OutlineIntensity OutlineLow
k dolphinrc General ShowStatusBar Small; k dolphinrc General ShowZoomSlider false; k dolphinrc IconsMode IconSize 80; k dolphinrc IconsMode PreviewSize 96
k ksplashrc KSplash Engine KSplashQML; k ksplashrc KSplash Theme framework.dots.desktop; k plasmarc Theme name breeze-rounded-dock
k kdeglobals KDE LookAndFeelPackage framework.dots.desktop; k kdeglobals KDE DefaultDarkLookAndFeel framework.dots.desktop; k kdeglobals KDE DefaultLightLookAndFeel framework.dots.light.desktop
k kwinrc TabBox LayoutName framework_dots; for x in dissolve minimize; do k kwinrc Plugins framework_dots_${x}Enabled true; done; for x in scale glide fade squash magiclamp; do k kwinrc Plugins ${x}Enabled false; done
if [ "$deco" = y ]; then g=org.kde.kdecoration2; k kwinrc $g library org.kde.kwin.aurorae; k kwinrc $g theme __aurorae__svg__framework-dots; k kwinrc $g BorderSize Tiny; k kwinrc $g BorderSizeAuto false; fi
if [ -n "${FD_TEST:-}" ]; then k kdeglobals General ColorScheme FrameworkGraphite; k kdeglobals Icons Theme nothing-dots; k kcminputrc Mouse cursorTheme framework-dots; echo "Done (test mode)."; exit 0; fi

plasma-apply-colorscheme FrameworkGraphite >/dev/null || true
ci="$(find /usr/lib /usr/lib64 /usr/libexec -name plasma-changeicons 2>/dev/null | head -1 || true)"
if [ -n "$ci" ]; then "$ci" nothing-dots >/dev/null 2>&1 || k kdeglobals Icons Theme nothing-dots; else k kdeglobals Icons Theme nothing-dots; fi
plasma-apply-cursortheme framework-dots >/dev/null 2>&1 || k kcminputrc Mouse cursorTheme framework-dots
busctl --user call org.kde.KWin /KWin org.kde.KWin reconfigure >/dev/null 2>&1 || true
fx() { busctl --user call org.kde.KWin /Effects org.kde.kwin.Effects "$1" s "$2" >/dev/null 2>&1 || true; }
for x in scale glide fade squash magiclamp; do fx unloadEffect $x; done; for x in dissolve minimize; do fx loadEffect framework_dots_$x; done
rm -f "$HOME"/.cache/plasma_theme_breeze-rounded-dock* "$HOME/.cache/ksvg-elements"
systemctl --user daemon-reload 2>/dev/null || true
systemctl --user enable --now framework-dots-mode.path framework-dots-mode.service >/dev/null 2>&1 || true
systemctl --user enable framework-dots-wallpaper-fix.service >/dev/null 2>&1 || true
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
