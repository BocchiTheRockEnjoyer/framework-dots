import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
KCM.SimpleKCM {
    property alias cfg_use24: h.checked
    property alias cfg_seconds: s.checked
    property alias cfg_grid: g.checked
    property alias cfg_backOpacity: o.value
    Kirigami.FormLayout {
        QQC2.CheckBox { id: h; text: "24-hour time" }
        QQC2.CheckBox { id: s; text: "Seconds track" }
        QQC2.CheckBox { id: g; text: "Show unlit dots" }
        QQC2.SpinBox { id: o; from: 0; to: 100; stepSize: 10; Kirigami.FormData.label: "Background %:" }
    }
}
