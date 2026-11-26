import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PC
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: root
    function n(s) { var v = Number(s.value); return isNaN(v) ? 0 : v }
    Sensors.Sensor { id: cpu; sensorId: "cpu/all/usage"; updateRateLimit: 3000 }
    Sensors.Sensor { id: mem; sensorId: "memory/physical/usedPercent"; updateRateLimit: 4000 }
    Sensors.Sensor { id: temp; sensorId: "cpu/all/averageTemperature"; updateRateLimit: 4000 }
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
                    Text { text: modelData.t; font.family: "FD Dots"; font.capitalization: Font.AllUppercase; font.pointSize: 12; color: Kirigami.Theme.textColor; opacity: 0.6; anchors.verticalCenter: parent.verticalCenter }
                    DotBar { cols: 6; rows: 3; pitch: 5; value: modelData.v / 100; hot: modelData.v >= 85; anchors.verticalCenter: parent.verticalCenter }
                }
            }
            Text { text: Math.round(root.n(temp)) + "°"; font.family: "FD Dots"; font.capitalization: Font.AllUppercase; font.pointSize: 13; color: root.n(temp) >= 85 ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor; anchors.verticalCenter: parent.verticalCenter }
        }
    }
    fullRepresentation: Item {
        id: view
        Layout.preferredWidth: col.implicitWidth + 20
        Layout.preferredHeight: col.implicitHeight + 20
        Layout.minimumWidth: Layout.preferredWidth
        Layout.minimumHeight: Layout.preferredHeight
        Layout.maximumWidth: Layout.preferredWidth
        Layout.maximumHeight: Layout.preferredHeight
        // Everything below is measured only while the pop-up is open
        readonly property bool live: root.expanded || Plasmoid.formFactor === PlasmaCore.Types.Planar
        readonly property int cores: coreCount.value > 0 ? Math.min(32, Math.round(Number(coreCount.value))) : 0
        function has(q) { return q.value !== undefined && q.value !== null && q.value !== "" && !isNaN(Number(q.value)) }
        function gb(v) { return (v / 1073741824).toFixed(v > 107374182400 ? 0 : 1) }
        function rate(v) { return v >= 1048576 ? (v / 1048576).toFixed(1) + " MB/s" : Math.round(v / 1024) + " KB/s" }
        function dur(v) { var d = Math.floor(v / 86400), h = Math.floor(v / 3600) % 24, m = Math.floor(v / 60) % 60; return d ? d + "d " + h + "h" : h ? h + "h " + m + "m" : m + "m" }
        component S: Sensors.Sensor { enabled: view.live; updateRateLimit: 2000 }
        S { id: gpu; sensorId: "gpu/all/usage" }
        S { id: freq; sensorId: "cpu/all/averageFrequency" }
        S { id: coreCount; sensorId: "cpu/all/coreCount" }
        S { id: memUsed; sensorId: "memory/physical/used" }
        S { id: memTotal; sensorId: "memory/physical/total" }
        S { id: diskPct; sensorId: "disk/all/usedPercent"; updateRateLimit: 10000 }
        S { id: diskUsed; sensorId: "disk/all/used"; updateRateLimit: 10000 }
        S { id: diskTotal; sensorId: "disk/all/total"; updateRateLimit: 10000 }
        S { id: down; sensorId: "network/all/download" }
        S { id: up; sensorId: "network/all/upload" }
        S { id: upt; sensorId: "os/system/uptime"; updateRateLimit: 30000 }
        S { id: fan; sensorId: "lmsensors/cros_ec-isa-000c/fan1" }

        property string watts: ""
        property var apps: []
        P5Support.DataSource {
            engine: "executable"
            interval: 5000
            connectedSources: view.live ? ["LC_ALL=C; for b in /sys/class/power_supply/BAT*; do [ -e $b/power_now ] && awk '{printf \"W %.1f\\n\", $1/1e6}' $b/power_now || { [ -e $b/current_now ] && paste $b/current_now $b/voltage_now | awk '{printf \"W %.1f\\n\", $1*$2/1e12}'; }; echo \"S $(cat $b/status)\"; break; done; top -b -n 2 -d 0.6 -w 120 | awk '/^top/{n++} n==2 && $1 ~ /^[0-9]+$/ && $12 != \"top\" {c[$12]+=$9} END{for(k in c) if(c[k]>=1) print \"P\", c[k], k}' | sort -k2 -rn | head -4"] : []
            onNewData: (src, d) => {
                var w = "", st = "", list = []
                d.stdout.split("\n").forEach(l => {
                    var f = l.split(" ")
                    if (f[0] === "W") w = f[1]; else if (f[0] === "S") st = f.slice(1).join(" ")
                    else if (f[0] === "P" && Number(f[1]) > 0) list.push({ c: Math.round(Number(f[1])), n: f.slice(2).join(" ") })
                })
                view.watts = w ? w + " W " + (st === "Charging" ? "in" : st === "Discharging" ? "out" : "") : ""
                view.apps = list
            }
        }

        component Row1: ColumnLayout {
            property string t
            property string sub
            property real v
            spacing: 3
            RowLayout {
                PC.Label { text: t }
                PC.Label { text: sub; opacity: 0.55; font: Kirigami.Theme.smallFont; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight }
                Text { text: Math.round(v) + "%"; font.family: "FD Dots"; font.capitalization: Font.AllUppercase; font.pointSize: 13; color: Kirigami.Theme.textColor; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 46 }
            }
            DotBar { cols: 34; rows: 2; pitch: 8; value: v / 100; hot: v >= 85 }
        }

        ColumnLayout {
            id: col
            anchors.centerIn: parent
            spacing: 10
            Row1 { t: "CPU"; v: root.n(cpu); sub: (view.has(freq) ? (root.n(freq) / 1000).toFixed(1) + " GHz  " : "") + Math.round(root.n(temp)) + "°C" }
            Row {    // one column of dots per core
                visible: view.cores > 0
                Layout.alignment: Qt.AlignHCenter
                Repeater {
                    model: view.cores
                    Item {
                        id: cr
                        required property int index
                        width: 272 / view.cores; height: 30
                        Sensors.Sensor { id: cs; sensorId: "cpu/cpu" + cr.index + "/usage"; enabled: view.live; updateRateLimit: 2000 }
                        readonly property real u: root.n(cs)
                        readonly property int lit: u < 3 ? 0 : Math.max(1, Math.round(u / 20))
                        Repeater {
                            model: 5
                            Rectangle {
                                required property int index
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: index * 6; width: 5; height: 5; radius: 2.5
                                color: index === 5 - cr.lit || cr.u >= 85 ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                                opacity: index >= 5 - cr.lit ? 1 : 0.15
                            }
                        }
                    }
                }
            }
            Row1 { t: "Memory"; v: root.n(mem); sub: view.has(memTotal) ? view.gb(root.n(memUsed)) + " / " + view.gb(root.n(memTotal)) + " GB" : "" }
            Row1 { t: "GPU"; v: root.n(gpu); visible: view.has(gpu) }
            Row1 { t: "Disk"; v: root.n(diskPct); sub: view.has(diskTotal) ? view.gb(root.n(diskUsed)) + " / " + view.gb(root.n(diskTotal)) + " GB" : ""; visible: view.has(diskPct) }
            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Kirigami.Theme.textColor; opacity: 0.12 }
            Grid {
                columns: 2; rowSpacing: 5
                Repeater {
                    model: [["Download", view.rate(root.n(down))], ["Upload", view.rate(root.n(up))], ["Power", view.watts], ["Fan", view.has(fan) ? Math.round(root.n(fan)) + " rpm" : ""], ["Uptime", view.has(upt) ? view.dur(root.n(upt)) : ""]].filter(x => x[1] !== "")
                    Column {
                        required property var modelData
                        width: 136
                        PC.Label { text: modelData[0]; opacity: 0.55; font: Kirigami.Theme.smallFont }
                        PC.Label { text: modelData[1] }
                    }
                }
            }
            Rectangle { visible: view.apps.length > 0; Layout.fillWidth: true; implicitHeight: 1; color: Kirigami.Theme.textColor; opacity: 0.12 }
            ColumnLayout {
                visible: view.apps.length > 0
                spacing: 1
                PC.Label { text: "Busiest (% of one core)"; opacity: 0.55; font: Kirigami.Theme.smallFont }
                Repeater {
                    model: view.apps
                    RowLayout {
                        required property var modelData
                        PC.Label { text: modelData.n; textFormat: Text.PlainText; elide: Text.ElideRight; Layout.preferredWidth: 220 }
                        PC.Label { text: modelData.c + "%"; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 46 }
                    }
                }
            }
        }
    }
}
