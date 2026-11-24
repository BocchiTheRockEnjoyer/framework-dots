import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PC
import org.kde.kirigami as Kirigami
import org.kde.notification

PlasmoidItem {
    id: root
    property int minutes: 25
    property bool resting: false
    property bool running: false
    property real endAt: 0
    property real remain: minutes * 60
    readonly property real total: minutes * 60
    readonly property var glyph: ["###########", ".#.......#.", ".#.......#.", "..#.....#..", "...#...#...", "....#.#....", "...#...#...", "..#.....#..", ".#.......#.", ".#.......#.", "###########"]
    function fmt(s) { s = Math.max(0, Math.ceil(s)); return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0") }
    function set(m, r) { running = false; minutes = m; resting = r; remain = m * 60 }
    function toggle() { if (running) { running = false } else { if (remain <= 0) remain = total; endAt = Date.now() + remain * 1000; running = true } }
    toolTipMainText: resting ? "Break" : "Focus"
    toolTipSubText: fmt(remain) + (running ? " left" : "")
    Timer {
        interval: 500; repeat: true; running: root.running
        onTriggered: {
            root.remain = (root.endAt - Date.now()) / 1000
            if (root.remain <= 0) { var was = root.resting; note.title = was ? "Break over" : "Focus done"; note.text = was ? "Ready for another round?" : "Time for a break."; note.sendEvent(); root.set(was ? 25 : 5, !was) }
        }
    }
    Notification { id: note; componentName: "plasma_workspace"; eventId: "notification"; iconName: "clock" }

    compactRepresentation: MouseArea {
        Layout.minimumWidth: row.implicitWidth + Kirigami.Units.smallSpacing * 2
        Layout.preferredWidth: Layout.minimumWidth
        Layout.maximumWidth: Layout.minimumWidth
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: m => { if (m.button === Qt.MiddleButton) root.toggle(); else root.expanded = !root.expanded }
        Row {
            id: row
            anchors.centerIn: parent
            spacing: 5
            DotIcon { rows: root.glyph; color: root.running ? "#f3531a" : Kirigami.Theme.textColor; anchors.verticalCenter: parent.verticalCenter }
            Text { visible: root.running || root.remain < root.total; text: root.fmt(root.remain); font.family: "FD Dots"; font.capitalization: Font.AllUppercase; font.pointSize: 13; color: Kirigami.Theme.textColor; anchors.verticalCenter: parent.verticalCenter }
        }
    }
    fullRepresentation: Item {
        Layout.preferredWidth: col.implicitWidth + 24
        Layout.preferredHeight: col.implicitHeight + 24
        Layout.minimumWidth: Layout.preferredWidth
        Layout.minimumHeight: Layout.preferredHeight
        Layout.maximumWidth: Layout.preferredWidth
        Layout.maximumHeight: Layout.preferredHeight
        ColumnLayout {
            id: col
            anchors.centerIn: parent
            spacing: 8
            PC.Label { text: root.resting ? "Break" : "Focus"; opacity: 0.6; Layout.alignment: Qt.AlignHCenter }
            Text { text: root.fmt(root.remain); font.family: "FD Dots"; font.capitalization: Font.AllUppercase; font.pointSize: 30; color: Kirigami.Theme.textColor; Layout.alignment: Qt.AlignHCenter }
            DotBar { cols: 26; rows: 4; pitch: 8; value: 1 - root.remain / root.total; Layout.alignment: Qt.AlignHCenter }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                PC.Button { text: root.running ? "Pause" : "Start"; onClicked: root.toggle() }
                PC.Button { text: "Reset"; onClicked: root.set(root.minutes, root.resting) }
            }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Repeater {
                    model: [15, 25, 50]
                    PC.ToolButton { required property int modelData; text: modelData + " min"; onClicked: root.set(modelData, false) }
                }
                PC.ToolButton { text: "Break 5"; onClicked: root.set(5, true) }
            }
        }
    }
}
