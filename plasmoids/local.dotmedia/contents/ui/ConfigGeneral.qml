import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
KCM.SimpleKCM {
    property alias cfg_colour: k.checked
    property alias cfg_grid: g.checked
    property alias cfg_backOpacity: o.value
    Kirigami.FormLayout {

        QQC2.CheckBox { id: k; text: "Cover art in colour" }
        QQC2.CheckBox { id: g; text: "Show unlit dots" }
        QQC2.SpinBox { id: o; from: 0; to: 100; stepSize: 10; Kirigami.FormData.label: "Background %:" }
    }
}
