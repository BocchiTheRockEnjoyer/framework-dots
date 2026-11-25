import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.kicker as Kicker

PlasmoidItem {
    id: root
    signal refreshed()
    property var dash: null
    preferredRepresentation: fullRepresentation      // we open our own window, so Plasma shouldn't
    toolTipMainText: "Apps"
    toolTipSubText: "Search and open your apps"
    Plasmoid.icon: "view-app-grid-symbolic"

    function toggle(item) {
        if (!dash) dash = dashComponent.createObject(item, { visualParent: item })
        if (dash) dash.toggle()
    }

    fullRepresentation: MouseArea {
        id: button
        Layout.minimumWidth: Plasmoid.formFactor === PlasmaCore.Types.Vertical ? 0 : height
        Layout.maximumWidth: Layout.minimumWidth
        Layout.minimumHeight: Plasmoid.formFactor === PlasmaCore.Types.Vertical ? width : 0
        hoverEnabled: true
        activeFocusOnTab: true
        Accessible.role: Accessible.Button; Accessible.name: "Apps"; Accessible.onPressAction: root.toggle(button)
        Keys.onSpacePressed: root.toggle(button)
        Keys.onReturnPressed: root.toggle(button)
        onClicked: root.toggle(button)
        Connections { target: Plasmoid; function onActivated() { root.toggle(button) } }
        Grid {
            id: nine
            anchors.centerIn: parent
            readonly property real dot: Math.max(3, Math.round(Math.min(button.width, button.height) * 0.12))
            columns: 3; spacing: dot * 0.72
            scale: button.pressed ? 0.9 : button.containsMouse ? 1.08 : 1
            Behavior on scale { NumberAnimation { duration: 110 } }
            Repeater { model: 9; Rectangle { required property int index; width: nine.dot; height: width; radius: width / 2; color: index === 4 && (button.containsMouse || (root.dash && root.dash.visible)) ? "#f3531a" : Kirigami.Theme.textColor } }
        }
    }

    Component { id: dashComponent; Dash { rootModel: apps; runnerModel: runner; systemModel: power; owner: root; onDone: toggle() } }

    Kicker.RootModel {
        id: apps
        autoPopulate: false
        appNameFormat: 0
        flat: true; sorted: true; showSeparators: false; showTopLevelItems: false
        showAllApps: true; showAllAppsCategorized: false
        showRecentApps: false; showRecentDocs: false; showPowerSession: false
        appletInterface: root
        onRefreshed: root.refreshed()
        Component.onCompleted: {
            // Not every Plasma 6 version has these
            for (const k of ["showRecentFolders", "showRootSeparator"]) if (k in apps) apps[k] = false
            if (favoritesModel) favoritesModel.initForClient("org.kde.plasma.kicker.favorites.instance-" + Plasmoid.id)
        }
    }
    Kicker.RunnerModel {
        id: runner
        appletInterface: root
        favoritesModel: apps.favoritesModel
        mergeResults: true
        runners: ["krunner_services", "krunner_systemsettings", "krunner_sessions", "krunner_powerdevil", "calculator", "unitconverter"]
    }
    Kicker.SystemModel { id: power }
    Kicker.ProcessRunner { id: proc }
    Plasmoid.contextualActions: [PlasmaCore.Action { text: "Edit Applications…"; icon.name: "kmenuedit"; onTriggered: proc.runMenuEditor() }]
}
