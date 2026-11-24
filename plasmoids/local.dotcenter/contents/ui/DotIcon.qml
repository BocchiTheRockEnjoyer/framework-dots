import QtQuick
import org.kde.kirigami as Kirigami
Item {
    id: ic
    property var rows: []
    property color color: Kirigami.Theme.textColor
    property real pitch: 2
    implicitWidth: 11 * pitch; implicitHeight: 11 * pitch
    Repeater {
        model: 121
        Rectangle {
            required property int index
            visible: ic.rows.length === 11 && ic.rows[Math.floor(index / 11)][index % 11] === "#"
            x: (index % 11 + 0.075) * ic.pitch; y: (Math.floor(index / 11) + 0.075) * ic.pitch
            width: ic.pitch * 0.85; height: width; radius: width / 2
            color: ic.color
        }
    }
}
