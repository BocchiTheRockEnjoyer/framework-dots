import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.taskmanager as TaskManager
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    preferredRepresentation: fullRepresentation
    Plasmoid.status: info.numberOfDesktops > 1 ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.HiddenStatus
    toolTipMainText: info.desktopNames[Math.max(0, info.desktopIds.indexOf(info.currentDesktop))] || ""

    TaskManager.VirtualDesktopInfo { id: info }

    fullRepresentation: Item {
        Layout.minimumWidth: row.implicitWidth + 4
        Layout.preferredWidth: Layout.minimumWidth
        Layout.maximumWidth: Layout.minimumWidth
        Layout.fillHeight: true
        Row {
            id: row
            anchors.right: parent.right
            height: parent.height
            Repeater {
                model: info.desktopIds
                MouseArea {
                    required property var modelData
                    readonly property bool current: modelData === info.currentDesktop
                    width: dot.width + 8; height: row.height
                    hoverEnabled: true
                    onClicked: info.requestActivate(modelData)
                    Rectangle {
                        id: dot
                        anchors.centerIn: parent
                        width: parent.current ? 18 : 7; height: 7; radius: 3.5
                        antialiasing: true
                        color: parent.current ? "#f3531a" : Kirigami.Theme.textColor
                        opacity: parent.current || parent.containsMouse ? 1 : 0.4
                        Behavior on width { NumberAnimation { duration: Kirigami.Units.shortDuration } }
                    }
                }
            }
        }
    }
}
