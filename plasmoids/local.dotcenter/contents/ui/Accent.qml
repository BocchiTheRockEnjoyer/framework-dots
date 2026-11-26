import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC
// Accent colour presets, and a window for any other colour. framework-dots-accent does the work.
Item {
    id: bar
    property color ink
    property color now: Kirigami.Theme.highlightColor      // the accent in use, from the colour scheme
    signal chosen(string c)
    // Written as numbers so the recolouring leaves them alone
    readonly property var presets: [["orange", 243 / 255, 83 / 255, 26 / 255], ["red", 1, .231, .231], ["pink", 1, .31, .639], ["purple", .663, .439, 1], ["blue", .298, .553, 1], ["cyan", .133, .827, .933], ["green", .224, .827, .325], ["lime", .224, 1, .078], ["yellow", 1, .839, .039], ["white", .949, .949, .949]]
    implicitHeight: 30
    function near(a, b) { return Math.abs(a.r - b.r) + Math.abs(a.g - b.g) + Math.abs(a.b - b.b) < 0.02 }
    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: (bar.width - 11 * 22) / 10
        Repeater {
            model: bar.presets
            Item {
                id: dot
                required property var modelData
                readonly property color tint: Qt.rgba(modelData[1], modelData[2], modelData[3], 1)
                readonly property bool on: bar.near(tint, bar.now)
                width: 22; height: 22
                activeFocusOnTab: true
                Accessible.role: Accessible.RadioButton; Accessible.name: "Accent colour " + modelData[0]; Accessible.checked: on
                Accessible.onPressAction: bar.chosen(modelData[0])
                Keys.onSpacePressed: bar.chosen(modelData[0])
                Keys.onReturnPressed: bar.chosen(modelData[0])
                Rectangle { anchors.centerIn: parent; width: 22; height: 22; radius: 11; color: "transparent"; border.width: 2; border.color: bar.ink; visible: dot.on || dot.activeFocus; opacity: dot.on ? 0.9 : 0.5 }
                Rectangle { anchors.centerIn: parent; width: ma.containsMouse && !dot.on ? 18 : 14; height: width; radius: width / 2; color: dot.tint; border.width: 1; border.color: Qt.rgba(bar.ink.r, bar.ink.g, bar.ink.b, 0.22); Behavior on width { NumberAnimation { duration: 90 } } }
                MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (!dot.on) bar.chosen(dot.modelData[0]) }
            }
        }
        Item {
            width: 22; height: 22
            activeFocusOnTab: true
            Accessible.role: Accessible.Button; Accessible.name: "Other accent colour"; Accessible.onPressAction: bar.chosen("pick")
            Keys.onSpacePressed: bar.chosen("pick")
            Keys.onReturnPressed: bar.chosen("pick")
            DotIcon { anchors.centerIn: parent; pitch: 1.6; color: more.containsMouse || parent.activeFocus ? bar.now : bar.ink; opacity: 0.9
                rows: ["...........", ".....#.....", ".....#.....", ".....#.....", ".....#.....", ".#########.", ".....#.....", ".....#.....", ".....#.....", ".....#.....", "..........."] }
            MouseArea { id: more; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: bar.chosen("pick") }
        }
    }
}
