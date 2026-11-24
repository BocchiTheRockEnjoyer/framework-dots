/*
    SPDX-FileCopyrightText: 2014 Martin Klapetek <mklapetek@kde.org>
    SPDX-FileCopyrightText: 2019 Kai Uwe Broulik <kde@broulik.de>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

RowLayout {
    id: root

    // OSD Timeout in msecs - how long it will stay on the screen
    property int timeout: 1800
    // This is either a text or a number, if showingProgress is set to true,
    // the number will be used as a value for the progress bar
    property var osdValue
    // Maximum percent value
    property int osdMaxValue: 100
    // Additional text if showingProgress is set to true
    property string osdAdditionalText: ""
    // Icon name to display
    property string icon
    // Set to true if the value is meant for progress bar,
    // false for displaying the value as normal text
    property bool showingProgress: false

    function formatPercent(number) {
        return i18nc("Percentage value", "%1%", number);
    }

    spacing: Kirigami.Units.largeSpacing

    Kirigami.Icon {
        id: iconItem
        Layout.leftMargin: Kirigami.Units.smallSpacing // Left end spacing
        Layout.preferredWidth: Kirigami.Units.iconSizes.medium
        Layout.preferredHeight: Kirigami.Units.iconSizes.medium
        Layout.alignment: Qt.AlignVCenter
        source: root.icon + (Application.layoutDirection === Qt.RightToLeft ? "-rtl" : "")
        visible: valid
    }

    ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.topMargin: Kirigami.Units.smallSpacing
        Layout.bottomMargin: Kirigami.Units.smallSpacing
        Layout.alignment: Qt.AlignVCenter

        PlasmaExtras.Heading {
            id: label
            Layout.fillWidth: true
            Layout.leftMargin: iconItem.valid ? 0 : Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing
            level: 3
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            textFormat: Text.PlainText
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
            text: (root.showingProgress ? root.osdAdditionalText : root.osdValue) ?? ""
            visible: text != ""
        }

        RowLayout {
            visible: root.showingProgress
            spacing: Kirigami.Units.smallSpacing

            // Dot-matrix level meter
            Item {
                id: progressBar
                readonly property real value: Number(root.osdValue) || 0
                readonly property int cols: 24
                readonly property int rows: 4
                readonly property real pitch: 8
                readonly property int lit: value <= 0 ? 0 : Math.max(1, Math.round(Math.min(1, value / root.osdMaxValue) * cols))
                Layout.leftMargin: iconItem.valid ? 0 : Kirigami.Units.smallSpacing
                Layout.rightMargin: Kirigami.Units.largeSpacing
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: cols * pitch
                implicitHeight: rows * pitch
                Repeater {
                    model: progressBar.cols * progressBar.rows
                    Rectangle {
                        required property int index
                        readonly property int col: Math.floor(index / progressBar.rows)
                        x: col * progressBar.pitch + 1
                        y: (index % progressBar.rows) * progressBar.pitch + 1
                        width: 6; height: 6; radius: 3
                        antialiasing: true
                        color: col < progressBar.lit && (col === progressBar.lit - 1 || progressBar.value > 100) ? "#f3531a" : Kirigami.Theme.textColor
                        opacity: col < progressBar.lit ? 1 : 0.18
                    }
                }
            }

            // Get the width of a three-digit number so we can size the label
            // to the maximum width to avoid the progress bad resizing itself
            TextMetrics {
                id: widestLabelSize
                text: root.formatPercent(root.osdMaxValue)
                font: percentageLabel.font
            }

            // Numerical display of progress bar value
            PlasmaExtras.Heading {
                id: percentageLabel
                Layout.rightMargin: Kirigami.Units.smallSpacing // Right end spacing
                Layout.fillHeight: true
                Layout.preferredWidth: Math.ceil(widestLabelSize.advanceWidth)
                Layout.alignment: Qt.AlignVCenter
                level: 3
                font.family: "Ndot55Caps"
                font.pointSize: 18
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: root.formatPercent(progressBar.value)
                textFormat: Text.PlainText
                wrapMode: Text.NoWrap
                visible: root.showingProgress
                font.features: Object.assign({}, Kirigami.Theme.defaultFont.features, { "tnum": 1 })
                // Display a subtle visual indication that the volume might be
                // dangerously high
                // ------------------------------------------------
                // Keep this in sync with the copies in plasma-pa:ListItemBase.qml
                // and plasma-pa:VolumeSlider.qml
                color: {
                    if (progressBar.value <= 100) {
                        return Kirigami.Theme.textColor
                    } else if (progressBar.value > 100 && progressBar.value <= 125) {
                        return Kirigami.Theme.neutralTextColor
                    } else {
                        return Kirigami.Theme.negativeTextColor
                    }
                }
            }
        }
    }
}
