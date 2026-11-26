import QtQuick
import QtQuick.Window
Window {
    width: 1440; height: 960; visible: true; color: "black"; visibility: Window.FullScreen
    Loader { id: l; anchors.fill: parent; source: "contents/ui/Dots.qml"; onLoaded: { item.time = Number(Qt.application.arguments[Qt.application.arguments.length - 2]); if (Qt.application.arguments.indexOf("swirl") >= 0) item.pattern = "swirl" } }
    // Click or press any key to close the preview
    MouseArea { anchors.fill: parent; onClicked: Qt.quit() }
    Item { focus: true; Keys.onPressed: Qt.quit() }
    Timer { interval: 2500; running: Qt.application.arguments[Qt.application.arguments.length - 1] !== "run"; onTriggered: l.grabToImage(function (r) { r.saveToFile(Qt.application.arguments[Qt.application.arguments.length - 1]); Qt.quit() }) }
}
