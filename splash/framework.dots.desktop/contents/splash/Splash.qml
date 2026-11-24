import QtQuick
import org.kde.kirigami as Kirigami

Rectangle {
    id: root
    color: "#0c0c0c"
    property int stage

    onStageChanged: {
        if (stage == 2) { intro.from = 0; intro.to = 1; intro.restart(); }
        else if (stage == 5) { intro.from = 1; intro.to = 0; intro.restart(); }
    }

    Item {
        id: content
        anchors.fill: parent
        opacity: 0
        Image {
            id: logo
            readonly property real size: Kirigami.Units.gridUnit * 12
            anchors.centerIn: parent
            source: "images/logo.svg"
            sourceSize.width: size
            sourceSize.height: size
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: logo.bottom
            anchors.topMargin: Kirigami.Units.gridUnit * 4
            spacing: 10
            Repeater {
                model: 6
                Rectangle {
                    required property int index
                    width: 8; height: 8; radius: 4
                    color: index < root.stage ? "#f3531a" : "#fcfcfc"
                    opacity: index < root.stage ? 1 : 0.2
                }
            }
        }
    }
    OpacityAnimator { id: intro; target: content; duration: Kirigami.Units.veryLongDuration; easing.type: Easing.InOutQuad }
}
