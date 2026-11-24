import QtQuick
import org.kde.plasma.networkmanagement as PlasmaNM
Item {
    readonly property bool available: net.wirelessHwEnabled
    readonly property bool active: net.wirelessEnabled && net.networkingEnabled
    function toggle() { handler.enableWireless(!net.wirelessEnabled) }
    PlasmaNM.EnabledConnections { id: net }
    PlasmaNM.Handler { id: handler }
}
