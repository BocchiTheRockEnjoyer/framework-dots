import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PC
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    readonly property color ink: Kirigami.Theme.textColor
    readonly property bool dark: { var b = Kirigami.Theme.backgroundColor; return 0.299 * b.r + 0.587 * b.g + 0.114 * b.b < 0.5 }
    readonly property var notifs: notifLoader.item
    readonly property int count: notifs ? notifs.count : 0
    readonly property bool dnd: !!notifs && notifs.dnd
    property int seen: 0
    readonly property int fresh: Math.max(0, count - seen)
    readonly property var bell: [".....#.....", "....###....", "...#...#...", "..#.....#..", "..#.....#..", "..#.....#..", "..#.....#..", ".#.......#.", "###########", "...........", "....###...."]
    readonly property var bellOff: ["#....#.....", ".#..###....", "..#....#...", "..##....#..", "..#.#...#..", "..#..#..#..", "..#...#.#..", ".#.....#.#.", "########.##", ".........#.", "....###...#"]

    onCountChanged: if (expanded || count < seen) seen = count
    onExpandedChanged: seen = count
    toolTipMainText: "Notifications"
    toolTipSubText: dnd ? "Do not disturb is on" : count === 0 ? "All clear" : count + (count === 1 ? " notification" : " notifications")

    Loader { id: notifLoader; source: "Notifs.qml" }
    P5Support.DataSource { id: sh; engine: "executable"; onNewData: (s, d) => disconnectSource(s); function run(c) { connectSource(c) } }
    function toggleMode() {
        var k = dark ? "DefaultLightLookAndFeel" : "DefaultDarkLookAndFeel", d = dark ? "org.kde.breeze.desktop" : "org.kde.breezedark.desktop"
        sh.run("plasma-apply-lookandfeel -a \"$(kreadconfig6 --file kdeglobals --group KDE --key " + k + " --default " + d + ")\"")
    }

    compactRepresentation: MouseArea {
        Layout.minimumWidth: icon.implicitWidth + Kirigami.Units.smallSpacing * 2
        Layout.preferredWidth: Layout.minimumWidth
        Layout.maximumWidth: Layout.minimumWidth
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: m => { if (m.button === Qt.MiddleButton && root.notifs) root.notifs.setDnd(!root.dnd); else root.expanded = !root.expanded }
        DotIcon { id: icon; anchors.centerIn: parent; rows: root.dnd ? root.bellOff : root.bell; color: root.ink; opacity: root.dnd ? 0.6 : 1 }
        Rectangle { visible: root.fresh > 0 && !root.dnd; width: 7; height: 7; radius: 3.5; color: "#f3531a"; anchors { right: icon.right; top: icon.top; rightMargin: -1; topMargin: -1 } }
    }

    fullRepresentation: Item {
        id: view
        Layout.preferredWidth: 372; Layout.minimumWidth: 372; Layout.maximumWidth: 372
        Layout.preferredHeight: col.implicitHeight + 28; Layout.minimumHeight: Layout.preferredHeight; Layout.maximumHeight: Layout.preferredHeight
        ColumnLayout {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
            spacing: 12
            RowLayout {
                spacing: 8
                Loader { id: wifi; source: "Wifi.qml"; visible: false }
                Loader { id: bt; source: "Bluetooth.qml"; visible: false }
                Loader { id: night; source: "NightLight.qml"; visible: false; onLoaded: item.setup.connect(() => { root.expanded = false; sh.run("kcmshell6 kcm_nightlight") }) }
                Tile { visible: !!wifi.item && wifi.item.available; Layout.fillWidth: true; Layout.preferredWidth: 1; ink: root.ink; label: "Wi-Fi"; active: !!wifi.item && wifi.item.active; onClicked: wifi.item.toggle()
                    glyph: ["...........", "...#####...", ".##.....##.", "#.........#", "...#####...", "..#.....#..", "...........", "....###....", "...........", ".....#.....", "..........."] }
                Tile { visible: !!bt.item && bt.item.available; Layout.fillWidth: true; Layout.preferredWidth: 1; ink: root.ink; label: "Bluetooth"; active: !!bt.item && bt.item.active; onClicked: bt.item.toggle()
                    glyph: [".....#.....", ".....##....", "..#..#.#...", "...#.#..#..", "....##.#...", ".....##....", "....##.#...", "...#.#..#..", "..#..#.#...", ".....##....", ".....#....."] }
                Tile { visible: !!root.notifs; Layout.fillWidth: true; Layout.preferredWidth: 1; ink: root.ink; label: "Quiet"; active: root.dnd; onClicked: root.notifs.setDnd(!root.dnd); glyph: root.bellOff }
                Tile { visible: !!night.item && night.item.available; Layout.fillWidth: true; Layout.preferredWidth: 1; ink: root.ink; label: "Night"; active: !!night.item && night.item.active; onClicked: night.item.toggle()
                    glyph: ["....###....", "..##.......", ".##........", ".##........", "##.........", "##.........", "##........#", ".##......#.", ".###...##..", "..#######..", "....###...."] }
                Tile { Layout.fillWidth: true; Layout.preferredWidth: 1; ink: root.ink; label: root.dark ? "Dark" : "Light"; active: false; onClicked: root.toggleMode()
                    glyph: ["...#####...", ".##..####..", ".#...#####.", "#....######", "#....######", "#....######", "#....######", "#....######", ".#...#####.", ".##..####..", "...#####..."] }
            }
            ColumnLayout {
                spacing: 6; Layout.fillWidth: true
                Loader { Layout.fillWidth: true; source: "Volume.qml"; visible: status === Loader.Ready && item.available; onLoaded: { item.width = Qt.binding(() => width); item.ink = Qt.binding(() => root.ink) } }
                Loader { Layout.fillWidth: true; source: "Brightness.qml"; visible: status === Loader.Ready && item.available; onLoaded: { item.width = Qt.binding(() => width); item.ink = Qt.binding(() => root.ink) } }
            }
            Accent {
                Layout.fillWidth: true; ink: root.ink
                // Started outside the taskbar, which restarts while the colour changes
                onChosen: c => { root.expanded = false; sh.run("systemd-run --user --collect --quiet \"$HOME/.local/bin/framework-dots-accent\" " + c) }
            }
            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: root.ink; opacity: 0.14 }
            RowLayout {
                PC.Label { text: "Notifications"; opacity: 0.7; Layout.fillWidth: true }
                Text { visible: root.count > 0; text: root.count; font.family: "FD Dots"; font.pointSize: 13; color: root.ink }
                PC.ToolButton { visible: root.count > 0; text: "Clear all"; onClicked: root.notifs.clearAll() }
            }
            ListView {
                id: list
                visible: root.count > 0
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(360, contentHeight)
                clip: true; spacing: 8
                boundsBehavior: Flickable.StopAtBounds
                model: root.notifs ? root.notifs.model : null
                delegate: NotifItem {
                    width: ListView.view.width - (list.contentHeight > list.height ? 14 : 0)
                    ink: root.ink; now: root.notifs ? root.notifs.now : new Date()
                    onClosed: root.notifs.close(index)
                    onOpened: { root.notifs.open(index); root.expanded = false }
                    onActed: name => root.notifs.act(index, name)
                }
                PC.ScrollBar.vertical: PC.ScrollBar { policy: list.contentHeight > list.height ? PC.ScrollBar.AsNeeded : PC.ScrollBar.AlwaysOff }
            }
            ColumnLayout {
                visible: root.count === 0
                Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 10; Layout.bottomMargin: 16; spacing: 12
                DotIcon { rows: root.dnd ? root.bellOff : root.bell; pitch: 4; color: root.ink; opacity: 0.25; Layout.alignment: Qt.AlignHCenter }
                Text { text: !root.notifs || !root.notifs.valid ? "UNAVAILABLE" : root.dnd ? "QUIET" : "ALL CLEAR"; font.family: "FD Dots"; font.pointSize: 14; color: root.ink; opacity: 0.5; Layout.alignment: Qt.AlignHCenter }
            }
        }
    }
}
