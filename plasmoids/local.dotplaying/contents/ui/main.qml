import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PC
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris
import QtQuick.Effects

PlasmoidItem {
    id: root
    Mpris.Mpris2Model { id: mpris }
    readonly property var player: mpris.currentPlayer
    readonly property string track: player?.track ?? ""
    readonly property string artist: player?.artist ?? ""
    readonly property string art: String(player?.artUrl ?? "")
    readonly property bool playing: (player?.playbackStatus ?? 0) === Mpris.PlaybackStatus.Playing
    readonly property real length: player?.length ?? 0
    property real pos: 0
    property var levels: [1, 2, 1, 3, 2, 1, 2]
    Plasmoid.status: track !== "" ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.HiddenStatus
    toolTipMainText: track
    toolTipSubText: artist
    onTrackChanged: pos = player?.position ?? 0
    Timer {
        // Decorative: not driven by the actual audio
        interval: 220; repeat: true; running: root.playing
        onTriggered: root.levels = root.levels.map(() => 1 + Math.floor(Math.random() * 5))
    }
    Timer {
        interval: 1000; repeat: true; running: root.expanded && root.track !== ""; triggeredOnStart: true
        onTriggered: { root.player?.updatePosition(); root.pos = root.player?.position ?? 0 }
    }

    component Art: Item {
        id: artItem
        property real radius: 8
        readonly property bool ready: img.status === Image.Ready
        readonly property real ratio: ready && img.implicitHeight > 0 ? img.implicitWidth / img.implicitHeight : 1
        Image {
            id: img
            anchors.fill: parent
            source: root.art
            asynchronous: true
            retainWhileLoading: true
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 640
            layer.enabled: true
            layer.effect: MultiEffect { maskEnabled: true; maskSource: mask; maskThresholdMin: 0.5; maskSpreadAtMin: 1.0 }
        }
        Item {
            id: mask
            anchors.fill: parent
            visible: false
            layer.enabled: true
            Rectangle { anchors.fill: parent; radius: artItem.radius }
        }
    }

    component Vis: Row {
        property real pitch: 4
        spacing: 0
        Repeater {
            model: 7
            Item {
                id: c
                required property int index
                width: pitch; height: pitch * 5
                Repeater {
                    model: 5
                    Rectangle {
                        required property int index
                        readonly property bool on: index >= 5 - (root.playing ? root.levels[c.index] : 1)
                        y: index * pitch; width: pitch * 0.8; height: width; radius: width / 2
                        color: on && root.playing && index === 5 - root.levels[c.index] ? "#f3531a" : Kirigami.Theme.textColor
                        opacity: on ? 1 : 0.18
                    }
                }
            }
        }
    }

    compactRepresentation: MouseArea {
        Layout.minimumWidth: row.implicitWidth + Kirigami.Units.smallSpacing * 2
        Layout.preferredWidth: Layout.minimumWidth
        Layout.maximumWidth: Layout.minimumWidth
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: m => { if (m.button === Qt.MiddleButton) root.player?.PlayPause(); else root.expanded = !root.expanded }
        Row {
            id: row
            visible: root.track !== ""
            anchors.centerIn: parent
            spacing: 8
            Art { visible: ready; width: 22; height: 22; radius: 4; anchors.verticalCenter: parent.verticalCenter }
            Vis { anchors.verticalCenter: parent.verticalCenter }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, 170)
                text: root.track; textFormat: Text.PlainText; elide: Text.ElideRight
                font: Kirigami.Theme.defaultFont; color: Kirigami.Theme.textColor
            }
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
            spacing: 14
            Art {
                id: cover
                visible: ready
                Layout.preferredWidth: ratio > 1.3 ? 270 : 200
                Layout.preferredHeight: ratio > 1.3 ? 152 : 200
                Layout.alignment: Qt.AlignHCenter
            }
            Vis { pitch: cover.ready ? 6 : 14; Layout.alignment: Qt.AlignHCenter }
            PC.Label { text: root.track || "Nothing playing"; textFormat: Text.PlainText; font.bold: true; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter; Layout.preferredWidth: 270 }
            PC.Label { text: root.artist; textFormat: Text.PlainText; opacity: 0.6; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter; Layout.preferredWidth: 270 }
            DotBar { rows: 1; value: root.length > 0 ? root.pos / root.length : 0; Layout.alignment: Qt.AlignHCenter }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                PC.ToolButton { icon.name: "media-skip-backward"; enabled: root.player?.canGoPrevious ?? false; onClicked: root.player.Previous() }
                PC.ToolButton { icon.name: root.playing ? "media-playback-pause" : "media-playback-start"; enabled: root.track !== ""; onClicked: root.player.PlayPause() }
                PC.ToolButton { icon.name: "media-skip-forward"; enabled: root.player?.canGoNext ?? false; onClicked: root.player.Next() }
            }
        }
    }
}
