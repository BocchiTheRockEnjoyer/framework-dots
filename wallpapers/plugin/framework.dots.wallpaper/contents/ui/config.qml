import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page
    property string cfg_Pattern
    property string cfg_PatternDefault
    property alias cfg_Speed: speed.value
    property alias cfg_Brightness: bright.value
    property alias cfg_Fps: fps.value
    property alias cfg_PauseCovered: covered.checked
    property alias cfg_PauseBattery: battery.checked
    property alias cfg_FollowMode: follow.checked
    property int cfg_SpeedDefault; property int cfg_BrightnessDefault; property int cfg_FpsDefault
    property bool cfg_PauseCoveredDefault; property bool cfg_PauseBatteryDefault; property bool cfg_FollowModeDefault

    QQC2.ComboBox {
        Kirigami.FormData.label: "Pattern:"
        textRole: "text"; valueRole: "value"
        model: [{ text: "Black hole", value: "blackhole" }, { text: "Swirl", value: "swirl" }]
        Component.onCompleted: currentIndex = Math.max(0, indexOfValue(page.cfg_Pattern))
        onActivated: page.cfg_Pattern = currentValue
    }
    RowLayout { Kirigami.FormData.label: "Speed:"; QQC2.Slider { id: speed; from: 25; to: 200; stepSize: 5; Layout.preferredWidth: Kirigami.Units.gridUnit * 12 } QQC2.Label { text: speed.value + "%" } }
    RowLayout { Kirigami.FormData.label: "Brightness:"; QQC2.Slider { id: bright; from: 40; to: 160; stepSize: 5; Layout.preferredWidth: Kirigami.Units.gridUnit * 12 } QQC2.Label { text: bright.value + "%" } }
    QQC2.SpinBox { id: fps; Kirigami.FormData.label: "Frames per second:"; from: 10; to: 60 }
    QQC2.CheckBox { id: covered; Kirigami.FormData.label: "Pause:"; text: "When windows cover the desktop (maximised, full screen or side by side)" }
    QQC2.CheckBox { id: battery; text: "On battery" }
    QQC2.CheckBox { id: follow; Kirigami.FormData.label: "Colours:"; text: "Follow light and dark mode" }
    QQC2.Label { text: "The dots use your accent colour."; opacity: 0.7 }
}
