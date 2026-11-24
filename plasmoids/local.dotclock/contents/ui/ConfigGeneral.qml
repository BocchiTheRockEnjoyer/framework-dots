import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
KCM.SimpleKCM {
    property alias cfg_city: city.text
    property alias cfg_fahrenheit: f.checked
    Kirigami.FormLayout {
        QQC2.TextField { id: city; Kirigami.FormData.label: "City:"; placeholderText: "City name" }
        QQC2.CheckBox { id: f; text: "Use °F" }
        QQC2.Label { text: "Your city is sent to open-meteo.com."; opacity: 0.6 }
    }
}
