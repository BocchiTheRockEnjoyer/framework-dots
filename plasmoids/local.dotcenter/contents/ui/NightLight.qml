import QtQuick
import org.kde.plasma.private.brightnesscontrolplugin
import org.kde.plasma.workspace.dbus as DBus
Item {
    signal setup()
    readonly property bool available: Boolean(night.properties.available)
    readonly property bool enabledInSettings: Boolean(night.properties.enabled)
    readonly property bool active: enabledInSettings && !Boolean(night.properties.inhibited)
    function toggle() { if (enabledInSettings) NightLightInhibitor.toggleInhibition(); else setup() }
    DBus.Properties {
        id: night
        busType: DBus.BusType.Session
        service: "org.kde.KWin.NightLight"; path: "/org/kde/KWin/NightLight"; iface: "org.kde.KWin.NightLight"
    }
}
