import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    // KDE underlines the whole tray while its hidden-icons popup is open; underline just the arrow
    property Item trayLine: null
    property Item trayArrow: null
    function findItem(item, test) {
        if (!item) return null
        if (test(item)) return item
        for (var i = 0; i < item.children.length; i++) { var r = findItem(item.children[i], test); if (r) return r }
        return null
    }
    function fixTrayLine() {
        if (trayLine && trayArrow && trayArrow.visible && trayLine.highlightedItem && trayLine.highlightedItem === trayLine.parent)
            trayLine.changeHighlightedItem(trayArrow, true)
    }
    Timer {
        property int tries: 0
        interval: 2000; repeat: true; running: !root.trayLine && tries < 30
        onTriggered: {
            tries++
            var w = root.Window.window; if (!w) return
            var line = root.findItem(w.contentItem, i => typeof i.changeHighlightedItem === "function" && i.highlightedItem !== undefined)
            if (!line) return
            var arrow = root.findItem(line.parent, i => i.arrowAnimationDuration !== undefined)
            if (arrow) { root.trayArrow = arrow; root.trayLine = line; root.fixTrayLine() }
        }
    }
    Connections { target: root.trayLine; function onHighlightedItemChanged() { root.fixTrayLine() } }
    readonly property var bat: source.data["Battery"]
    readonly property bool present: !!bat && bat["Has Battery"] !== false && bat["Percent"] !== undefined
    readonly property int percent: present ? bat["Percent"] : 0
    readonly property bool charging: !!source.data["AC Adapter"] && source.data["AC Adapter"]["Plugged in"] === true
    readonly property bool low: percent <= 20 && !charging

    // 5x7 dot digits
    readonly property var digits: [
        [".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
        ["..#..", ".##..", "..#..", "..#..", "..#..", "..#..", ".###."],
        [".###.", "#...#", "....#", "...#.", "..#..", ".#...", "#####"],
        [".###.", "#...#", "....#", "..##.", "....#", "#...#", ".###."],
        ["...#.", "..##.", ".#.#.", "#..#.", "#####", "...#.", "...#."],
        ["#####", "#....", "####.", "....#", "....#", "#...#", ".###."],
        [".###.", "#....", "#....", "####.", "#...#", "#...#", ".###."],
        ["#####", "....#", "...#.", "..#..", "..#..", "..#..", "..#.."],
        [".###.", "#...#", "#...#", ".###.", "#...#", "#...#", ".###."],
        [".###.", "#...#", "#...#", ".####", "....#", "....#", ".###."]
    ]
    readonly property string text: String(percent)
    readonly property int bodyCols: text.length * 6 - 1 + 6   // digits + gaps + padding and outline
    readonly property real pitch: 2

    // Outline dots light up left to right with the charge; digits stay bright.
    function buildDots() {
        var out = [], n = bodyCols
        function outline(x, y) { out.push({ x: x, y: y, k: (x + 0.5) / n * 100 <= percent || x === 0 ? "on" : "dim" }) }
        for (var x = 1; x < n - 1; x++) { outline(x, 0); outline(x, 10) }
        for (var y = 1; y < 10; y++) { outline(0, y); outline(n - 1, y) }
        for (var t = 4; t <= 6; t++) out.push({ x: n, y: t, k: charging ? "red" : (percent >= 99 ? "on" : "dim") })
        for (var i = 0; i < text.length; i++) {
            var g = digits[Number(text[i])]
            for (var r = 0; r < 7; r++)
                for (var c = 0; c < 5; c++)
                    if (g[r][c] === "#") out.push({ x: 3 + i * 6 + c, y: 2 + r, k: low ? "red" : "on" })
        }
        return out
    }
    readonly property var dots: present ? buildDots() : []

    preferredRepresentation: fullRepresentation
    Plasmoid.status: present ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.HiddenStatus
    toolTipMainText: i18n("Battery: %1%", percent)
    toolTipSubText: charging ? i18n("Plugged in") : i18n("On battery")

    P5Support.DataSource {
        id: source
        engine: "powermanagement"
        connectedSources: ["Battery", "AC Adapter"]
    }

    fullRepresentation: Item {
        Layout.minimumWidth: grid.width + Kirigami.Units.smallSpacing * 2
        Layout.preferredWidth: Layout.minimumWidth
        Layout.maximumWidth: Layout.minimumWidth
        Layout.fillHeight: true
        Item {
            id: grid
            anchors.centerIn: parent
            width: (root.bodyCols + 1) * root.pitch
            height: 11 * root.pitch
            Repeater {
                model: root.dots
                Rectangle {
                    required property var modelData
                    x: modelData.x * root.pitch + (root.pitch - width) / 2
                    y: modelData.y * root.pitch + (root.pitch - height) / 2
                    width: 1.7; height: 1.7; radius: 0.85
                    antialiasing: true
                    color: modelData.k === "red" ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                    opacity: modelData.k === "dim" ? 0.3 : 1
                }
            }
        }
    }
}
