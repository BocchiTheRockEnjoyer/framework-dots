import QtQuick
import org.kde.bluezqt as BluezQt
Item {
    readonly property bool available: BluezQt.Manager.adapters.length > 0
    readonly property bool active: BluezQt.Manager.bluetoothOperational
    function toggle() {
        var on = !active
        BluezQt.Manager.bluetoothBlocked = !on
        BluezQt.Manager.adapters.forEach(a => { a.powered = on })
    }
}
