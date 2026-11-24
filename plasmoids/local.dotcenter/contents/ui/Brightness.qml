import QtQuick
import org.kde.plasma.private.brightnesscontrolplugin
Column {
    id: col
    property color ink
    spacing: 10
    ScreenBrightnessControl { id: ctl; isSilent: true }
    readonly property bool available: ctl.isBrightnessAvailable
    Repeater {
        model: ctl.displays
        DotSlider {
            required property string displayName
            required property int brightness
            required property int maxBrightness
            width: col.width; ink: col.ink
            glyph: [".....#.....", ".#.......#.", "...........", "....###....", "...#####...", "#..#####..#", "...#####...", "....###....", "...........", ".#.......#.", ".....#....."]
            value: maxBrightness > 0 ? brightness / maxBrightness : 0
            minimum: 0.01
            onMoved: v => ctl.setBrightness(displayName, Math.max(1, Math.round(v * maxBrightness)))
        }
    }
}
