import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PC
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    toolTipMainText: "Shortcuts"
    readonly property var glyph: ["...........", "###########", "#.........#", "#.#.#.#.#.#", "#.........#", "#.#.#.#.#.#", "#.........#", "#..#####..#", "#.........#", "###########", "..........."]
    readonly property var keys: [["Desktops", ""], ["Super+Ctrl+1–4", "Go to desktop"], ["Super+Alt+1–4", "Move window to desktop"], ["Super+Ctrl+←/→", "Previous / next desktop"], ["3 or 4 finger swipe", "Switch desktop"],
        ["Windows", ""], ["Super+W", "Overview"], ["Super+arrows", "Snap to half"], ["Shift+drag", "Drop into a tile"], ["Super+T", "Edit tiles"], ["Super+PgUp / PgDn", "Maximise / minimise"], ["Alt+F4", "Close"],
        ["System", ""], ["Super", "App menu"], ["Super+D", "Peek at desktop"], ["Super+L", "Lock"], ["Super+G", "Desktop grid"]]
    compactRepresentation: MouseArea {
        Layout.minimumWidth: row.implicitWidth + Kirigami.Units.smallSpacing * 2
        Layout.preferredWidth: Layout.minimumWidth
        Layout.maximumWidth: Layout.minimumWidth
        onClicked: root.expanded = !root.expanded
        Row { id: row; anchors.centerIn: parent; DotIcon { rows: root.glyph } }
    }
    fullRepresentation: Item {
        Layout.preferredWidth: col.implicitWidth + 32
        Layout.preferredHeight: col.implicitHeight + 32
        Layout.minimumWidth: Layout.preferredWidth
        Layout.minimumHeight: Layout.preferredHeight
        ColumnLayout {
            id: col
            anchors.centerIn: parent
            spacing: 6
            Repeater {
                model: root.keys
                RowLayout {
                    required property var modelData
                    readonly property bool head: modelData[1] === ""
                    spacing: 24
                    Layout.topMargin: head ? 8 : 0
                    PC.Label { text: modelData[0]; Layout.preferredWidth: 190; color: parent.head ? "#f3531a" : Kirigami.Theme.textColor; font.bold: parent.head }
                    PC.Label { text: modelData[1]; opacity: 0.7; Layout.preferredWidth: 200 }
                }
            }
        }
    }
}
