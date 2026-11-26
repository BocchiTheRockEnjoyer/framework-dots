import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.private.mpris as Mpris

PlasmoidItem {
    readonly property color accent: Kirigami.Theme.highlightColor     // follows the colour scheme, no restart needed
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
    readonly property int cols: 71          // same grid as Dot Board Clock
    readonly property int art0: 2           // cover position and size, in cells
    readonly property int artN: 27
    readonly property int col0: art0 + artN + 3
    readonly property int span: cols - col0 - 2
    readonly property int dense: 68         // cover dots per side
    readonly property int rows: 31
    readonly property bool colour: Plasmoid.configuration.colour

    Mpris.Mpris2Model { id: mpris }
    readonly property var player: mpris.currentPlayer
    readonly property string track: player?.track ?? ""
    readonly property string artist: player?.artist ?? ""
    readonly property string art: String(player?.artUrl ?? "")
    readonly property bool playing: (player?.playbackStatus ?? 0) === Mpris.PlaybackStatus.Playing
    readonly property real length: player?.length ?? 0
    property real pos: 0
    property var levels: [1, 1, 1, 1, 1, 1, 1]
    function sync() { player?.updatePosition(); pos = player?.position ?? 0 }
    function fmt(us) { var s = Math.max(0, Math.floor(us / 1e6)), h = Math.floor(s / 3600), m = Math.floor(s / 60) % 60; return (h ? h + ":" + String(m).padStart(2, "0") : m) + ":" + String(s % 60).padStart(2, "0") }
    onTrackChanged: sync()
    Timer { interval: 1000; repeat: true; running: root.playing; triggeredOnStart: true; onTriggered: root.sync() }
    Timer {   // Decorative, not driven by the audio itself
        interval: 260; repeat: true; running: root.playing
        onTriggered: root.levels = root.levels.map(() => 1 + Math.floor(Math.random() * 5))
    }

    component Glyph: MouseArea {
        id: gl
        property var rows7: []
        property real pitch: 4
        property color tint: root.ink
        width: 7 * pitch + 12; height: 7 * pitch + 12
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        opacity: enabled ? 1 : 0.25
        Repeater {
            model: 49
            Rectangle {
                required property int index
                visible: gl.rows7.length === 7 && gl.rows7[Math.floor(index / 7)][index % 7] === "#"
                x: 6 + (index % 7) * gl.pitch; y: 6 + Math.floor(index / 7) * gl.pitch
                width: gl.pitch * 0.84; height: width; radius: width / 2
                color: gl.containsMouse ? Kirigami.Theme.highlightColor : gl.tint
            }
        }
    }

    // Long text is cut off with an ellipsis; hovering scrolls through the rest
    component Marquee: Item {
        id: mq
        property alias text: t.text
        property alias font: t.font
        property alias color: t.color
        readonly property bool need: t.implicitWidth > width + 1
        readonly property bool scrolling: need && hover.hovered
        clip: true
        implicitHeight: t.implicitHeight
        HoverHandler { id: hover }
        Text {
            id: t
            textFormat: Text.PlainText
            elide: Text.ElideRight
            width: mq.scrolling || back.running ? implicitWidth : mq.width
            onTextChanged: { back.stop(); x = 0; if (mq.scrolling) scroll.restart() }
        }
        onScrollingChanged: if (scrolling) { back.stop(); scroll.restart() } else { scroll.stop(); back.restart() }
        SequentialAnimation {
            id: scroll
            loops: Animation.Infinite
            PauseAnimation { duration: 300 }
            NumberAnimation { target: t; property: "x"; to: mq.width - t.implicitWidth; duration: Math.max(1, t.implicitWidth - mq.width) * 20 }
            PauseAnimation { duration: 1500 }
            NumberAnimation { target: t; property: "x"; to: 0; duration: 400 }
            PauseAnimation { duration: 700 }
        }
        NumberAnimation { id: back; target: t; property: "x"; to: 0; duration: 250 }
    }

    fullRepresentation: Item {
        id: view
        Layout.preferredWidth: 464
        Layout.preferredHeight: 208
        Layout.minimumWidth: 240
        Layout.minimumHeight: 116
        readonly property real p: Math.min(width / root.cols, height / root.rows)

        // Cover sampled at 3x3 pixels per dot, hidden behind the board
        Image { id: img; source: root.art; asynchronous: true; visible: false; sourceSize.width: 240; onStatusChanged: if (status === Image.Ready) probe.fetch(); else if (root.art === "") { probe.px = []; probe.done = ""; cover.requestPaint() } }
        Canvas {
            id: probe
            readonly property int n: root.dense
            property var px: []
            property string done: ""   // cover that px was read from
            width: n * 3; height: n * 3; opacity: 0.01
            renderTarget: Canvas.Image
            anchors.centerIn: board
            function fetch() { if (available && img.status === Image.Ready) requestPaint() }
            // Try again if the cover file wasn't ready yet, or a repaint got lost
            Timer {
                interval: 1000; repeat: true; running: root.art !== "" && probe.done !== root.art
                property int tries: 0
                property string last: ""
                onTriggered: {
                    if (last !== root.art) { last = root.art; tries = 0 }
                    if (++tries > 20) return
                    if (img.status === Image.Error) { img.source = ""; img.source = Qt.binding(() => root.art) }
                    else probe.fetch()
                }
            }
            onAvailableChanged: fetch()
            onPaint: {
                if (img.status !== Image.Ready || root.art === "") return
                var c = getContext("2d"), w = img.implicitWidth, h = img.implicitHeight, S = n * 3
                // getImageData counts physical pixels on scaled screens: paint the right
                // half and see whether a point in it can be read back
                c.reset(); c.fillStyle = "#ffffff"; c.fillRect(S / 2, 0, S / 2, S)
                var physical = c.getImageData(Math.floor(S * 0.55), 4, 1, 1).data[3] === 0
                var D = physical ? S / Screen.devicePixelRatio : S, k = D / Math.min(w, h)
                c.reset(); c.drawImage(img, (D - w * k) / 2, (D - h * k) / 2, w * k, h * k)
                var d = c.getImageData(0, 0, S, S).data, o = []
                for (var i = 0; i < n * n; i++) {
                    var bx = (i % n) * 3, by = Math.floor(i / n) * 3, t = [0, 0, 0]
                    for (var y = 0; y < 3; y++) for (var x = 0; x < 3; x++) { var j = ((by + y) * S + bx + x) * 4; t[0] += d[j]; t[1] += d[j + 1]; t[2] += d[j + 2] }
                    o.push([t[0] / 9, t[1] / 9, t[2] / 9])
                }
                if (d[(Math.floor(S / 2) * S + Math.floor(S / 2)) * 4 + 3] === 0) return      // nothing drawn yet
                px = o; done = root.art; cover.opacity = 0; cover.requestPaint(); appear.restart()
            }
        }

        Rectangle {
            id: board
            anchors.centerIn: parent
            width: view.p * root.cols; height: view.p * root.rows
            radius: view.p * 2.2
            border.width: 1.5; border.color: root.edge
            color: root.boardColor(Plasmoid.configuration.backOpacity / 100)
            Canvas {
                id: grid
                Connections { target: root; function onDarkChanged() { grid.requestPaint() } }
                anchors.fill: parent
                visible: Plasmoid.configuration.grid
                onWidthChanged: requestPaint()
                onPaint: {
                    var c = getContext("2d"), p = view.p; c.reset(); c.fillStyle = root.gridInk
                    for (var y = 1; y < root.rows - 1; y++) for (var x = 1; x < root.cols - 1; x++) {
                        if (x >= root.art0 && x < root.art0 + root.artN && y >= root.art0 && y < root.art0 + root.artN) continue
                        if (x >= root.col0 - 1 && x < root.cols - 1 && y >= 2 && y <= root.rows - 3) continue   // keep text and controls clear
                        c.beginPath(); c.arc((x + 0.5) * p, (y + 0.5) * p, p * 0.38, 0, 6.2832); c.fill()
                    }
                }
            }
            Canvas {
                id: cover
                x: view.p * root.art0; y: view.p * root.art0; width: view.p * root.artN; height: width
                onWidthChanged: requestPaint()
                NumberAnimation { id: appear; target: cover; property: "opacity"; to: 1; duration: 350 }
                Connections { target: root; function onColourChanged() { cover.requestPaint() } function onDarkChanged() { cover.requestPaint() } function onAccentChanged() { cover.requestPaint() } }
                onPaint: {
                    var c = getContext("2d"), n = root.dense, q = width / n, a = probe.px, cr = n * 0.07; c.reset()
                    if (a.length === n * n) {
                        var lo = 255, hi = 0, lum = a.map(v => { var l = 0.3 * v[0] + 0.59 * v[1] + 0.11 * v[2]; lo = Math.min(lo, l); hi = Math.max(hi, l); return l })
                        for (var i = 0; i < a.length; i++) {
                            var x = i % n, y = Math.floor(i / n)
                            var ex = Math.max(cr - x - 0.5, x + 0.5 - (n - cr), 0), ey = Math.max(cr - y - 0.5, y + 0.5 - (n - cr), 0)
                            if (ex * ex + ey * ey > cr * cr) continue       // rounded corners
                            var b = (lum[i] - lo) / Math.max(1, hi - lo)
                            c.fillStyle = root.colour ? Qt.rgba(a[i][0] / 255, a[i][1] / 255, a[i][2] / 255, 1) : Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.1 + 0.9 * (root.dark ? b : 1 - b))
                            c.beginPath(); c.arc((x + 0.5) * q, (y + 0.5) * q, q * (root.colour ? 0.47 : 0.2 + 0.28 * (root.dark ? b : 1 - b)), 0, 6.2832); c.fill()
                        }
                    } else {
                        var p = view.p, note = ["....#######", "....#######", "....#.....#", "....#.....#", "....#.....#", "....#.....#", ".####..####", "#####.#####", "#####.#####", ".###...###."]
                        for (var gy = 0; gy < root.artN; gy++) for (var gx = 0; gx < root.artN; gx++) {
                            var on = gy >= 8 && gy < 18 && gx >= 8 && gx < 19 && note[gy - 8][gx - 8] === "#"
                            c.fillStyle = on ? root.accent : root.gridInk; c.beginPath(); c.arc((gx + 0.5) * p, (gy + 0.5) * p, p * (on ? 0.42 : 0.38), 0, 6.2832); c.fill()
                        }
                    }
                }
            }
            Marquee { x: view.p * root.col0; y: view.p * 1.8; width: view.p * root.span; text: root.track || "Nothing playing"; color: root.track ? root.ink : root.dim; font.family: "FD Dots"; font.capitalization: Font.AllUppercase; font.pixelSize: view.p * 3.9 }
            Marquee { x: view.p * root.col0; y: view.p * 6.9; width: view.p * root.span; text: root.artist; color: root.dim; font.family: "Space Mono"; font.pixelSize: view.p * 2.1 }
            Row {
                x: view.p * root.col0 - 6; y: view.p * 15.5 - height / 2
                spacing: view.p * 0.3
                Glyph { pitch: view.p * 0.6; enabled: root.player?.canGoPrevious ?? false; onClicked: root.player.Previous()
                    rows7: ["#.....#", "#...###", "#..####", "#.#####", "#..####", "#...###", "#.....#"] }
                Glyph { pitch: view.p * 0.6; enabled: root.track !== ""; tint: Kirigami.Theme.highlightColor; onClicked: root.player.PlayPause()
                    rows7: root.playing ? ["##...##", "##...##", "##...##", "##...##", "##...##", "##...##", "##...##"] : ["##.....", "####...", "######.", "#######", "######.", "####...", "##....."] }
                Glyph { pitch: view.p * 0.6; enabled: root.player?.canGoNext ?? false; onClicked: root.player.Next()
                    rows7: ["#.....#", "###...#", "####..#", "#####.#", "####..#", "###...#", "#.....#"] }
            }
            Row {    // level meter
                x: view.p * (root.cols - 9); y: view.p * 13
                Repeater {
                    model: 7
                    Item {
                        id: bar
                        required property int index
                        width: view.p; height: view.p * 5
                        Repeater {
                            model: 5
                            Rectangle {
                                required property int index
                                readonly property int lv: root.playing ? root.levels[bar.index] : 1
                                x: view.p * 0.08; y: index * view.p + view.p * 0.08
                                width: view.p * 0.84; height: width; radius: width / 2
                                color: index === 5 - lv && root.playing ? Kirigami.Theme.highlightColor : root.ink
                                opacity: index >= 5 - lv ? (root.playing ? 1 : 0.4) : 0.07
                            }
                        }
                    }
                }
            }
            Text { x: view.p * root.col0; y: view.p * 23.4 - height / 2; text: root.track ? root.fmt(root.pos) : ""; color: root.dim; font.family: "FD Dots"; font.capitalization: Font.AllUppercase; font.pixelSize: view.p * 2.4 }
            Text { x: view.p * (root.cols - 2) - width; y: view.p * 23.4 - height / 2; text: root.length > 0 ? root.fmt(root.length) : ""; color: root.dim; font.family: "FD Dots"; font.capitalization: Font.AllUppercase; font.pixelSize: view.p * 2.4 }
            Item {    // progress, click to seek
                id: prog
                x: view.p * root.col0; y: view.p * 27; width: view.p * root.span; height: view.p
                readonly property int lit: root.length > 0 ? Math.max(1, Math.round(Math.min(1, root.pos / root.length) * root.span)) : 0
                Repeater {
                    model: root.span
                    Rectangle {
                        required property int index
                        x: index * view.p + view.p * 0.08; y: view.p * 0.08
                        width: view.p * 0.84; height: width; radius: width / 2
                        color: index === prog.lit - 1 ? Kirigami.Theme.highlightColor : root.ink
                        opacity: index < prog.lit ? 1 : 0.12
                    }
                }
                MouseArea {
                    anchors.fill: parent; anchors.margins: -5
                    enabled: (root.player?.canSeek ?? false) && root.length > 0
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: m => { var v = Math.max(0, Math.min(1, (m.x - 5) / (width - 10))) * root.length; root.player.position = v; root.pos = v }
                }
            }
        }
    }
}
