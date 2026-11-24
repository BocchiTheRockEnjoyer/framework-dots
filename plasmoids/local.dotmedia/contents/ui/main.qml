import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.private.mpris as Mpris

PlasmoidItem {
    id: root
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
        property color tint: "#f6f6f6"
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
                color: gl.containsMouse ? "#f3531a" : gl.tint
            }
        }
    }

    component Marquee: Item {
        id: mq
        property alias text: t.text
        property alias font: t.font
        property alias color: t.color
        clip: true
        implicitHeight: t.implicitHeight
        Text { id: t; textFormat: Text.PlainText; x: 0
            onTextChanged: { scroll.stop(); x = 0; if (scroll.need) scroll.start() } }
        SequentialAnimation {
            id: scroll
            readonly property bool need: t.implicitWidth > mq.width && root.playing
            onNeedChanged: if (need) restart(); else { stop(); t.x = 0 }
            loops: Animation.Infinite
            PauseAnimation { duration: 2500 }
            NumberAnimation { target: t; property: "x"; to: mq.width - t.implicitWidth; duration: Math.max(1, t.implicitWidth - mq.width) * 25 }
            PauseAnimation { duration: 2500 }
            NumberAnimation { target: t; property: "x"; to: 0; duration: 400 }
        }
    }

    fullRepresentation: Item {
        id: view
        Layout.preferredWidth: 464
        Layout.preferredHeight: 208
        Layout.minimumWidth: 240
        Layout.minimumHeight: 116
        readonly property real p: Math.min(width / root.cols, height / root.rows)

        // Cover sampled at 3x3 pixels per dot, hidden behind the board
        Image { id: img; source: root.art; asynchronous: true; visible: false; sourceSize.width: 240; onStatusChanged: if (status === Image.Ready) probe.fetch(); else if (root.art === "") { probe.px = []; cover.requestPaint() } }
        Canvas {
            id: probe
            readonly property int n: root.dense
            property var px: []
            property string held: ""
            width: n * 3; height: n * 3; opacity: 0.01
            renderTarget: Canvas.Image
            anchors.centerIn: board
            function fetch() {
                if (!available || img.status !== Image.Ready) return
                var u = root.art
                if (held && held !== u) unloadImage(held)
                held = u
                if (isImageLoaded(u)) requestPaint(); else loadImage(u)
            }
            onAvailableChanged: fetch()
            onImageLoaded: requestPaint()
            onPaint: {
                if (img.status !== Image.Ready || held === "" || !isImageLoaded(held)) return
                var c = getContext("2d"), w = img.implicitWidth, h = img.implicitHeight, S = n * 3
                // getImageData counts physical pixels on scaled screens: paint the right
                // half and see whether a point in it can be read back
                c.reset(); c.fillStyle = "#ffffff"; c.fillRect(S / 2, 0, S / 2, S)
                var physical = c.getImageData(Math.floor(S * 0.55), 4, 1, 1).data[3] === 0
                var D = physical ? S / Screen.devicePixelRatio : S, k = D / Math.min(w, h)
                c.reset(); c.drawImage(held, (D - w * k) / 2, (D - h * k) / 2, w * k, h * k)
                var d = c.getImageData(0, 0, S, S).data, o = []
                for (var i = 0; i < n * n; i++) {
                    var bx = (i % n) * 3, by = Math.floor(i / n) * 3, t = [0, 0, 0]
                    for (var y = 0; y < 3; y++) for (var x = 0; x < 3; x++) { var j = ((by + y) * S + bx + x) * 4; t[0] += d[j]; t[1] += d[j + 1]; t[2] += d[j + 2] }
                    o.push([t[0] / 9, t[1] / 9, t[2] / 9])
                }
                px = o; cover.opacity = 0; cover.requestPaint(); appear.restart()
            }
        }

        Rectangle {
            id: board
            anchors.centerIn: parent
            width: view.p * root.cols; height: view.p * root.rows
            radius: view.p * 2.2
            border.width: 1.5; border.color: "#4a4a4a"
            color: Qt.rgba(0.047, 0.047, 0.047, Plasmoid.configuration.backOpacity / 100)
            Canvas {
                id: grid
                anchors.fill: parent
                visible: Plasmoid.configuration.grid
                onWidthChanged: requestPaint()
                onPaint: {
                    var c = getContext("2d"), p = view.p; c.reset(); c.fillStyle = Qt.rgba(1, 1, 1, 0.07)
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
                Connections { target: root; function onColourChanged() { cover.requestPaint() } }
                onPaint: {
                    var c = getContext("2d"), n = root.dense, q = width / n, a = probe.px, cr = n * 0.07; c.reset()
                    if (a.length === n * n) {
                        var lo = 255, hi = 0, lum = a.map(v => { var l = 0.3 * v[0] + 0.59 * v[1] + 0.11 * v[2]; lo = Math.min(lo, l); hi = Math.max(hi, l); return l })
                        for (var i = 0; i < a.length; i++) {
                            var x = i % n, y = Math.floor(i / n)
                            var ex = Math.max(cr - x - 0.5, x + 0.5 - (n - cr), 0), ey = Math.max(cr - y - 0.5, y + 0.5 - (n - cr), 0)
                            if (ex * ex + ey * ey > cr * cr) continue       // rounded corners
                            var b = (lum[i] - lo) / Math.max(1, hi - lo)
                            c.fillStyle = root.colour ? Qt.rgba(a[i][0] / 255, a[i][1] / 255, a[i][2] / 255, 1) : Qt.rgba(0.96, 0.96, 0.96, 0.1 + 0.9 * b)
                            c.beginPath(); c.arc((x + 0.5) * q, (y + 0.5) * q, q * (root.colour ? 0.47 : 0.2 + 0.28 * b), 0, 6.2832); c.fill()
                        }
                    } else {
                        var p = view.p, note = ["....#######", "....#######", "....#.....#", "....#.....#", "....#.....#", "....#.....#", ".####..####", "#####.#####", "#####.#####", ".###...###."]
                        for (var gy = 0; gy < root.artN; gy++) for (var gx = 0; gx < root.artN; gx++) {
                            var on = gy >= 8 && gy < 18 && gx >= 8 && gx < 19 && note[gy - 8][gx - 8] === "#"
                            c.fillStyle = on ? "#f3531a" : Qt.rgba(1, 1, 1, 0.07); c.beginPath(); c.arc((gx + 0.5) * p, (gy + 0.5) * p, p * (on ? 0.42 : 0.38), 0, 6.2832); c.fill()
                        }
                    }
                }
            }
            Marquee { x: view.p * root.col0; y: view.p * 1.8; width: view.p * root.span; text: root.track || "Nothing playing"; color: root.track ? "#f6f6f6" : "#9a9a9a"; font.family: "Ndot55Caps"; font.pixelSize: view.p * 3.9 }
            Marquee { x: view.p * root.col0; y: view.p * 6.9; width: view.p * root.span; text: root.artist; color: "#9a9a9a"; font.family: "Space Mono"; font.pixelSize: view.p * 2.1 }
            Row {
                x: view.p * root.col0 - 6; y: view.p * 15.5 - height / 2
                spacing: view.p * 0.3
                Glyph { pitch: view.p * 0.6; enabled: root.player?.canGoPrevious ?? false; onClicked: root.player.Previous()
                    rows7: ["#.....#", "#...###", "#..####", "#.#####", "#..####", "#...###", "#.....#"] }
                Glyph { pitch: view.p * 0.6; enabled: root.track !== ""; tint: "#f3531a"; onClicked: root.player.PlayPause()
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
                                color: index === 5 - lv && root.playing ? "#f3531a" : "#f6f6f6"
                                opacity: index >= 5 - lv ? (root.playing ? 1 : 0.4) : 0.07
                            }
                        }
                    }
                }
            }
            Text { x: view.p * root.col0; y: view.p * 23.4 - height / 2; text: root.track ? root.fmt(root.pos) : ""; color: "#c8c8c8"; font.family: "Ndot55Caps"; font.pixelSize: view.p * 2.4 }
            Text { x: view.p * (root.cols - 2) - width; y: view.p * 23.4 - height / 2; text: root.length > 0 ? root.fmt(root.length) : ""; color: "#8a8a8a"; font.family: "Ndot55Caps"; font.pixelSize: view.p * 2.4 }
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
                        color: index === prog.lit - 1 ? "#f3531a" : "#f6f6f6"
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
