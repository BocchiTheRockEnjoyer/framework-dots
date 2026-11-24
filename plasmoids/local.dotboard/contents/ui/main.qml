import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root

    // Boards follow the colour scheme: light text on dark, dark on light
    Item { id: scheme; Kirigami.Theme.inherit: false; Kirigami.Theme.colorSet: Kirigami.Theme.Window
        readonly property color bg: Kirigami.Theme.backgroundColor
        readonly property bool dark: 0.299 * bg.r + 0.587 * bg.g + 0.114 * bg.b < 0.5 }
    readonly property bool dark: scheme.dark
    readonly property color ink: dark ? "#f6f6f6" : "#1c1c1c"
    readonly property color dim: dark ? "#9a9a9a" : "#6a6a6a"
    readonly property color edge: dark ? "#4a4a4a" : "#b8b8b8"
    readonly property color gridInk: dark ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(0, 0, 0, 0.09)
    function boardColor(o) { return dark ? Qt.rgba(0.047, 0.047, 0.047, o) : Qt.rgba(0.95, 0.95, 0.95, Math.min(1, o + 0.12)) }
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    readonly property int cols: 64
    readonly property int rows: 31
    readonly property bool use24: Plasmoid.configuration.use24
    readonly property bool secs: Plasmoid.configuration.seconds
    onUse24Changed: tick()
    onSecsChanged: tick()

    // Dot states: 0 off, 1 white, 2 orange, 3 dim white
    property var target: []
    property var shown: []      // brightness currently displayed, 0..1
    property var tint: []       // last lit state, so fading dots keep their colour
    property var changed: []    // indexes to redraw; empty = everything
    signal repaint()

    readonly property var big: [
        [".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."], ["..#..", ".##..", "..#..", "..#..", "..#..", "..#..", ".###."],
        [".###.", "#...#", "....#", "...#.", "..#..", ".#...", "#####"], [".###.", "#...#", "....#", "..##.", "....#", "#...#", ".###."],
        ["...#.", "..##.", ".#.#.", "#..#.", "#####", "...#.", "...#."], ["#####", "#....", "####.", "....#", "....#", "#...#", ".###."],
        [".###.", "#....", "#....", "####.", "#...#", "#...#", ".###."], ["#####", "....#", "...#.", "..#..", "..#..", "..#..", "..#.."],
        [".###.", "#...#", "#...#", ".###.", "#...#", "#...#", ".###."], [".###.", "#...#", "#...#", ".####", "....#", "....#", ".###."]]
    // 3x5 letters, one string of five 3-dot rows each
    readonly property var small: ({
        A: ".#.#.#####.##.#", B: "##.#.###.#.###.", C: ".###..#..#...##", D: "##.#.##.##.###.", E: "####..##.#..###", F: "####..##.#..#..",
        G: ".###..#.##.#.##", H: "#.##.#####.##.#", I: "###.#..#..#.###", J: "..#..#..##.#.#.", L: "#..#..#..#..###", M: "#.########.##.#", N: "####.##.##.##.#",
        O: ".#.#.##.##.#.#.", P: "##.#.###.#..#..", R: "##.#.###.#.##.#", S: ".###...#...###.", T: "###.#..#..#..#.", U: "#.##.##.##.####", V: "#.##.##.##.#.#.",
        W: "#.##.########.#", Y: "#.##.#.#..#..#.", "0": "####.##.##.####", "1": ".#.##..#..#.###", "2": "##...#.#.#..###", "3": "##...#.#...###.",
        "4": "#.##.####..#..#", "5": "####..##...###.", "6": ".###..####.####", "7": "###..#.#..#..#.", "8": "####.#####.####", "9": "####.####..###.", " ": "..............." })

    function tick() {
        var t = new Array(cols * rows).fill(0), d = new Date()
        function put(x, y, s) { if (x >= 0 && y >= 0 && x < cols && y < rows) t[y * cols + x] = s }
        function word(str, x, y, s) {
            for (var i = 0; i < str.length; i++) { var g = small[str[i]]; if (g) for (var k = 0; k < 15; k++) if (g[k] === "#") put(x + i * 4 + k % 3, y + Math.floor(k / 3), s) }
        }
        var en = Qt.locale("en_US")
        word(d.toLocaleDateString(en, "ddd d MMM").toUpperCase(), 3, 2, 1)
        if (!use24) word(d.getHours() < 12 ? "AM" : "PM", cols - 10, 2, 2)
        var h = use24 ? d.getHours() : (d.getHours() % 12 || 12), m = d.getMinutes()
        var hs = use24 ? String(h).padStart(2, "0") : String(h), ms = String(m).padStart(2, "0"), w = hs.length * 12 + 4 + 24 - 2 + 2, x = Math.round((cols - w) / 2), y0 = 10
        function digit(n) { var g = big[n]; for (var r = 0; r < 7; r++) for (var c = 0; c < 5; c++) if (g[r][c] === "#") for (var q = 0; q < 4; q++) put(x + c * 2 + q % 2, y0 + r * 2 + (q >> 1), 1); x += 12 }
        for (var a = 0; a < hs.length; a++) digit(Number(hs[a]))
        if (!secs || d.getSeconds() % 2 === 0) for (var q = 0; q < 4; q++) { put(x + q % 2, y0 + 4 + (q >> 1), 2); put(x + q % 2, y0 + 8 + (q >> 1), 2) }
        x += 4
        for (var b = 0; b < 2; b++) digit(Number(ms[b]))
        if (secs) { var sec = d.getSeconds(); for (var i = 0; i < 60; i++) put(2 + i, 28, i === sec ? 2 : i < sec ? 1 : 0) }
        target = t
        if (shown.length !== t.length) { shown = t.map(v => v ? 1 : 0); tint = t.slice(); repaint() } else fade.start()
    }
    function step() {
        var busy = false, ch = []
        for (var i = 0; i < target.length; i++) {
            var goal = target[i] ? 1 : 0
            if (target[i] && tint[i] !== target[i]) { tint[i] = target[i]; ch.push(i) }
            if (shown[i] !== goal) { ch.push(i); shown[i] += goal > shown[i] ? 0.5 : -0.5; if (shown[i] !== goal) busy = true }
        }
        changed = changed.concat(ch)
        if (ch.length) repaint()
        if (!busy) fade.stop()
    }
    Timer { id: fade; interval: 60; repeat: true; onTriggered: root.step() }
    // Re-aligns to the start of each second (or minute when the track is off)
    Timer {
        id: clock
        running: true; repeat: false; interval: 10
        onTriggered: { root.tick(); var n = new Date(); interval = (root.secs ? 1000 : (60 - n.getSeconds()) * 1000) - n.getMilliseconds() + 5; start() }
    }

    fullRepresentation: Item {
        id: full
        Layout.preferredWidth: 416
        Layout.preferredHeight: 208
        Layout.minimumWidth: 200
        Layout.minimumHeight: 100
        readonly property real pitch: Math.min(width / root.cols, height / root.rows)
        Rectangle {
            id: board
            anchors.centerIn: parent
            width: full.pitch * root.cols; height: full.pitch * root.rows
            radius: full.pitch * 2.2
            border.width: 1.5; border.color: root.edge
            color: root.boardColor(Plasmoid.configuration.backOpacity / 100)
            Canvas {
                id: grid
                Connections { target: root; function onDarkChanged() { grid.requestPaint() } }
                anchors.fill: parent
                visible: Plasmoid.configuration.grid
                onPaint: {
                    var c = getContext("2d"), p = full.pitch; c.reset(); c.fillStyle = root.gridInk
                    for (var y = 1; y < root.rows - 1; y++) for (var x = 1; x < root.cols - 1; x++) { c.beginPath(); c.arc((x + 0.5) * p, (y + 0.5) * p, p * 0.38, 0, 6.2832); c.fill() }
                }
                onWidthChanged: requestPaint()
            }
            Canvas {
                id: lit
                anchors.fill: parent
                property bool needAll: true
                function dot(c, i, p) {
                    var v = root.shown[i]; if (v <= 0) return
                    c.globalAlpha = v; c.fillStyle = root.tint[i] === 2 ? "#f3531a" : root.ink
                    c.beginPath(); c.arc((i % root.cols + 0.5) * p, (Math.floor(i / root.cols) + 0.5) * p, p * 0.42, 0, 6.2832); c.fill()
                }
                onPaint: {
                    var c = getContext("2d"), p = width / root.cols
                    if (lit.needAll) { c.reset(); for (var i = 0; i < root.shown.length; i++) dot(c, i, p); lit.needAll = root.shown.length === 0; root.changed = []; return }
                    for (var k = 0; k < root.changed.length; k++) {
                        var j = root.changed[k], x = j % root.cols, y = Math.floor(j / root.cols)
                        c.clearRect(x * p, y * p, p, p); dot(c, j, p)
                    }
                    root.changed = []
                }
                onAvailableChanged: lit.needAll = true
                onWidthChanged: { lit.needAll = true; requestPaint() }
                onVisibleChanged: { lit.needAll = true; requestPaint() }
                Connections { target: root; function onDarkChanged() { lit.needAll = true; lit.requestPaint() } }
                Connections { target: root; function onRepaint() { if (root.changed.length === 0) lit.needAll = true; lit.requestPaint() } }
            }
        }
    }
}
