import QtQuick
import QtQuick.Window
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

WallpaperItem {
    id: root
    readonly property var cfg: root.configuration
    // Colours come from the colour scheme, so light/dark mode and the accent follow by themselves
    Item { id: scheme; Kirigami.Theme.inherit: false; Kirigami.Theme.colorSet: Kirigami.Theme.Window
        readonly property color accent: Kirigami.Theme.highlightColor
        readonly property color bg: Kirigami.Theme.backgroundColor }
    readonly property bool light: root.cfg.FollowMode && 0.299 * scheme.bg.r + 0.587 * scheme.bg.g + 0.114 * scheme.bg.b > 0.5
    property real mode: light ? 1 : 0
    Behavior on mode { NumberAnimation { duration: 450; easing.type: Easing.InOutSine } }
    function mix(a, b, t) { a = Qt.color(a); b = Qt.color(b); return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1) }
    accentColor: scheme.accent

    Loader {
        id: cover
        active: root.cfg.PauseCovered
        source: "Covered.qml"
        onLoaded: item.screen = Qt.binding(() => Qt.rect(Screen.virtualX, Screen.virtualY, Screen.width, Screen.height))
    }
    Loader { id: power; active: root.cfg.PauseBattery; source: "Battery.qml" }

    Dots {
        anchors.fill: parent
        running: root.visible && !(cover.item && cover.item.covered) && !(power.item && power.item.onBattery)
        fps: Math.max(10, Math.min(60, root.cfg.Fps))
        speed: root.cfg.Speed / 100
        gain: 2.1 * root.cfg.Brightness / 100
        accent: scheme.accent
        hotColor: root.mix(root.mix(scheme.accent, "white", 0.38), root.mix(scheme.accent, "black", 0.3), root.mode)
        background: root.mix("#090909", "#ededed", root.mode)
        lightness: root.mode
        pattern: root.cfg.Pattern === "swirl" ? "swirl" : "blackhole"
    }
}
