import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    readonly property color accent: Kirigami.Theme.highlightColor     // follows the colour scheme, no restart needed
    id: root

    // Boards follow the colour scheme: light text on dark, dark on light
    Item { id: scheme; Kirigami.Theme.inherit: false; Kirigami.Theme.colorSet: Kirigami.Theme.Window
        readonly property color bg: Kirigami.Theme.backgroundColor
        readonly property bool dark: 0.299 * bg.r + 0.587 * bg.g + 0.114 * bg.b < 0.5 }
    readonly property bool dark: scheme.dark
    readonly property color ink: dark ? "#f6f6f6" : "#1c1c1c"
    readonly property color edge: dark ? "#4a4a4a" : "#b8b8b8"
    readonly property color gridInk: dark ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(0, 0, 0, 0.09)
    function boardColor(o) { return dark ? Qt.rgba(0.047, 0.047, 0.047, o) : Qt.rgba(0.95, 0.95, 0.95, Math.min(1, o + 0.12)) }
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    readonly property int cols: 64
    readonly property int rows: 31
    readonly property string city: Plasmoid.configuration.city.trim()
    readonly property bool f: Plasmoid.configuration.fahrenheit
    readonly property bool animate: Plasmoid.configuration.animate

    // ---- data ----
    property var cur: null
    property var days: []
    property string place: ""
    property string err: ""
    property int req: 0
    property int tries: 0
    property double last: 0
    function get(url, cb) {
        var x = new XMLHttpRequest(), id = req
        x.onreadystatechange = function() {
            if (x.readyState !== XMLHttpRequest.DONE || id !== root.req) return
            if (x.status !== 200) return root.failed("NO SIGNAL")
            try { cb(JSON.parse(x.responseText)) } catch (e) { root.failed("NO SIGNAL") }
        }
        x.open("GET", url); x.send()
    }
    // Keeps showing the last weather when there's a hiccup, and tries again soon
    function failed(why) { err = why; tries++; last = Date.now() - 1800000 + Math.min(600000, 30000 * tries); draw() }
    function refresh() {
        req++; err = ""; last = Date.now()
        if (!city) { cur = null; days = []; draw(); return }
        get("https://geocoding-api.open-meteo.com/v1/search?count=1&name=" + encodeURIComponent(city), g => {
            if (!g.results || !g.results.length) { root.cur = null; root.err = "CITY NOT FOUND"; root.draw(); return }
            var p = g.results[0]
            get("https://api.open-meteo.com/v1/forecast?latitude=" + p.latitude + "&longitude=" + p.longitude + "&current=temperature_2m,weather_code,is_day&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max&forecast_days=5&timezone=auto&temperature_unit=" + (root.f ? "fahrenheit" : "celsius"), w => {
                root.place = p.name; root.tries = 0
                root.cur = { t: w.current.temperature_2m, c: w.current.weather_code, d: w.current.is_day }
                root.days = w.daily.time.map((t, i) => ({ d: t, c: w.daily.weather_code[i], hi: w.daily.temperature_2m_max[i], lo: w.daily.temperature_2m_min[i], p: w.daily.precipitation_probability_max[i] || 0 }))
                root.draw()
            })
        })
    }
    function newPlace() { cur = null; days = []; tries = 0; refresh() }
    onCityChanged: newPlace()
    onFChanged: newPlace()
    Component.onCompleted: refresh()
    // Checks the clock rather than counting, so it catches up after sleep
    Timer { interval: 15000; repeat: true; running: root.city !== ""; onTriggered: if (Date.now() - root.last >= 1800000 || Date.now() < root.last) root.refresh() }

    // ---- drawing ----
    property bool week: false
    property int frame: 0
    property var target: []     // 0 off, 1 ink, 2 accent, 3 dim
    property var changed: []
    signal repaint(bool all)

    readonly property var big: [
        [".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."], ["..#..", ".##..", "..#..", "..#..", "..#..", "..#..", ".###."],
        [".###.", "#...#", "....#", "...#.", "..#..", ".#...", "#####"], [".###.", "#...#", "....#", "..##.", "....#", "#...#", ".###."],
        ["...#.", "..##.", ".#.#.", "#..#.", "#####", "...#.", "...#."], ["#####", "#....", "####.", "....#", "....#", "#...#", ".###."],
        [".###.", "#....", "#....", "####.", "#...#", "#...#", ".###."], ["#####", "....#", "...#.", "..#..", "..#..", "..#..", "..#.."],
        [".###.", "#...#", "#...#", ".###.", "#...#", "#...#", ".###."], [".###.", "#...#", "#...#", ".####", "....#", "....#", ".###."]]
    // 3x5 letters, one string of five 3-dot rows each
    readonly property var small: ({
        A: ".#.#.#####.##.#", B: "##.#.###.#.###.", C: ".###..#..#...##", D: "##.#.##.##.###.", E: "####..##.#..###", F: "####..##.#..#..",
        G: ".###..#.##.#.##", H: "#.##.#####.##.#", I: "###.#..#..#.###", J: "..#..#..##.#.#.", K: "#.##.###.#.##.#", L: "#..#..#..#..###", M: "#.########.##.#", N: "####.##.##.##.#",
        O: ".#.#.##.##.#.#.", P: "##.#.###.#..#..", Q: ".#.#.##.##.#.##", R: "##.#.###.#.##.#", S: ".###...#...###.", T: "###.#..#..#..#.", U: "#.##.##.##.####", V: "#.##.##.##.#.#.",
        W: "#.##.########.#", X: "#.##.#.#.#.##.#", Y: "#.##.#.#..#..#.", Z: "###..#.#.#..###", "0": "####.##.##.####", "1": ".#.##..#..#.###", "2": "##...#.#.#..###", "3": "##...#.#...###.",
        "4": "#.##.####..#..#", "5": "####..##...###.", "6": ".###..####.####", "7": "###..#.#..#..#.", "8": "####.#####.####", "9": "####.####..###.",
        "-": "......###......", ".": ".............#.", "'": ".#..#..........", "%": "#.#..#.#.#..#.#", "/": "..#..#.#.#..#..", " ": "..............." })
    // 11x11. A letter is a part that moves: o accent, a b c rain or snow dots by turn, x flash
    readonly property var pics: ({
        sun: [".....o.....", ".o.......o.", "...........", "....ooo....", "...ooooo...", "o..ooooo..o", "...ooooo...", "....ooo....", "...........", ".o.......o.", ".....o....."],
        moon: ["....###....", "..##.......", ".##........", ".##........", "##.........", "##.........", "##........#", ".##......#.", ".###...##..", "..#######..", "....###...."],
        partly: ["......o....", "...o.....o.", ".....ooo...", "....ooooo..", "..###oooo.o", ".#...#ooo..", "#.....##...", "#.......#..", ".#######...", "...........", "..........."],
        cloud: ["...........", "...........", "....###....", "..##...#...", ".#......##.", "#.........#", "#.........#", ".#########.", "...........", "...........", "..........."],
        rain: ["....###....", "..##...#...", ".#......##.", "#.........#", "#.........#", ".#########.", "...........", "..a..b..c..", "..b..c..a..", "..c..a..b..", "..a..b..c.."],
        snow: ["....###....", "..##...#...", ".#......##.", "#.........#", "#.........#", ".#########.", "...........", ".a..b..c..a", "...c..a..b.", ".b..c..a..b", "...a..b..c."],
        fog: ["...........", ".#########.", "...........", "#######....", "...........", "..#########", "...........", "########...", "...........", "...#######.", "..........."],
        storm: ["....###....", "..##...#...", ".#......##.", "#.........#", "#.........#", ".#########.", ".....xx....", "....xx.....", "...xxxxx...", ".....xx....", "....xx....."] })
    function kind(c, day) { return c <= 1 ? (day === 0 ? "moon" : "sun") : c === 2 ? (day === 0 ? "cloud" : "partly") : c === 3 ? "cloud" : c <= 48 ? "fog" : c >= 95 ? "storm" : (c >= 71 && c <= 77) || c === 85 || c === 86 ? "snow" : "rain" }
    function words(c) { return c === 0 ? "CLEAR" : c === 1 ? "FAIR" : c === 2 ? "CLOUDY" : c === 3 ? "OVERCAST" : c <= 48 ? "FOG" : c <= 57 ? "DRIZZLE" : c <= 67 ? "RAIN" : c <= 77 ? "SNOW" : c <= 82 ? "SHOWERS" : c <= 86 ? "SNOW" : "STORM" }
    function plain(s) { return String(s).normalize("NFD").replace(/[̀-ͯ]/g, "").toUpperCase() }

    function draw() {
        var t = new Array(cols * rows).fill(0), fr = frame, move = animate
        function put(x, y, s) { if (x >= 0 && y >= 0 && x < cols && y < rows) t[y * cols + x] = s }
        function word(str, x, y, s) { for (var i = 0; i < str.length; i++) { var g = small[str[i]]; if (g) for (var k = 0; k < 15; k++) if (g[k] === "#") put(x + i * 4 + k % 3, y + Math.floor(k / 3), s) } }
        function wide(str) { return str.length * 4 - 1 }
        function pic(name, x, y, z, quiet) {
            var g = pics[name], turn = move && !quiet ? fr % 3 : 0
            for (var r = 0; r < 11; r++) for (var c = 0; c < 11; c++) {
                var v = g[r][c], s = 0
                if (v === "#") s = 1
                else if (v === "o") { s = 2; if (name !== "partly" && move && !quiet && (r === 0 || r === 10 || c === 0 || c === 10 || ((r === 1 || r === 9) && (c === 1 || c === 9)))) s = (fr >> 2) % 2 === ((r + c) % 10 === 5 ? 0 : 1) ? 2 : 3 }
                else if (v === "x") s = move && !quiet ? (fr % 14 === 0 || fr % 14 === 2 ? 1 : 2) : 2
                else if (v === "a" || v === "b" || v === "c") s = "abc".indexOf(v) === (name === "snow" ? (fr >> 1) % 3 : turn) && move && !quiet ? 2 : 3
                if (v === "a" || v === "b" || v === "c") { put(x + c * z, y + r * z, s); if (z > 1 && name === "rain") put(x + c * z, y + r * z + 1, s); continue }
                if (s) for (var q = 0; q < z * z; q++) put(x + c * z + q % z, y + r * z + Math.floor(q / z), s)
            }
        }
        function centre(str, y, s) { word(str, Math.round((cols - wide(str)) / 2), y, s) }
        if (!cur) {
            if (!city) { pic("partly", 26, 4, 1); centre("SET YOUR CITY", 19, 1); centre("RIGHT-CLICK", 25, 3) }
            else { pic(err ? "cloud" : "sun", 26, 5, 1); centre(err || "LOADING", 21, err ? 2 : 3) }
        } else if (week && days.length) {
            for (var i = 0; i < Math.min(5, days.length); i++) {
                var d = days[i], x = 2 + Math.round(i * 12.25), nm = new Date(d.d + "T12:00:00").toLocaleDateString(Qt.locale("en_US"), "ddd").slice(0, 2).toUpperCase()
                word(nm, x + 2, 2, i === 0 ? 2 : 1)
                pic(kind(d.c, 1), x, 8, 1, true)
                var hi = String(Math.round(d.hi)); word(hi, x + Math.max(0, Math.round((11 - wide(hi)) / 2)), 21, 1)
                for (var b = 0; b < 11; b++) put(x + b, 28, b < Math.round(d.p / 100 * 11) ? 2 : 3)
            }
        } else {
            // A long name takes the whole line; the picture already says what the weather is
            var nm2 = plain(place).slice(0, 15).trim(), cond = words(cur.c)
            word(nm2, 3, 2, 1)
            if (wide(nm2) + wide(cond) + 9 <= cols) word(cond, cols - 3 - wide(cond), 2, 2)
            pic(kind(cur.c, cur.d), 2, 8, 2)
            var s = String(Math.abs(Math.round(cur.t))), neg = Math.round(cur.t) < 0, step = s.length > 2 ? 11 : 12
            var tw = s.length * step - 2 + 4 + (neg ? 6 : 0), tx = 27 + Math.max(0, Math.round((36 - tw) / 2))
            if (neg) { for (var n = 0; n < 8; n++) put(tx + n % 4, 15 + (n >> 2), 1); tx += 6 }
            for (var a = 0; a < s.length; a++) { var g = big[Number(s[a])]; for (var r = 0; r < 7; r++) for (var c = 0; c < 5; c++) if (g[r][c] === "#") for (var q = 0; q < 4; q++) put(tx + c * 2 + q % 2, 9 + r * 2 + (q >> 1), 1); tx += step }
            for (var u = 0; u < 4; u++) put(tx + u % 2, 9 + (u >> 1), 2)
            var td = days[0]
            if (td) {
                var hl = Math.round(td.hi) + "/" + Math.round(td.lo), pr = Math.round(td.p) + "%", gap = wide(hl) > 19 ? 3 : 5, total = wide(hl) + gap + wide(pr), bx = Math.min(27 + Math.max(0, Math.round((36 - total) / 2)), cols - 2 - total)
                word(hl, bx, 25, 3); word(pr, bx + wide(hl) + gap, 25, td.p >= 50 ? 2 : 3)
            }
            if (err) put(cols - 3, rows - 3, 2)      // last update failed
        }
        var ch = []
        if (target.length !== t.length) { target = t; repaint(true); return }
        for (var i2 = 0; i2 < t.length; i2++) if (t[i2] !== target[i2]) ch.push(i2)
        if (!ch.length) return
        target = t; changed = changed.concat(ch); repaint(false)
    }
    readonly property bool moving: animate && !!cur && !week && ["sun", "rain", "snow", "storm"].indexOf(kind(cur.c, cur.d)) >= 0
    Timer { interval: 260; repeat: true; running: root.moving; onTriggered: { root.frame = (root.frame + 1) % 840; root.draw() } }
    onWeekChanged: draw()
    onAnimateChanged: draw()

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
            Accessible.role: Accessible.StaticText
            Accessible.name: root.cur ? root.place + ", " + Math.round(root.cur.t) + " degrees, " + root.words(root.cur.c).toLowerCase() : "Weather"
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
                Connections { target: root; function onAccentChanged() { lit.needAll = true; lit.requestPaint() } }
                function dot(c, i, p) {
                    var s = root.target[i]; if (!s) return
                    c.globalAlpha = s === 3 ? 0.42 : 1; c.fillStyle = s === 2 ? root.accent : root.ink
                    c.beginPath(); c.arc((i % root.cols + 0.5) * p, (Math.floor(i / root.cols) + 0.5) * p, p * 0.42, 0, 6.2832); c.fill()
                }
                onPaint: {
                    var c = getContext("2d"), p = width / root.cols
                    if (lit.needAll) { c.reset(); for (var i = 0; i < root.target.length; i++) dot(c, i, p); lit.needAll = root.target.length === 0; root.changed = []; return }
                    for (var k = 0; k < root.changed.length; k++) { var j = root.changed[k]; c.clearRect(j % root.cols * p, Math.floor(j / root.cols) * p, p, p); dot(c, j, p) }
                    root.changed = []
                }
                onAvailableChanged: lit.needAll = true
                onWidthChanged: { lit.needAll = true; requestPaint() }
                onVisibleChanged: { lit.needAll = true; requestPaint() }
                Connections { target: root; function onDarkChanged() { lit.needAll = true; lit.requestPaint() } function onRepaint(all) { if (all) lit.needAll = true; lit.requestPaint() } }
            }
            TapHandler { acceptedButtons: Qt.LeftButton; onTapped: if (root.cur) root.week = !root.week }
        }
    }
}
