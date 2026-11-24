import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PC
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors

PlasmoidItem {
    id: root
    function n(s) { var v = Number(s.value); return isNaN(v) ? 0 : v }
    Sensors.Sensor { id: cpu; sensorId: "cpu/all/usage"; updateRateLimit: 2000 }
    Sensors.Sensor { id: mem; sensorId: "memory/physical/usedPercent"; updateRateLimit: 4000 }
    Sensors.Sensor { id: temp; sensorId: "cpu/all/averageTemperature"; updateRateLimit: 4000 }
    Sensors.Sensor { id: gpu; sensorId: "gpu/all/usage"; updateRateLimit: 4000 }
    toolTipMainText: "System"
    toolTipSubText: "CPU " + Math.round(n(cpu)) + "%  Memory " + Math.round(n(mem)) + "%  " + Math.round(n(temp)) + "°C"

    compactRepresentation: MouseArea {
        Layout.minimumWidth: row.implicitWidth + Kirigami.Units.smallSpacing * 2
        Layout.preferredWidth: Layout.minimumWidth
        Layout.maximumWidth: Layout.minimumWidth
        onClicked: root.expanded = !root.expanded
        Row {
            id: row
            anchors.centerIn: parent
            spacing: 10
            Repeater {
                model: [{ t: "C", v: root.n(cpu) }, { t: "M", v: root.n(mem) }]
                Row {
                    required property var modelData
                    spacing: 5
                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                    Text { text: modelData.t; font.family: "Ndot55Caps"; font.pointSize: 12; color: Kirigami.Theme.textColor; opacity: 0.6; anchors.verticalCenter: parent.verticalCenter }
                    DotBar { cols: 6; rows: 3; pitch: 5; value: modelData.v / 100; hot: modelData.v >= 85; anchors.verticalCenter: parent.verticalCenter }
                }
            }
            Text { text: Math.round(root.n(temp)) + "°"; font.family: "Ndot55Caps"; font.pointSize: 13; color: root.n(temp) >= 85 ? "#f3531a" : Kirigami.Theme.textColor; anchors.verticalCenter: parent.verticalCenter }
        }
    }
    fullRepresentation: Item {
        Layout.preferredWidth: col.implicitWidth + 32
        Layout.preferredHeight: col.implicitHeight + 32
        Layout.minimumWidth: Layout.preferredWidth
        Layout.minimumHeight: Layout.preferredHeight
        ColumnLayout {
            id: col
            anchors.centerIn: parent
            spacing: 12
            Repeater {
                model: [{ t: "CPU", v: root.n(cpu), m: 100, u: "%" }, { t: "Memory", v: root.n(mem), m: 100, u: "%" }, { t: "GPU", v: root.n(gpu), m: 100, u: "%" }, { t: "CPU temperature", v: root.n(temp), m: 100, u: "°C" }]
                ColumnLayout {
                    required property var modelData
                    spacing: 4
                    RowLayout {
                        PC.Label { text: modelData.t; Layout.fillWidth: true }
                        Text { text: Math.round(modelData.v) + modelData.u; font.family: "Ndot55Caps"; font.pointSize: 14; color: Kirigami.Theme.textColor }
                    }
                    DotBar { value: modelData.v / modelData.m; hot: modelData.v >= 85 }
                }
            }
        }
    }
}
