import QtQuick
import org.kde.plasma.private.volume
Item {
    id: vol
    property color ink
    readonly property var sink: PreferredDevice.sink
    readonly property real full: 65536      // PulseAudio's 100%
    implicitHeight: slider.implicitHeight
    readonly property bool available: !!sink
    DotSlider {
        id: slider
        width: vol.width; ink: vol.ink
        faded: !!vol.sink && vol.sink.muted
        glyph: faded ? ["...........", "....#......", "...##......", "#####..#.#.", "#####...#..", "#####..#.#.", "#####......", "...##......", "....#......", "...........", "..........."]
                     : ["...........", "....#......", "...##...#..", "#####.#..#.", "#####..#.#.", "#####..#.#.", "#####.#..#.", "...##...#..", "....#......", "...........", "..........."]
        value: vol.sink ? Math.min(1, vol.sink.volume / vol.full) : 0
        onMoved: v => { if (!vol.sink) return; vol.sink.volume = Math.round(v * vol.full); if (vol.sink.muted && v > 0) vol.sink.muted = false }
        onGlyphClicked: if (vol.sink) vol.sink.muted = !vol.sink.muted
    }
}
