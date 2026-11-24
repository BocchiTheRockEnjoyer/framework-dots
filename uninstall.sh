#!/usr/bin/env bash
# Removes Framework Dots and puts back the settings it changed. No root needed.
#   ./uninstall.sh          asks first
#   ./uninstall.sh --yes    no questions (keeps the moving wallpaper app)
# Settings you have changed yourself since installing are left alone.
set -uo pipefail

yes=0
while [ $# -gt 0 ]; do
  case "$1" in -y|--yes) yes=1 ;; -h|--help) sed -n '2,5s/^# \{0,1\}//p' "${BASH_SOURCE[0]}"; exit 0 ;; *) echo "Unknown option: $1"; exit 2 ;; esac
  shift
done
[ "$(id -u)" -ne 0 ] || { echo "Run this as yourself, not with sudo."; exit 1; }
command -v kwriteconfig6 >/dev/null || { echo "Missing 'kwriteconfig6', which comes with Plasma 6. Nothing was changed."; exit 1; }
[ -n "${HOME:-}" ] && [ -d "$HOME" ] || { echo "Can't find your home folder."; exit 1; }
S="$HOME/.local/share"; C="$HOME/.config"; state="$S/framework-dots"
if [ ! -d "$state" ] && [ ! -d "$S/icons/nothing-dots" ]; then echo "Framework Dots doesn't seem to be installed. Nothing was changed."; exit 0; fi
if [ "$yes" = 0 ] && [ ! -t 0 ] && [ -z "${FD_ANSWERS:-}" ]; then echo "Run it in a terminal, or add --yes."; exit 1; fi

ask() {
  local a
  [ "$yes" = 0 ] || { [ "$2" = y ]; return; }
  while :; do
    if [ "$2" = y ]; then printf '%s [Y/n] ' "$1"; else printf '%s [y/N] ' "$1"; fi
    read -r a || { echo; echo "No answer, so nothing more was done."; exit 1; }
    case "${a:-$2}" in [Yy]*) return 0 ;; [Nn]*) return 1 ;; *) echo "Please type y or n." ;; esac
  done
}
plasma() {
  local q
  for q in qdbus6 qdbus-qt6 /usr/lib/qt6/bin/qdbus; do
    if command -v "$q" >/dev/null; then "$q" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$1" 2>/dev/null; return; fi
  done
  busctl --user call org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell evaluateScript s "$1" 2>/dev/null | sed 's/^s "//; s/"$//; s/\\n/ /g'
}
# Reads a key from one file only, ignoring system defaults. Fails if it isn't set there.
ini() {
  [ -f "$1" ] || return 1
  awk -v g="[$2]" -v k="$3=" '$0 == g { f = 1; next } /^\[/ { f = 0 } f && index($0, k) == 1 { print substr($0, length(k) + 1); r = 1; exit } END { exit !r }' "$1"
}

# The value in use: yours, or the copy KDE makes when switching light/dark mode
now() { ini "$C/$1" "$2" "$3" || ini "$C/kdedefaults/$1" "$2" "$3"; }

# Settings from before the theme: saved by the installer, or the oldest backup from its first version
orig="$state/original"
if [ ! -d "$orig" ]; then orig="$(find "$S" -maxdepth 1 -type d -name 'framework-dots-backup-*' 2>/dev/null | sort | head -1)"; fi

cat <<'T'

  Remove Framework Dots

  This removes the theme, its widgets, and the bar and dock it added, and puts back
  the settings it changed. Anything you have changed yourself since then stays.

T
[ -n "$orig" ] || echo "  Your old settings weren't found, so KDE's defaults will be used."
ask "Remove it now?" n || [ "$yes" = 1 ] || { echo "Nothing was changed."; exit 0; }
ways=0; if [ -e "$state/waywallen" ] && ask "Also remove the Waywallen app and its KDE plugin?" y && [ "$yes" = 0 ]; then ways=1; fi

# A copy of how things are now, in case something needs to be looked up later
bak="$S/framework-dots-backup-$(date +%Y%m%d-%H%M%S)-uninstall"; mkdir -p "$bak" || exit 1
for f in kdeglobals kwinrc breezerc dolphinrc ksplashrc plasmarc plasmashellrc plasma-org.kde.plasma.desktop-appletsrc; do [ ! -e "$C/$f" ] || cp -a "$C/$f" "$bak/"; done

ours_cs() { case "$1" in FrameworkGraphite|FrameworkGraphiteLight) return 0 ;; esac; return 1; }
if [ -z "${FD_TEST:-}" ]; then
  # ---- wallpaper: only if it's still one of ours ----
  js='var old = {};'
  if [ -f "$state/wallpaper" ]; then
    while IFS='|' read -r _ id plug img _; do
      case "$id$plug" in *[!A-Za-z0-9._-]*|"") continue ;; esac
      img="${img//\\/\\\\}"; img="${img//\"/\\\"}"; js="$js old[$id] = [\"$plug\", \"$img\"];"
    done < "$state/wallpaper"
  fi
  plasma "$js"' var ways = '"$ways"'; desktops().forEach(function(d) { var g = ["Wallpaper", "org.kde.image", "General"]; d.currentConfigGroup = g; var img = String(d.readConfig("Image") || "");
    var mine = d.wallpaperPlugin == "org.kde.image" && /Pictures\/Wallpapers\/(dot-matrix-blackhole(-light)?|framework-logo-dots|graphite-orange-dots)\.png$/.test(img);
    if (!mine && !(ways && d.wallpaperPlugin == "org.waywallen.kde")) return;
    var o = old[d.id]; if (o && ways && o[0] == "org.waywallen.kde") o = null;
    if (o && o[0] == "org.kde.image" && /Pictures\/Wallpapers\/(dot-matrix-blackhole|framework-logo-dots|graphite-orange-dots)/.test(o[1])) o = null;
    d.wallpaperPlugin = o ? o[0] : "org.kde.image"; d.currentConfigGroup = ["Wallpaper", d.wallpaperPlugin, "General"];
    if (!o || o[0] == "org.kde.image") d.writeConfig("Image", o ? o[1] : ""); d.reloadConfig() })' >/dev/null
  # ---- bar, dock and widgets ----
  ids="$(tr -cs '0-9' ',' < "$state/panels" 2>/dev/null | sed 's/^,*//; s/,*$//')"
  plasma "var ids = [$ids];"' var mine = ["dotboard", "dotmedia", "dotclock", "dotsysmon", "dotplaying", "dottimer", "dotkeys", "dotdesktops", "dotbatterypercent", "dotcenter", "claudeusage"].map(function(x) { return "local." + x });
    function clear(c) { mine.forEach(function(t) { c.widgets(t).forEach(function(w) { w.remove() }) }) }
    panels().forEach(function(p) {
      var bar = p.widgets("local.dotdesktops").length > 0 && p.widgets("local.dotclock").length > 0, dock = ids.indexOf(p.id) >= 0;
      var types = ["org.kde.plasma.icontasks", "org.kde.plasma.marginsseparator", "org.kde.plasma.kickerdash"];
      // Added by the first installer, which kept no record: match only a dock with exactly our three widgets
      if (!ids.length && p.location == "bottom" && p.widgets().length == 3 && types.every(function(t) { return p.widgets(t).length == 1 }))
        p.widgets("org.kde.plasma.kickerdash").forEach(function(w) { w.currentConfigGroup = ["General"]; if (w.readConfig("customButtonImage") == "view-app-grid-symbolic") dock = true });
      if (bar || dock) p.remove(); else clear(p) });
    desktops().forEach(clear)' >/dev/null
  sleep 2
  case "$(plasma 'print("FDN" + panels().length + ".")' || true)" in *FDN0.*) plasma 'loadTemplate("org.kde.plasma.desktop.defaultPanel")' >/dev/null; echo "Added KDE's standard panel, because there was no other one."; sleep 2 ;; esac
  systemctl --user disable --now framework-dots-mode.path framework-dots-mode.service >/dev/null 2>&1

  # ---- colours and icons ----
  if ours_cs "$(now kdeglobals General ColorScheme || true)"; then
    cs="$(ini "$orig/kdeglobals" General ColorScheme || ini "$orig/kdedefaults/kdeglobals" General ColorScheme || true)"; if [ -z "$cs" ] || ours_cs "$cs"; then cs=BreezeLight; fi
    plasma-apply-colorscheme "$cs" >/dev/null 2>&1 || plasma-apply-colorscheme BreezeLight >/dev/null 2>&1
  fi
  case "$(now kdeglobals Icons Theme || true)" in nothing-dots*)
    ic="$(ini "$orig/kdeglobals" Icons Theme || ini "$orig/kdedefaults/kdeglobals" Icons Theme || true)"; case "$ic" in ""|nothing-dots*) ic=breeze ;; esac
    ci="$(find /usr/lib /usr/lib64 /usr/libexec -name plasma-changeicons 2>/dev/null | head -1)"
    if [ -n "$ci" ]; then "$ci" "$ic" >/dev/null 2>&1; else kwriteconfig6 --file kdeglobals --group Icons --key Theme "$ic"; fi ;;
  esac
fi

# ---- settings (install.sh has the same list) ----
# file, group, key, then the value or values the theme uses
back() {
  local f="$1" g="$2" key="$3" cur old x; shift 3
  cur="$(now "$f" "$g" "$key")" || return 0
  for x in "$@"; do
    [ "$cur" = "$x" ] || continue
    if old="$(ini "$orig/$f" "$g" "$key")"; then
      for x in "$@"; do if [ "$old" = "$x" ]; then case "$x" in *framework.dots*|*framework-dots*|breeze-rounded-dock*|nothing-dots*|FrameworkGraphite*) old="" ;; esac; fi; done
    else old=""; fi
    if [ -n "$old" ]; then kwriteconfig6 --file "$f" --group "$g" --key "$key" "$old"
    else
      kwriteconfig6 --file "$f" --group "$g" --key "$key" --delete
      # KDE can leave a "deleted" marker that would hide its own default
      [ ! -f "$C/$f" ] || sed -i "/^$key\[\\\$d\]\$/d" "$C/$f"
    fi
    return 0
  done
}
F="Space Mono,9,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"; for x in font menuFont toolBarFont fixed; do back kdeglobals General $x "$F"; done
back kdeglobals General smallestReadableFont "Space Mono,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"; back kdeglobals WM activeFont "$F"
back kdeglobals General ColorScheme FrameworkGraphite FrameworkGraphiteLight; back kdeglobals Icons Theme nothing-dots nothing-dots-light
back kdeglobals KDE frameContrast 0.1; back breezerc Windeco TitleAlignment AlignCenter; back breezerc Windeco DrawBackgroundGradient false; back breezerc Common OutlineIntensity OutlineLow
back dolphinrc General ShowStatusBar Small; back dolphinrc General ShowZoomSlider false; back dolphinrc IconsMode IconSize 80; back dolphinrc IconsMode PreviewSize 96
D=framework.dots.desktop L=framework.dots.light.desktop
g=org.kde.kdecoration2
case "$(now kwinrc $g theme || true)" in __aurorae__svg__framework-dots*)
  back kwinrc $g library org.kde.kwin.aurorae; back kwinrc $g BorderSize Tiny; back kwinrc $g BorderSizeAuto false
  back kwinrc $g theme __aurorae__svg__framework-dots __aurorae__svg__framework-dots-light ;;
esac
back ksplashrc KSplash Theme $D $L
if ! ini "$C/ksplashrc" KSplash Theme >/dev/null; then back ksplashrc KSplash Engine KSplashQML; fi
back plasmarc Theme name breeze-rounded-dock breeze-rounded-dock-light
for x in LookAndFeelPackage DefaultDarkLookAndFeel DefaultLightLookAndFeel; do back kdeglobals KDE $x $D $L; done
# Switching light/dark mode makes KDE keep its own copy of the theme's choices
T='=(framework\.dots\.(light\.)?desktop|breeze-rounded-dock(-light)?|nothing-dots(-light)?|FrameworkGraphite(Light)?|__aurorae__svg__framework-dots(-light)?)$'
if grep -rqsE "$T|^framework\.dots\." "$C/kdedefaults" && [ -d "$orig/kdedefaults" ] && ! grep -rqsE "$T|^framework\.dots\." "$orig/kdedefaults"; then
  cp -a "$orig/kdedefaults/." "$C/kdedefaults/"
elif [ -d "$C/kdedefaults" ]; then
  for f in "$C"/kdedefaults/*; do
    [ -f "$f" ] || continue
    if [ "$(basename "$f")" = package ]; then
      if grep -qE '^framework\.dots\.' "$f"; then lf="$(ini "$orig/kdeglobals" KDE LookAndFeelPackage || true)"; case "$lf" in ""|framework.dots.*) lf=org.kde.breeze.desktop ;; esac; printf '%s' "$lf" > "$f"; fi
    elif grep -qE "$T" "$f"; then sed -i -E "/$T/d; /^library=org\.kde\.kwin\.aurorae\$/d" "$f"
    fi
  done
fi

# ---- files ----
if [ -e "$state/kitty.conf.ours" ]; then
  if cmp -s "$state/kitty.conf.ours" "$C/kitty/kitty.conf"; then
    rm -f "$C/kitty/kitty.conf"; if [ -e "$orig/kitty/kitty.conf" ] && ! cmp -s "$orig/kitty/kitty.conf" "$state/kitty.conf.ours"; then cp -a "$orig/kitty/kitty.conf" "$C/kitty/kitty.conf"; fi
  else echo "Left kitty.conf alone, because you've edited it."; fi
else
  # The first installer always replaced kitty.conf and kept no record; these are its unedited versions
  case "$(sha256sum "$C/kitty/kitty.conf" 2>/dev/null | cut -d' ' -f1)" in
    a687bc540153b51bceec08a7db95a2af2a0d7278e399cebcbac0e692db7b52d4)
      rm -f "$C/kitty/kitty.conf"; if [ -e "$orig/kitty/kitty.conf" ]; then cp -a "$orig/kitty/kitty.conf" "$C/kitty/kitty.conf"; fi ;;
  esac
fi
for f in "$state"/*-theme.auto.conf; do if [ -e "$f" ] && cmp -s "$f" "$C/kitty/$(basename "$f")"; then rm -f "$C/kitty/$(basename "$f")"; fi; done
for w in dotboard dotmedia dotclock dotsysmon dotplaying dottimer dotkeys dotdesktops dotbatterypercent dotcenter claudeusage; do rm -rf "$S/plasma/plasmoids/local.$w"; done
rm -rf "$S/icons/nothing-dots" "$S/icons/nothing-dots-light" "$S/plasma/desktoptheme/breeze-rounded-dock" "$S/plasma/desktoptheme/breeze-rounded-dock-light"
rm -rf "$S/plasma/look-and-feel/$D" "$S/plasma/look-and-feel/$L" "$S/fonts/fd-dots" "$S/plasma-qml/org/kde/plasma/workspace/osd"
rm -f "$S/icons/hicolor/scalable/apps"/framework-logo-dots*.svg
rmdir -p "$S/plasma-qml/org/kde/plasma/workspace" 2>/dev/null
rm -f "$S/color-schemes/FrameworkGraphite.colors" "$S/color-schemes/FrameworkGraphiteLight.colors"
[ -e "$state/keep-space-mono" ] || rm -rf "$S/fonts/space-mono"
if [ -s "$state/pictures.sha256" ]; then
  while read -r h p; do case "$p" in Pictures/Wallpapers/*) if [ "$(sha256sum "$HOME/$p" 2>/dev/null | cut -d' ' -f1)" = "$h" ]; then rm -f "$HOME/$p"; fi ;; esac; done < "$state/pictures.sha256"
fi
rm -f "$C/systemd/user/plasma-plasmashell.service.d/dot-osd.conf" "$C"/systemd/user/framework-dots-mode.path "$C"/systemd/user/framework-dots-mode.service
rmdir "$C/systemd/user/plasma-plasmashell.service.d" 2>/dev/null
rm -rf "$S/aurorae/themes/framework-dots" "$S/aurorae/themes/framework-dots-light"
if [ -s "$state/terminal.sha256" ]; then
  while read -r h p; do
    case "$p" in .config/*|.local/bin/*) ;; *) continue ;; esac
    if [ "$(sha256sum "$HOME/$p" 2>/dev/null | cut -d' ' -f1)" = "$h" ]; then rm -f "$HOME/$p"; elif [ -e "$HOME/$p" ]; then echo "Left ~/$p alone, because it has changed."; fi
  done < "$state/terminal.sha256"
  # btop rewrites its own settings, so that file usually counts as changed
  [ ! -f "$C/btop/btop.conf" ] || sed -i -E 's/^color_theme = "framework-dots(-light)?"$/color_theme = "Default"/' "$C/btop/btop.conf"
  (cd "$C" && rmdir fastfetch fish/functions btop/themes btop cava 2>/dev/null)
fi
rm -f "$HOME/.local/bin/framework-dots-mode" "$HOME/.local/bin/claude-usage"
if grep -qs 'claude-usage' "$HOME/.claude/settings.json"; then echo "Note: ~/.claude/settings.json still mentions claude-usage. Remove that statusLine yourself."; fi
if [ "$ways" = 1 ]; then
  rm -f "$C/autostart/waywallen.desktop" "$S/applications/waywallen.desktop" "$HOME/Applications/waywallen.AppImage"
  kpackagetool6 --type Plasma/Wallpaper -r org.waywallen.kde >/dev/null 2>&1
  echo "Removed Waywallen. If it's still running, it stops when you log out."
fi
if [ "$ways" = 1 ] || [ ! -e "$state/waywallen" ]; then
  # Only our two; anything else in there isn't ours
  we="FrameworkDots-Wallpapers/steamapps/common/wallpaper_engine/projects/myprojects"
  rm -rf "$HOME/$we/dot-matrix-blackhole" "$HOME/$we/dot-matrix-swirl"; (cd "$HOME" && rmdir -p "$we" 2>/dev/null)
else echo "Kept ~/FrameworkDots-Wallpapers, because Waywallen is still installed."; fi
fc-cache -f "$S/fonts" 2>/dev/null
rm -f "$HOME"/.cache/plasma_theme_*.kcache "$HOME/.cache/ksvg-elements"
[ -z "$orig" ] || [ "$orig" != "$state/original" ] || cp -a "$orig" "$bak/original-settings"
if [ -e "$state/waywallen" ] && [ "$ways" = 0 ]; then find "$state" -mindepth 1 -maxdepth 1 ! -name waywallen -exec rm -rf {} +; else rm -rf "$state"; fi
if [ -z "${FD_TEST:-}" ]; then busctl --user call org.kde.KWin /KWin org.kde.KWin reconfigure >/dev/null 2>&1; systemctl --user daemon-reload 2>/dev/null; systemctl --user restart plasma-plasmashell 2>/dev/null; fi
echo
echo "Framework Dots is removed. Log out and back in to finish."
echo "Backups were kept in ~/.local/share/framework-dots-backup-… (safe to delete)."
