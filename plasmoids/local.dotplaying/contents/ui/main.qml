import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PC
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris
import QtQuick.Effects

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
    Mpris.Mpris2Model { id: mpris }
    readonly property var player: mpris.currentPlayer
    readonly property string track: player?.track ?? ""
    readonly property string artist: player?.artist ?? ""
    readonly property string art: String(player?.artUrl ?? "")
    readonly property bool playing: (player?.playbackStatus ?? 0) === Mpris.PlaybackStatus.Playing
    readonly property real length: player?.length ?? 0
    property real pos: 0
    property var levels: [1, 2, 1, 3, 2, 1, 2]
    Plasmoid.status: track !== "" ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.HiddenStatus
    toolTipMainText: track
    toolTipSubText: artist + (length > 0 ? "\n" + fmt(pos) + " / " + fmt(length) : "")
    readonly property string source: player?.identity ?? ""
    readonly property int shuffle: player?.shuffle ?? 0      // 0 unknown, 1 off, 2 on
    readonly property int loop: player?.loopStatus ?? 0      // 0 unknown, 1 none, 2 playlist, 3 track
    function fmt(us) { var s = Math.max(0, Math.floor(us / 1e6)), h = Math.floor(s / 3600), m = Math.floor(s / 60) % 60; return (h ? h + ":" + String(m).padStart(2, "0") : m) + ":" + String(s % 60).padStart(2, "0") }
    function seek(f) { if ((player?.canSeek ?? false) && length > 0) { pos = Math.max(0, Math.min(1, f)) * length; player.position = pos } }
    onTrackChanged: { player?.updatePosition(); pos = player?.position ?? 0 }
    Timer {
        // Decorative: not driven by the actual audio
        interval: 220; repeat: true; running: root.playing
        onTriggered: root.levels = root.levels.map(() => 1 + Math.floor(Math.random() * 5))
    }
    Timer {
        interval: root.expanded ? 1000 : 5000; repeat: true; running: root.track !== "" && (root.expanded || root.playing); triggeredOnStart: true
        onTriggered: { root.player?.updatePosition(); root.pos = root.player?.position ?? 0 }
    }

    component Art: Item {
        id: artItem
        property real radius: 8
        readonly property bool ready: img.status === Image.Ready
        readonly property real ratio: ready && img.implicitHeight > 0 ? img.implicitWidth / img.implicitHeight : 1
        Timer {
            id: barRetry
            property int tries: 0
            interval: 1000; repeat: true; running: img.status === Image.Error && root.art !== "" && tries < 20
            onTriggered: { tries++; img.source = ""; img.source = Qt.binding(() => root.art) }
        }
        Connections { target: root; function onArtChanged() { barRetry.tries = 0 } }
        Image {
            id: img
            anchors.fill: parent
            source: root.art
            asynchronous: true
            retainWhileLoading: true
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 640
            layer.enabled: true
            layer.effect: MultiEffect { maskEnabled: true; maskSource: mask; maskThresholdMin: 0.5; maskSpreadAtMin: 1.0 }
        }
        Item {
            id: mask
            anchors.fill: parent
            visible: false
            layer.enabled: true
            Rectangle { anchors.fill: parent; radius: artItem.radius }
        }
    }

    component Vis: Row {
        property real pitch: 4
        spacing: 0
        Repeater {
            model: 7
            Item {
                id: c
                required property int index
                width: pitch; height: pitch * 5
                Repeater {
                    model: 5
                    Rectangle {
                        required property int index
                        readonly property bool on: index >= 5 - (root.playing ? root.levels[c.index] : 1)
                        y: index * pitch; width: pitch * 0.8; height: width; radius: width / 2
                        color: on && root.playing && index === 5 - root.levels[c.index] ? "#f3531a" : Kirigami.Theme.textColor
                        opacity: on ? 1 : 0.18
                    }
                }
            }
        }
    }

    compactRepresentation: MouseArea {
        Layout.minimumWidth: row.implicitWidth + Kirigami.Units.smallSpacing * 2
        Layout.preferredWidth: Layout.minimumWidth
        Layout.maximumWidth: Layout.minimumWidth
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: m => { if (m.button === Qt.MiddleButton) root.player?.PlayPause(); else root.expanded = !root.expanded }
        Row {
            id: row
            visible: root.track !== ""
            anchors.centerIn: parent
            spacing: 8
            Art { id: thumb; visible: ready; width: 22; height: 22; radius: 4; anchors.verticalCenter: parent.verticalCenter }
            Item {    // level meter: slides in while playing, away when paused
                anchors.verticalCenter: parent.verticalCenter
                width: root.playing ? meter.width : 0
                height: meter.height
                visible: width > 0.5
                clip: true
                opacity: root.playing ? 1 : 0
                Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 200 } }
                Vis { id: meter }
            }
            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(title.implicitWidth, 170); height: 26
                Item {
                    width: parent.width; height: title.implicitHeight
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: root.length > 0 ? -3 : 0
                    clip: true
                    Text {
                        id: title
                        text: root.track; textFormat: Text.PlainText
                        font: Kirigami.Theme.defaultFont; color: Kirigami.Theme.textColor
                        onTextChanged: { slide.stop(); x = 0; slide.need ? slide.restart() : 0 }
                        SequentialAnimation {
                            id: slide
                            readonly property bool need: title.implicitWidth > 171 && root.playing
                            onNeedChanged: if (need) restart(); else { stop(); title.x = 0 }
                            loops: Animation.Infinite
                            PauseAnimation { duration: 4000 }
                            NumberAnimation { target: title; property: "x"; to: 170 - title.implicitWidth; duration: Math.max(1, title.implicitWidth - 170) * 30 }
                            PauseAnimation { duration: 3000 }
                            NumberAnimation { target: title; property: "x"; to: 0; duration: 500 }
                        }
                    }
                }
                Row {    // progress
                    id: line
                    visible: root.length > 0
                    anchors.bottom: parent.bottom
                    readonly property int n: Math.max(4, Math.floor(parent.width / 5))
                    readonly property int lit: Math.round(Math.min(1, root.pos / Math.max(1, root.length)) * n)
                    Repeater {
                        model: line.n
                        Item {
                            required property int index
                            width: 5; height: 3
                            Rectangle { width: 3; height: 3; radius: 1.5; color: index === line.lit - 1 ? "#f3531a" : Kirigami.Theme.textColor; opacity: index < line.lit ? 0.9 : 0.18 }
                        }
                    }
                }
            }
        }
        onWheel: w => root.player?.changeVolume(w.angleDelta.y > 0 ? 0.05 : -0.05, true)
    }

    component Glyph: MouseArea {
        id: gl
        property var rows9: []
        property real pitch: 3
        property color tint: Kirigami.Theme.textColor
        readonly property int n: rows9.length
        width: n * pitch + 14; height: n * pitch + 14
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        opacity: enabled ? 1 : 0.25
        Repeater {
            model: gl.n * gl.n
            Rectangle {
                required property int index
                visible: gl.n > 0 && gl.rows9[Math.floor(index / gl.n)][index % gl.n] === "#"
                x: 7 + (index % gl.n) * gl.pitch; y: 7 + Math.floor(index / gl.n) * gl.pitch
                width: gl.pitch * 0.84; height: width; radius: width / 2
                color: gl.containsMouse ? "#f3531a" : gl.tint
            }
        }
    }
    component Dots: Item {    // clickable row of dots
        id: dts
        property real value: 0
        property int cols: 33
        signal picked(real f)
        signal scrolled(int dir)
        readonly property int lit: value <= 0 ? 0 : Math.max(1, Math.round(Math.min(1, value) * cols))
        implicitWidth: cols * 8; implicitHeight: 14
        Repeater {
            model: dts.cols
            Rectangle {
                required property int index
                x: index * 8 + 1; y: 4; width: 6; height: 6; radius: 3
                color: index === dts.lit - 1 ? "#f3531a" : Kirigami.Theme.textColor
                opacity: index < dts.lit ? 1 : 0.18
            }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: m => dts.picked(m.x / width)
            onWheel: w => dts.scrolled(w.angleDelta.y > 0 ? 1 : -1)
        }
    }

    fullRepresentation: Item {
        id: view
        Layout.preferredWidth: 288
        Layout.preferredHeight: col.implicitHeight + 24
        Layout.minimumWidth: 288
        Layout.minimumHeight: Layout.preferredHeight
        Layout.maximumWidth: 288
        Layout.maximumHeight: Layout.preferredHeight

        Image { id: img; source: root.art; asynchronous: true; visible: false; sourceSize.width: 400; onStatusChanged: if (status === Image.Ready) probe.fetch() }
        readonly property bool hasArt: root.art !== "" && img.status === Image.Ready
        readonly property bool wide: hasArt && img.implicitHeight > 0 && img.implicitWidth / img.implicitHeight > 1.3
        readonly property int dc: 88
        readonly property int dr: wide ? 50 : 88
        onDrChanged: probe.fetch()
        Canvas {    // cover sampled at 2x2 pixels per dot, hidden
            id: probe
            property var px: []
            property string done: ""
            width: view.dc * 2; height: view.dr * 2; opacity: 0.01
            renderTarget: Canvas.Image
            anchors.centerIn: parent
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
                if (root.art === "" || img.status !== Image.Ready) return
                var c = getContext("2d"), W = view.dc * 2, H = view.dr * 2, w = img.implicitWidth, h = img.implicitHeight
                // getImageData counts physical pixels on scaled screens; detect that first
                c.reset(); c.fillStyle = "#ffffff"; c.fillRect(W / 2, 0, W / 2, H)
                var physical = c.getImageData(Math.floor(W * 0.55), 4, 1, 1).data[3] === 0, q = physical ? 1 / Screen.devicePixelRatio : 1
                var k = Math.max(W * q / w, H * q / h)
                c.reset(); c.drawImage(img, (W * q - w * k) / 2, (H * q - h * k) / 2, w * k, h * k)
                var d = c.getImageData(0, 0, W, H).data, o = []
                for (var y = 0; y < view.dr; y++) for (var x = 0; x < view.dc; x++) {
                    var t = [0, 0, 0]
                    for (var j = 0; j < 2; j++) for (var i = 0; i < 2; i++) { var z = ((y * 2 + j) * W + x * 2 + i) * 4; t[0] += d[z]; t[1] += d[z + 1]; t[2] += d[z + 2] }
                    o.push(Qt.rgba(t[0] / 1020, t[1] / 1020, t[2] / 1020, 1))
                }
                if (d[(Math.floor(H / 2) * W + Math.floor(W / 2)) * 4 + 3] === 0) return      // nothing drawn yet
                px = o; done = root.art; cover.opacity = 0; cover.requestPaint(); appear.restart()
            }
        }

        ColumnLayout {
            id: col
            anchors.horizontalCenter: parent.horizontalCenter
            y: 12
            width: 264
            spacing: 8
            Rectangle {
                Layout.preferredWidth: 264
                Layout.preferredHeight: view.hasArt ? view.dr * 3 : 110
                radius: 12; color: root.boardColor(0.9); border.color: root.edge; border.width: 1
                Canvas {
                    id: cover
                    anchors.fill: parent
                    visible: view.hasArt
                    NumberAnimation { id: appear; target: cover; property: "opacity"; to: 1; duration: 350 }
                    onHeightChanged: requestPaint()
                    onPaint: {
                        var c = getContext("2d"), a = probe.px, C = view.dc, R = view.dr, cr = 4.2; c.reset()
                        if (a.length !== C * R) return
                        for (var i = 0; i < a.length; i++) {
                            var x = i % C, y = Math.floor(i / C)
                            var ex = Math.max(cr - x - 0.5, x + 0.5 - (C - cr), 0), ey = Math.max(cr - y - 0.5, y + 0.5 - (R - cr), 0)
                            if (ex * ex + ey * ey > cr * cr * 0.85) continue
                            c.fillStyle = a[i]; c.beginPath(); c.arc((x + 0.5) * 3, (y + 0.5) * 3, 1.4, 0, 6.2832); c.fill()
                        }
                    }
                }
                Vis { visible: !view.hasArt; pitch: 13; anchors.centerIn: parent }
                MouseArea { anchors.fill: parent; enabled: root.player?.canRaise ?? false; cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor; onClicked: { root.player.Raise(); root.expanded = false } }
            }
            PC.Label { text: root.track || "Nothing playing"; textFormat: Text.PlainText; font.bold: true; wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true; Layout.topMargin: 2 }
            PC.Label { visible: text !== ""; text: root.artist; textFormat: Text.PlainText; opacity: 0.6; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true; Layout.topMargin: -6 }
            Dots { visible: root.length > 0; value: root.pos / Math.max(1, root.length); onPicked: f => root.seek(f); onScrolled: d => root.seek((root.pos + d * 5e6) / root.length) }
            RowLayout {
                visible: root.length > 0
                Layout.topMargin: -6
                Text { text: root.fmt(root.pos); font.family: "Ndot55Caps"; font.pointSize: 11; color: Kirigami.Theme.textColor; Layout.fillWidth: true }
                Text { text: root.fmt(root.length); font.family: "Ndot55Caps"; font.pointSize: 11; color: Kirigami.Theme.textColor; opacity: 0.6 }
            }
            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: 2
                Glyph { anchors.verticalCenter: parent.verticalCenter; visible: root.shuffle !== 0; pitch: 2; tint: root.shuffle === 2 ? "#f3531a" : Kirigami.Theme.textColor; onClicked: root.player.shuffle = root.shuffle === 2 ? 1 : 2
                    rows9: [".......#.", "##....###", "..#..#.#.", "...##....", "...##....", "..#..#.#.", "##....###", ".......#.", "........."] }
                Glyph { anchors.verticalCenter: parent.verticalCenter; enabled: root.player?.canGoPrevious ?? false; onClicked: root.player.Previous()
                    rows9: ["#.....#", "#...###", "#..####", "#.#####", "#..####", "#...###", "#.....#"] }
                Glyph { anchors.verticalCenter: parent.verticalCenter; pitch: 4; tint: "#f3531a"; enabled: root.track !== ""; onClicked: root.player.PlayPause()
                    rows9: root.playing ? ["##...##", "##...##", "##...##", "##...##", "##...##", "##...##", "##...##"] : ["##.....", "####...", "######.", "#######", "######.", "####...", "##....."] }
                Glyph { anchors.verticalCenter: parent.verticalCenter; enabled: root.player?.canGoNext ?? false; onClicked: root.player.Next()
                    rows9: ["#.....#", "###...#", "####..#", "#####.#", "####..#", "###...#", "#.....#"] }
                Glyph { anchors.verticalCenter: parent.verticalCenter; visible: root.loop !== 0; pitch: 2; tint: root.loop > 1 ? "#f3531a" : Kirigami.Theme.textColor; onClicked: root.player.loopStatus = root.loop === 1 ? 2 : root.loop === 2 ? 3 : 1
                    rows9: root.loop === 3 ? ["......#..", "########.", "#.....#..", "#...#....", "...##...#", "....#...#", "..#.....#", ".########", "..#......"] : ["......#..", "########.", "#.....#..", "#........", "........#", "........#", "..#.....#", ".########", "..#......"] }
            }
            RowLayout {
                visible: root.track !== ""
                spacing: 8
                DotIcon { pitch: 1.3; rows: ["...........", "....#......", "...##......", "..###......", "#####..#...", "#####...#..", "#####..#...", "..###......", "...##......", "....#......", "..........."]; opacity: 0.7 }
                Dots { cols: 25; value: root.player?.volume ?? 0; onPicked: f => { var v = Math.max(0, Math.min(1, f)); root.player.changeVolume(v - (root.player.volume ?? 0), false) } onScrolled: d => root.player.changeVolume(d * 0.05, false) }
                PC.Label { text: Math.round((root.player?.volume ?? 0) * 100) + "%"; font: Kirigami.Theme.smallFont; opacity: 0.6; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight }
            }
            PC.Label { visible: text !== ""; text: root.source; textFormat: Text.PlainText; font: Kirigami.Theme.smallFont; opacity: 0.45; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true }
        }
    }
}
