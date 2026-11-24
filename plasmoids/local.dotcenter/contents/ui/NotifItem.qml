import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PC
import org.kde.kirigami as Kirigami
Rectangle {
    id: it
    required property var model
    required property int index
    property color ink
    property date now
    signal closed()
    signal opened()
    signal acted(string name)
    readonly property var names: model.actionNames || []
    readonly property var labels: model.actionLabels || []
    readonly property bool critical: model.urgency === 4
    // Bodies can hold markup: show plain text only, so nothing in them is loaded or run
    function plain(s) {
        return String(s || "").replace(/<br\s*\/?>/gi, "\n").replace(/<[^>]*>/g, "").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, "\"").replace(/&(apos|#39);/g, "'").replace(/&nbsp;/g, " ").replace(/&amp;/g, "&").trim()
    }
    function ago(t) {
        var d = t ? new Date(t) : null; if (!d || isNaN(d.getTime())) return ""
        var m = Math.floor((now.getTime() - d.getTime()) / 60000)
        return m < 1 ? "now" : m < 60 ? m + "m" : m < 1440 ? Math.floor(m / 60) + "h" : Math.floor(m / 1440) + "d"
    }
    implicitHeight: col.implicitHeight + 20
    radius: 12
    color: Qt.rgba(ink.r, ink.g, ink.b, area.containsMouse ? 0.1 : 0.05)
    border.width: 1; border.color: critical ? "#f3531a" : Qt.rgba(ink.r, ink.g, ink.b, 0.16)
    MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; cursorShape: it.model.hasDefaultAction ? Qt.PointingHandCursor : Qt.ArrowCursor; acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: m => { if (m.button === Qt.MiddleButton) it.closed(); else if (it.model.hasDefaultAction) it.opened() } }
    ColumnLayout {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
        spacing: 3
        RowLayout {
            spacing: 7
            Kirigami.Icon { source: it.model.applicationIconName || it.model.iconName || "dialog-information"; Layout.preferredWidth: 16; Layout.preferredHeight: 16 }
            PC.Label { text: it.plain(it.model.applicationName); textFormat: Text.PlainText; font: Kirigami.Theme.smallFont; opacity: 0.6; elide: Text.ElideRight; Layout.fillWidth: true }
            PC.Label { text: it.ago(it.model.updated || it.model.created); font: Kirigami.Theme.smallFont; opacity: 0.6 }
            Item {
                Layout.preferredWidth: 16; Layout.preferredHeight: 16
                Accessible.role: Accessible.Button; Accessible.name: "Dismiss"; Accessible.onPressAction: it.closed()
                DotIcon { anchors.centerIn: parent; pitch: 1.2; color: x.containsMouse ? "#f3531a" : it.ink; opacity: x.containsMouse ? 1 : 0.5
                    rows: ["#.........#", ".#.......#.", "..#.....#..", "...#...#...", "....#.#....", ".....#.....", "....#.#....", "...#...#...", "..#.....#..", ".#.......#.", "#.........#"] }
                MouseArea { id: x; anchors.fill: parent; anchors.margins: -4; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: it.closed() }
            }
        }
        PC.Label { text: it.plain(it.model.summary); textFormat: Text.PlainText; visible: text !== ""; font.bold: true; wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight; Layout.fillWidth: true }
        PC.Label { text: it.plain(it.model.body); textFormat: Text.PlainText; visible: text !== ""; opacity: 0.8; wrapMode: Text.Wrap; maximumLineCount: area.containsMouse ? 8 : 2; elide: Text.ElideRight; Layout.fillWidth: true }
        Flow {
            visible: it.names.length > 0; spacing: 6; Layout.fillWidth: true; Layout.topMargin: 3
            Repeater { model: Math.min(3, it.names.length); PC.Button { required property int index; text: String(it.labels[index] || ""); onClicked: it.acted(it.names[index]) } }
        }
    }
}
