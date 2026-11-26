import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PC
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    property var info: ({ output: 0, input: 0, cached: 0, limits: {}, age: null })
    property real now: Date.now() / 1000
    readonly property string cmd: "$HOME/.local/bin/claude-usage"
    readonly property bool hasLimit: pct("five_hour") >= 0
    readonly property string shortText: hasLimit ? Math.round(pct("five_hour")) + "%" : fmt(info.output)

    function pct(k) { var l = info.limits[k]; return l && l.used_percentage !== undefined ? l.used_percentage : -1 }
    function fmt(n) { return n >= 1e6 ? (n / 1e6).toFixed(1) + "M" : n >= 1e3 ? Math.round(n / 1e3) + "K" : String(n) }
    function resetText(k) {
        var l = info.limits[k]; if (!l || !l.resets_at) return ""
        var m = Math.max(0, Math.round((l.resets_at - now) / 60)), h = Math.floor(m / 60), d = Math.floor(h / 24)
        return "resets in " + (d > 0 ? d + "d " + (h % 24) + "h" : h > 0 ? h + "h " + (m % 60) + "m" : m + "m")
    }

    toolTipMainText: "Claude Code"
    toolTipSubText: hasLimit ? "5-hour limit: " + shortText + " used" : fmt(info.output) + " output tokens today"

    P5Support.DataSource {
        id: exec
        engine: "executable"
        interval: 60000
        connectedSources: [root.cmd]
        onNewData: (s, d) => { try { root.info = JSON.parse(d.stdout); root.now = Date.now() / 1000 } catch (e) {} }
    }

    readonly property var spark: [".....#.....", ".#...#...#.", "..#..#..#..", "...#.#.#...", "....###....", "###########", "....###....", "...#.#.#...", "..#..#..#..", ".#...#...#.", ".....#....."]

    compactRepresentation: MouseArea {
        Layout.minimumWidth: row.implicitWidth + Kirigami.Units.smallSpacing * 2
        Layout.preferredWidth: Layout.minimumWidth
        Layout.maximumWidth: Layout.minimumWidth
        hoverEnabled: true
        onClicked: root.expanded = !root.expanded
        Row {
            id: row
            anchors.centerIn: parent
            spacing: 5
            Item {
                width: 22; height: 22
                anchors.verticalCenter: parent.verticalCenter
                Repeater {
                    model: 121
                    Rectangle {
                        required property int index
                        visible: root.spark[Math.floor(index / 11)][index % 11] === "#"
                        x: (index % 11) * 2 + 0.15; y: Math.floor(index / 11) * 2 + 0.15
                        width: 1.7; height: 1.7; radius: 0.85
                        color: Kirigami.Theme.highlightColor
                    }
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.shortText
                font.family: "FD Dots"; font.capitalization: Font.AllUppercase; font.pointSize: 13
                color: root.pct("five_hour") >= 80 ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
            }
        }
    }

    component Meter: ColumnLayout {
        property string title
        property string key
        readonly property real value: root.pct(key)
        visible: value >= 0
        spacing: 4
        RowLayout {
            PC.Label { text: title; Layout.fillWidth: true }
            Text { text: Math.round(value) + "%"; font.family: "FD Dots"; font.capitalization: Font.AllUppercase; font.pointSize: 16; color: Kirigami.Theme.textColor }
        }
        Item {
            implicitWidth: 30 * 9; implicitHeight: 27
            Repeater {
                model: 90
                Rectangle {
                    required property int index
                    readonly property int col: Math.floor(index / 3)
                    readonly property int lit: value <= 0 ? 0 : Math.max(1, Math.round(Math.min(100, value) / 100 * 30))
                    x: col * 9 + 1; y: (index % 3) * 9 + 1; width: 7; height: 7; radius: 3.5
                    color: col < lit && (col === lit - 1 || value >= 80) ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                    opacity: col < lit ? 1 : 0.18
                }
            }
        }
        PC.Label { text: root.resetText(key); opacity: 0.6; font: Kirigami.Theme.smallFont }
    }

    fullRepresentation: Item {
        Layout.preferredWidth: col.implicitWidth + 32
        Layout.preferredHeight: col.implicitHeight + 32
        Layout.minimumWidth: Layout.preferredWidth
        Layout.minimumHeight: Layout.preferredHeight
        ColumnLayout {
            id: col
            anchors.centerIn: parent
            spacing: 14
            Kirigami.Heading { text: "Claude Code"; level: 3 }
            Meter { title: "5-hour limit"; key: "five_hour" }
            Meter { title: "Weekly limit"; key: "seven_day" }
            PC.Label {
                visible: !root.hasLimit && root.pct("seven_day") < 0
                text: "Limits appear once the status line\nis on and Claude has replied."
                opacity: 0.6
            }
            GridLayout {
                columns: 2; columnSpacing: 24
                PC.Label { text: "Output today"; Layout.fillWidth: true } PC.Label { text: root.fmt(root.info.output) }
                PC.Label { text: "Input today" } PC.Label { text: root.fmt(root.info.input) }
                PC.Label { text: "Cache reads" } PC.Label { text: root.fmt(root.info.cached) }
            }
            PC.Label {
                visible: root.info.age !== null
                text: "Limits updated " + (root.info.age < 60 ? "just now" : root.info.age < 3600 ? Math.round(root.info.age / 60) + "m ago" : Math.round(root.info.age / 3600) + "h ago")
                opacity: 0.6; font: Kirigami.Theme.smallFont
            }
        }
    }
}
