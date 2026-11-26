import QtQuick
import org.kde.plasma.plasma5support as P5Support

// True while running on battery (no charger plugged in)
Item {
    readonly property bool onBattery: src.data["AC Adapter"] ? src.data["AC Adapter"]["Plugged in"] === false : false
    P5Support.DataSource { id: src; engine: "powermanagement"; connectedSources: ["AC Adapter"] }
}
