import QtQuick
import org.kde.kirigami as Kirigami
Item {
    id: s
    property var glyph: []
    property real value: 0
    property real minimum: 0
    property bool faded: false
    property color ink
    property real dragValue: -1
    readonly property real shown: dragValue >= 0 ? dragValue : value
    signal moved(real v)
    signal glyphClicked()
    implicitHeight: 26
    DotIcon {
        id: icon
        anchors.verticalCenter: parent.verticalCenter
        rows: s.glyph; color: s.ink; opacity: s.faded ? 0.45 : 1
        MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: s.glyphClicked() }
    }
    Item {
        id: track
        anchors { left: icon.right; leftMargin: 14; right: pct.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
        height: 26
        readonly property real pitch: 8
        readonly property int cols: Math.max(1, Math.floor(width / pitch))
        readonly property int lit: s.shown <= 0 ? 0 : Math.max(1, Math.round(s.shown * cols))
        Repeater {
            model: track.cols * 2
            Rectangle {
                required property int index
                readonly property int col: Math.floor(index / 2)
                x: col * track.pitch; y: 6 + (index % 2) * track.pitch
                width: 6; height: 6; radius: 3
                color: col === track.lit - 1 && !s.faded ? Kirigami.Theme.highlightColor : s.ink
                opacity: col < track.lit ? (s.faded ? 0.4 : 1) : 0.16
            }
        }
        MouseArea {
            anchors.fill: parent
            preventStealing: true
            cursorShape: Qt.PointingHandCursor
            function at(x) { return Math.max(s.minimum, Math.min(1, x / (track.cols * track.pitch))) }
            onPressed: m => { s.dragValue = at(m.x); s.moved(s.dragValue) }
            onPositionChanged: m => { if (pressed) { s.dragValue = at(m.x); s.moved(s.dragValue) } }
            onReleased: hold.restart()
            onCanceled: s.dragValue = -1
            onWheel: w => s.moved(Math.max(s.minimum, Math.min(1, s.value + (w.angleDelta.y > 0 ? 0.05 : -0.05))))
        }
        Timer { id: hold; interval: 500; onTriggered: s.dragValue = -1 }   // until the system reports back
    }
    Text {
        id: pct
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        width: 50; horizontalAlignment: Text.AlignRight
        text: Math.round(s.shown * 100) + "%"
        font.family: "FD Dots"; font.pointSize: 13; color: s.ink; opacity: s.faded ? 0.45 : 1
    }
}
