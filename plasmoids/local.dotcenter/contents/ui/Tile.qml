import QtQuick
import org.kde.plasma.components as PC
import org.kde.kirigami as Kirigami
Item {
    id: tile
    property string label
    property var glyph: []
    property bool active: false
    property color ink
    signal clicked()
    implicitHeight: 74
    activeFocusOnTab: true
    Accessible.role: Accessible.CheckBox
    Accessible.name: label
    Accessible.checked: active
    Accessible.onPressAction: clicked()
    Keys.onSpacePressed: clicked()
    Keys.onReturnPressed: clicked()
    Rectangle {
        id: board
        width: parent.width; height: 52; radius: 12
        color: tile.active ? "#f3531a" : Qt.rgba(tile.ink.r, tile.ink.g, tile.ink.b, area.containsMouse ? 0.14 : 0.07)
        border.width: tile.activeFocus ? 2 : 1
        border.color: tile.activeFocus ? "#f3531a" : Qt.rgba(tile.ink.r, tile.ink.g, tile.ink.b, tile.active ? 0 : 0.2)
        Behavior on color { ColorAnimation { duration: 120 } }
        DotIcon { anchors.centerIn: parent; rows: tile.glyph; color: tile.active ? "#141414" : tile.ink }
    }
    PC.Label {
        anchors { top: board.bottom; topMargin: 3; horizontalCenter: parent.horizontalCenter }
        width: parent.width + 6; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
        text: tile.label; font: Kirigami.Theme.smallFont; opacity: tile.active ? 1 : 0.65
    }
    MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: tile.clicked() }
}
