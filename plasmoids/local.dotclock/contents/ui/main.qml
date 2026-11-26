import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PC
import org.kde.kirigami as Kirigami
import org.kde.plasma.workspace.calendar as PlasmaCalendar

PlasmoidItem {
    id: root
    readonly property string city: Plasmoid.configuration.city.trim()
    readonly property bool f: Plasmoid.configuration.fahrenheit
    property var cur: null
    property date now: new Date()
    Timer { interval: 1000; repeat: true; running: true; onTriggered: { var d = new Date(); if (d.getMinutes() !== root.now.getMinutes() || d.getDate() !== root.now.getDate()) root.now = d } }
    property var days: []
    property var hours: []
    property var today: null
    readonly property string windUnit: f ? "mph" : "km/h"
    function words(c) {
        return c === 0 ? "Clear" : c === 1 ? "Mostly clear" : c === 2 ? "Partly cloudy" : c === 3 ? "Overcast" : c <= 48 ? "Fog" : c <= 57 ? "Drizzle"
            : c <= 67 ? "Rain" : c <= 77 ? "Snow" : c <= 82 ? "Showers" : c <= 86 ? "Snow showers" : "Thunderstorm"
    }
    function compass(d) { return ["N", "NE", "E", "SE", "S", "SW", "W", "NW"][Math.round(d / 45) % 8] }
    function clockOf(t) { var h = Number(t.slice(11, 13)), m = Number(t.slice(14, 16)); return new Date(2000, 0, 1, h, m).toLocaleTimeString(Qt.locale(), Locale.ShortFormat) }
    function hourOf(t) { var h = Number(t.slice(11, 13)); return Qt.locale().timeFormat(Locale.ShortFormat).toLowerCase().indexOf("a") >= 0 ? (h % 12 || 12) + (h < 12 ? "a" : "p") : String(h).padStart(2, "0") }
    function uvWord(u) { return u < 3 ? "low" : u < 6 ? "moderate" : u < 8 ? "high" : u < 11 ? "very high" : "extreme" }
    property string place: ""
    property string err: ""
    property int req: 0
    readonly property var icons: ({
        sun: [".....#.....", ".#.......#.", "...........", "....###....", "...#####...", "#..#####..#", "...#####...", "....###....", "...........", ".#.......#.", ".....#....."],
        moon: ["....###....", "..##.......", ".##........", ".##........", "##.........", "##.........", "##........#", ".##......#.", ".###...##..", "..#######..", "....###...."],
        cloud: ["...........", "...........", "....###....", "..##...#...", ".#......##.", "#.........#", "#.........#", ".#########.", "...........", "...........", "..........."],
        rain: ["....###....", "..##...#...", ".#......##.", "#.........#", "#.........#", ".#########.", "...........", "..#..#..#..", ".#..#..#...", "..#..#..#..", ".#..#..#..."],
        snow: [".....#.....", "..#..#..#..", "...#.#.#...", ".#..###..#.", "..##.#.##..", "###########", "..##.#.##..", ".#..###..#.", "...#.#.#...", "..#..#..#..", ".....#....."],
        fog: ["...........", ".#########.", "...........", "#######....", "...........", "..#########", "...........", "########...", "...........", "...#######.", "..........."],
        storm: ["....###....", "..##...#...", ".#......##.", "#.........#", "#.........#", ".#########.", ".....##....", "....##.....", "...#####...", ".....##....", "....##....."] })
    function kind(c, day) { return c <= 1 ? (day === 0 ? "moon" : "sun") : c <= 3 ? "cloud" : c <= 48 ? "fog" : c >= 95 ? "storm" : (c >= 71 && c <= 77) || c === 85 || c === 86 ? "snow" : "rain" }
    function get(url, cb) {
        var x = new XMLHttpRequest(), id = req
        x.onreadystatechange = function() {
            if (x.readyState !== XMLHttpRequest.DONE || id !== root.req) return
            if (x.status !== 200) { root.err = "Weather unavailable"; return }
            try { cb(JSON.parse(x.responseText)) } catch (e) { root.err = "Weather unavailable" }
        }
        x.open("GET", url); x.send()
    }
    function refresh() {
        req++; err = ""
        if (!city) { cur = null; days = []; return }
        get("https://geocoding-api.open-meteo.com/v1/search?count=1&name=" + encodeURIComponent(city), g => {
            if (!g.results || !g.results.length) { root.err = "City not found"; root.cur = null; return }
            var p = g.results[0]; root.place = p.name
            get("https://api.open-meteo.com/v1/forecast?latitude=" + p.latitude + "&longitude=" + p.longitude + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,is_day,wind_speed_10m,wind_direction_10m,surface_pressure&hourly=temperature_2m,weather_code,is_day,precipitation_probability&forecast_hours=13&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max,precipitation_probability_max&forecast_days=5&timezone=auto&temperature_unit=" + (root.f ? "fahrenheit" : "celsius") + "&wind_speed_unit=" + (root.f ? "mph" : "kmh"), w => {
                root.cur = w.current
                root.today = { rise: w.daily.sunrise[0], set: w.daily.sunset[0], uv: w.daily.uv_index_max[0], hi: w.daily.temperature_2m_max[0], lo: w.daily.temperature_2m_min[0], rain: w.daily.precipitation_probability_max[0] }
                root.hours = w.hourly.time.map((t, i) => ({ t: t, c: w.hourly.weather_code[i], d: w.hourly.is_day[i], v: w.hourly.temperature_2m[i], p: w.hourly.precipitation_probability[i] })).filter((x, i) => i % 2 === 0 && i > 0)
                root.days = w.daily.time.map((t, i) => ({ d: t, c: w.daily.weather_code[i], hi: w.daily.temperature_2m_max[i], lo: w.daily.temperature_2m_min[i], p: w.daily.precipitation_probability_max[i] }))
            })
        })
    }
    onCityChanged: refresh()
    onFChanged: refresh()
    Component.onCompleted: refresh()
    Timer { interval: 1800000; repeat: true; running: root.city !== ""; onTriggered: root.refresh() }
    toolTipMainText: Qt.formatDate(now, Qt.locale(), Locale.LongFormat)
    toolTipSubText: cur ? place + "  " + Math.round(cur.temperature_2m) + "°" : ""

    compactRepresentation: MouseArea {
        Layout.minimumWidth: row.implicitWidth + Kirigami.Units.smallSpacing * 2
        Layout.preferredWidth: Layout.minimumWidth
        Layout.maximumWidth: Layout.minimumWidth
        onClicked: root.expanded = !root.expanded
        Text {
            id: row
            anchors.centerIn: parent
            text: root.now.toLocaleDateString(Qt.locale(), Locale.ShortFormat) + "  " + root.now.toLocaleTimeString(Qt.locale(), Locale.ShortFormat)
            font.family: "FD Dots"; font.capitalization: Font.AllUppercase; font.pointSize: 13; color: Kirigami.Theme.textColor
        }
    }
    fullRepresentation: Item {
        Layout.preferredWidth: 820
        Layout.preferredHeight: 580
        Layout.minimumWidth: 800
        Layout.minimumHeight: 580
        RowLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 24
            ColumnLayout {
                Layout.preferredWidth: 340
                Layout.minimumWidth: 340
                Layout.maximumWidth: 340
                Layout.fillHeight: true
                spacing: 12
                PC.Label { text: !root.city ? "Right-click the clock and\nconfigure it to set your city." : root.err || root.place; horizontalAlignment: Text.AlignHCenter; Layout.alignment: Qt.AlignHCenter }
                RowLayout {
                    visible: root.cur !== null
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 18
                    DotIcon { pitch: 6; color: Kirigami.Theme.highlightColor; rows: root.icons[root.cur ? root.kind(root.cur.weather_code, root.cur.is_day) : "cloud"] }
                    ColumnLayout {
                        spacing: 2
                        Text { text: root.cur ? Math.round(root.cur.temperature_2m) + "°" : ""; font.family: "FD Dots"; font.capitalization: Font.AllUppercase; font.pointSize: 42; color: Kirigami.Theme.textColor }
                        PC.Label { text: root.cur ? root.words(root.cur.weather_code) : "" }
                        PC.Label { text: root.cur ? "Feels like " + Math.round(root.cur.apparent_temperature) + "°" : ""; opacity: 0.6; font: Kirigami.Theme.smallFont }
                    }
                }
                Grid {
                    visible: root.cur !== null && root.today !== null
                    Layout.preferredWidth: 340
                    Layout.topMargin: 6
                    columns: 2; rowSpacing: 8
                    Repeater {
                        model: root.cur && root.today ? [
                            ["High / low", Math.round(root.today.hi) + "° / " + Math.round(root.today.lo) + "°"],
                            ["Rain chance", (root.today.rain ?? 0) + "%"],
                            ["Humidity", Math.round(root.cur.relative_humidity_2m) + "%"],
                            ["Wind", Math.round(root.cur.wind_speed_10m) + " " + root.windUnit + " " + root.compass(root.cur.wind_direction_10m)],
                            ["UV", Math.round(root.today.uv) + " " + root.uvWord(root.today.uv)],
                            ["Pressure", Math.round(root.cur.surface_pressure) + " hPa"],
                            ["Sunrise", root.clockOf(root.today.rise)],
                            ["Sunset", root.clockOf(root.today.set)]] : []
                        ColumnLayout {
                            required property var modelData
                            spacing: 0
                            width: 170
                            PC.Label { Layout.leftMargin: 24; text: modelData[0]; opacity: 0.6; font: Kirigami.Theme.smallFont }
                            PC.Label { Layout.leftMargin: 24; text: modelData[1] }
                        }
                    }
                }
                Item { Layout.fillHeight: true }
                Row {
                    Layout.preferredWidth: 340
                    Repeater {
                        model: root.hours
                        ColumnLayout {
                            required property var modelData
                            width: 340 / 6
                            spacing: 4
                            PC.Label { text: root.hourOf(modelData.t); opacity: 0.6; font: Kirigami.Theme.smallFont; Layout.alignment: Qt.AlignHCenter }
                            DotIcon { rows: root.icons[root.kind(modelData.c, modelData.d)]; Layout.alignment: Qt.AlignHCenter }
                            PC.Label { text: Math.round(modelData.v) + "°"; Layout.alignment: Qt.AlignHCenter }
                            PC.Label { text: (modelData.p ?? 0) + "%"; color: (modelData.p ?? 0) >= 50 ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor; opacity: (modelData.p ?? 0) >= 50 ? 1 : 0.5; font: Kirigami.Theme.smallFont; Layout.alignment: Qt.AlignHCenter }
                        }
                    }
                }
                Rectangle { visible: root.days.length > 0; Layout.fillWidth: true; implicitHeight: 1; color: Kirigami.Theme.textColor; opacity: 0.12 }
                Row {
                    Layout.preferredWidth: 340
                    Repeater {
                        model: root.days
                        ColumnLayout {
                            required property var modelData
                            width: 340 / 5
                            spacing: 4
                            PC.Label { text: Qt.formatDate(new Date(modelData.d + "T12:00:00"), "ddd"); opacity: 0.6; font: Kirigami.Theme.smallFont; Layout.alignment: Qt.AlignHCenter }
                            DotIcon { rows: root.icons[root.kind(modelData.c, 1)]; Layout.alignment: Qt.AlignHCenter }
                            PC.Label { text: Math.round(modelData.hi) + "°"; Layout.alignment: Qt.AlignHCenter }
                            PC.Label { text: Math.round(modelData.lo) + "°"; opacity: 0.6; Layout.alignment: Qt.AlignHCenter }
                            PC.Label { text: (modelData.p ?? 0) + "%"; color: (modelData.p ?? 0) >= 50 ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor; opacity: (modelData.p ?? 0) >= 50 ? 1 : 0.5; font: Kirigami.Theme.smallFont; Layout.alignment: Qt.AlignHCenter }
                        }
                    }
                }
            }
            Rectangle { Layout.fillHeight: true; implicitWidth: 1; color: Kirigami.Theme.textColor; opacity: 0.12 }
            PlasmaCalendar.MonthView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                today: root.now
                borderOpacity: 0.12
                firstDayOfWeek: Qt.locale().firstDayOfWeek
                eventPluginsManager: PlasmaCalendar.EventPluginsManager {}
            }
        }
    }
}
