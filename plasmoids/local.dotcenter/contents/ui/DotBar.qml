import QtQuick
import org.kde.kirigami as Kirigami
Item {
    id: bar
    property real value: 0      // 0..1
    property int cols: 30
    property int rows: 3
    property real pitch: 9
    property bool hot: false
    readonly property int lit: value <= 0 ? 0 : Math.max(1, Math.round(Math.min(1, value) * cols))
    implicitWidth: cols * pitch; implicitHeight: rows * pitch
    Repeater {
        model: bar.cols * bar.rows
        Rectangle {
            required property int index
            readonly property int col: Math.floor(index / bar.rows)
            x: col * bar.pitch + 1; y: (index % bar.rows) * bar.pitch + 1
            width: bar.pitch - 2; height: width; radius: width / 2
            color: col < bar.lit && (bar.hot || col === bar.lit - 1) ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
            opacity: col < bar.lit ? 1 : 0.18
        }
    }
}
