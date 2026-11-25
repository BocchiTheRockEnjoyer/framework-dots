// Based on KWin's Big Icons switcher, SPDX-FileCopyrightText: 2011 Martin Gräßlin <mgraesslin@kde.org>
// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.kwin as KWin

KWin.TabBoxSwitcher {
    id: tabBox
    currentIndex: (instantiator.object as Cards)?.currentIndex ?? currentIndex

    Instantiator { id: instantiator; active: tabBox.visible; delegate: Cards { } }

    component Cards: PlasmaCore.Dialog {
        property alias currentIndex: grid.currentIndex
        location: PlasmaCore.Types.Floating
        visible: tabBox.visible
        flags: Qt.ToolTip | Qt.X11BypassWindowManagerHint
        x: tabBox.screenGeometry.x + (tabBox.screenGeometry.width - box.width) / 2
        y: tabBox.screenGeometry.y + (tabBox.screenGeometry.height - box.height) / 2

        mainItem: Item {
            id: box
            readonly property color ink: Kirigami.Theme.textColor
            readonly property int total: grid.count
            readonly property int cols: Math.max(1, Math.min(total, Math.floor(tabBox.screenGeometry.width * 0.84 / grid.cellWidth)))
            readonly property int rows: Math.max(1, Math.ceil(total / cols))
            width: Math.max(380, cols * grid.cellWidth) + 24
            height: grid.height + foot.height + 34

            GridView {
                id: grid
                anchors { top: parent.top; topMargin: 12; horizontalCenter: parent.horizontalCenter }
                width: box.cols * cellWidth
                height: Math.min(box.rows * cellHeight, Math.floor(tabBox.screenGeometry.height * 0.72 / cellHeight) * cellHeight)
                cellWidth: 236; cellHeight: 178
                clip: true; focus: true
                keyNavigationWraps: true
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: 0
                currentIndex: tabBox.currentIndex
                model: tabBox.model
                delegate: Item {
                    id: card
                    required property var model
                    required property int index
                    readonly property string caption: model.caption
                    readonly property bool on: GridView.isCurrentItem
                    width: grid.cellWidth; height: grid.cellHeight
                    Accessible.name: caption
                    Rectangle {
                        anchors { fill: parent; margins: 5 }
                        radius: 14
                        color: Qt.rgba(box.ink.r, box.ink.g, box.ink.b, card.on ? 0.1 : 0.035)
                        border.width: card.on ? 2 : 1
                        border.color: card.on ? "#f3531a" : Qt.rgba(box.ink.r, box.ink.g, box.ink.b, 0.16)
                    }
                    Item {
                        id: shot
                        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 14 }
                        height: 116
                        opacity: card.on ? 1 : 0.75
                        KWin.WindowThumbnail { anchors.fill: parent; wId: card.model.windowId }
                    }
                    RowLayout {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 16; rightMargin: 16; bottomMargin: 13 }
                        spacing: 7
                        Kirigami.Icon { source: card.model.icon; Layout.preferredWidth: 20; Layout.preferredHeight: 20 }
                        Text { text: card.caption; textFormat: Text.PlainText; elide: Text.ElideRight; Layout.fillWidth: true; font: Kirigami.Theme.smallFont; color: box.ink; opacity: card.on ? 1 : 0.65 }
                        Rectangle { visible: card.on; width: 7; height: 7; radius: 3.5; color: "#f3531a" }
                    }
                    TapHandler { onSingleTapped: { if (card.index === grid.currentIndex) grid.model.activate(card.index); else grid.currentIndex = card.index } onDoubleTapped: grid.model.activate(card.index) }
                }
            }
            Text { anchors.centerIn: grid; visible: grid.count === 0; text: "NO WINDOWS"; font.family: "FD Dots"; font.pointSize: 18; color: box.ink; opacity: 0.5 }
            Column {
                id: foot
                anchors { top: grid.bottom; topMargin: 8; horizontalCenter: parent.horizontalCenter }
                spacing: 9
                Text { anchors.horizontalCenter: parent.horizontalCenter; width: Math.min(implicitWidth, box.width - 40); elide: Text.ElideRight; textFormat: Text.PlainText; text: grid.currentItem ? grid.currentItem.caption : ""; font.family: "FD Dots"; font.capitalization: Font.AllUppercase; font.pointSize: 15; color: box.ink }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 7
                    Repeater { model: Math.min(40, grid.count); Rectangle { required property int index; width: 7; height: 7; radius: 3.5; color: index === grid.currentIndex ? "#f3531a" : box.ink; opacity: index === grid.currentIndex ? 1 : 0.22 } }
                }
            }
            Connections { target: tabBox; function onCurrentIndexChanged() { grid.currentIndex = tabBox.currentIndex } }
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Up) grid.moveCurrentIndexUp()
                else if (event.key === Qt.Key_Down) grid.moveCurrentIndexDown()
                else if (event.key === Qt.Key_Left) grid.moveCurrentIndexLeft()
                else if (event.key === Qt.Key_Right) grid.moveCurrentIndexRight()
            }
        }
        onSceneGraphError: () => { /* otherwise Qt may abort on a graphics reset */ }
    }
}
