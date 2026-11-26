import QtQuick

// The moving black hole: a tiny picture with one pixel per dot (fed back into itself for the trails), then the dots drawn from it
Item {
    id: root
    property real fps: 30
    property bool running: true
    property real speed: 1
    property color accent: "#f3531a"
    property color hotColor: "#ff8f57"
    property color background: "#090909"
    property string pattern: "blackhole" // or "swirl"
    readonly property bool swirl: pattern === "swirl"
    property real density: swirl ? 180 : 224   // dots across
    property real gain: 2.6
    property real trail: swirl ? 0.71 : 0.7
    property real lightness: 0           // 0 dark, 1 light
    readonly property real dpr: Screen.devicePixelRatio || 1
    readonly property real pitch: Math.max(3, Math.round(width * dpr / density))
    readonly property int gw: Math.ceil(width * dpr / pitch)
    readonly property int gh: Math.ceil(height * dpr / pitch)
    property real time: 3
    property real step: 1 / fps          // real seconds since the last frame

    Timer {
        interval: Math.round(1000 / root.fps); repeat: true; running: root.running && root.visible
        property double last: 0
        onRunningChanged: last = 0
        onTriggered: {
            var n = Date.now(), dt = last ? Math.min(0.1, (n - last) / 1000) : 1 / root.fps; last = n
            root.step = dt; root.time = (root.time + dt * root.speed) % 655.36     // repeats seamlessly, keeps the numbers small
            feedback.scheduleUpdate()                                              // one new frame, only when the timer says so
        }
    }
    ShaderEffect {
        id: field
        width: root.gw; height: root.gh
        property var prev: feedback
        property size grid: Qt.size(root.gw, root.gh)
        property real time: root.time
        property real keep: Math.pow(root.trail, root.step * 9)
        property real inject: Math.max(0.08, 1 - keep) * (root.swirl ? 1.15 : 0.95)
        property real holeSize: root.swirl ? 0.35 : 0.092
        property real bend: 1
        property real ring: 1
        property real stars: 0.5
        property real spread: root.swirl ? 1.3 : 1
        property real flat_: root.swirl ? 0.38 : 0.65
        property real tilt: (root.swirl ? -18 : 12) * Math.PI / 180
        property point centre: root.swirl ? Qt.point(0.27, 0.5) : Qt.point(0.5, 0.52)
        fragmentShader: Qt.resolvedUrl(root.swirl ? "../shaders/swirl.frag.qsb" : "../shaders/field.frag.qsb")
    }
    ShaderEffectSource {
        id: feedback
        sourceItem: field
        hideSource: true
        recursive: true
        live: false
        smooth: false
        format: ShaderEffectSource.RGBA16F
        textureSize: Qt.size(root.gw, root.gh)
        width: 1; height: 1; opacity: 0
    }
    ShaderEffect {
        anchors.fill: parent
        property var field: feedback
        property size grid: Qt.size(root.gw, root.gh)
        property size res: Qt.size(width * root.dpr, height * root.dpr)
        property real pitch: root.pitch
        property real size: Math.min(1, (root.swirl ? 0.9 : 0.5) * (1 + 0.24 * root.lightness))
        property real unlit: Math.min(1, 0.35 + 0.1 * root.lightness)
        property real square: 0
        property real gain: root.gain * (root.swirl ? 1.8 : 1)
        property real fade: root.swirl ? 60 : 1
        property color col: root.accent
        property color hot: root.hotColor
        property color bg: root.background
        fragmentShader: Qt.resolvedUrl("../shaders/dots.frag.qsb")
    }
}
