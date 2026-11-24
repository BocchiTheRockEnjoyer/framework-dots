import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.private.kicker as Kicker

Kicker.DashboardWindow {
    id: dash
    required property var rootModel
    required property var runnerModel
    required property var systemModel
    required property var owner
    signal done()
    readonly property bool searching: field.text !== ""
    readonly property var favs: rootModel.favoritesModel
    property var groups: []             // [{ name, model }]
    property int group: 0
    readonly property var current: searching ? (runnerModel.count > 0 ? runnerModel.modelForRow(0) : null) : (groups[group] ? groups[group].model : null)
    keyEventProxy: field
    backgroundColor: "transparent"

    function rebuild() {
        var g = [], keep = groups[group] ? groups[group].name : ""
        if (favs && favs.count > 0) g.push({ name: "Favorites", model: favs })
        for (var i = 0; i < rootModel.count; i++) {
            var m = rootModel.modelForRow(i); var n = rootModel.labelForRow(i)
            if (m && m.count > 0 && n) g.push({ name: i === 0 ? "All" : n, model: m })
        }
        groups = g
        var k = g.findIndex(x => x.name === keep)
        group = k >= 0 ? k : 0
    }
    function reset() { field.clear(); group = Math.max(0, groups.findIndex(x => x.name === "All")); grid.currentIndex = -1; grid.positionViewAtBeginning(); field.forceActiveFocus(Qt.OtherFocusReason) }
    function run(i) { if (current && i >= 0 && i < current.count) { current.trigger(i, "", null); done() } }
    function pick(i) { if (groups.length) { group = (i + groups.length) % groups.length; field.clear(); grid.currentIndex = -1; grid.positionViewAtBeginning(); pills.positionViewAtIndex(group, ListView.Contain) } }

    onKeyEscapePressed: searching ? field.clear() : done()
    onActiveChanged: if (!active && visible) done()
    onVisibleChanged: if (visible) { rootModel.refresh(); rebuild(); reset(); view.opacity = 0; view.scale = 0.985; appear.restart() }
    onSearchingChanged: { grid.currentIndex = -1; grid.positionViewAtBeginning() }

    mainItem: MouseArea {
        id: page
        anchors.fill: parent
        Kirigami.Theme.colorSet: Kirigami.Theme.Window
        Kirigami.Theme.inherit: false
        readonly property color ink: Kirigami.Theme.textColor
        readonly property bool dark: { var b = Kirigami.Theme.backgroundColor; return 0.299 * b.r + 0.587 * b.g + 0.114 * b.b < 0.5 }
        onClicked: dash.done()
        Connections { target: dash.owner; function onRefreshed() { dash.rebuild() } }
        Connections { target: dash.favs; function onCountChanged() { Qt.callLater(dash.rebuild) } }

        Rectangle { anchors.fill: parent; color: page.dark ? "#0c0c0c" : "#f2f2f2"; opacity: 0.94 }
        Canvas {
            id: dots
            anchors.fill: parent
            property bool dark: page.dark
            onDarkChanged: requestPaint()
            onPaint: {
                var c = getContext("2d"), p = 16; c.reset()
                c.fillStyle = dark ? "rgba(255,255,255,0.055)" : "rgba(0,0,0,0.075)"
                c.beginPath()
                for (var y = p / 2; y < height; y += p) for (var x = p / 2; x < width; x += p) { c.moveTo(x + 1.6, y); c.arc(x, y, 1.6, 0, 6.2832) }
                c.fill()
            }
        }

        Item {
            id: view
            anchors.fill: parent
            transformOrigin: Item.Center
            ParallelAnimation { id: appear; NumberAnimation { target: view; property: "opacity"; to: 1; duration: 140 } NumberAnimation { target: view; property: "scale"; to: 1; duration: 180; easing.type: Easing.OutCubic } }

            // Search
            Item {
                id: search
                anchors { top: parent.top; topMargin: Math.max(48, parent.height * 0.07); horizontalCenter: parent.horizontalCenter }
                width: Math.min(760, parent.width * 0.6); height: 64
                Text { anchors.centerIn: parent; visible: !dash.searching; text: "SEARCH"; font.family: "FD Dots"; font.pointSize: 30; color: page.ink; opacity: 0.28 }
                TextInput {
                    id: field
                    anchors.fill: parent
                    horizontalAlignment: TextInput.AlignHCenter; verticalAlignment: TextInput.AlignVCenter
                    font.family: "FD Dots"; font.capitalization: Font.AllUppercase; font.pointSize: 30
                    color: page.ink; selectionColor: "#f3531a"; selectedTextColor: "#141414"
                    clip: true; maximumLength: 80
                    Accessible.role: Accessible.EditableText; Accessible.name: "Search apps"
                    cursorDelegate: Item {
                        Column { anchors.verticalCenter: parent.verticalCenter; x: 2; spacing: 2; visible: dash.searching
                            Repeater { model: 5; Rectangle { width: 5; height: 5; radius: 2.5; color: "#f3531a" } }
                            SequentialAnimation on opacity { loops: Animation.Infinite; running: dash.visible && dash.searching; PauseAnimation { duration: 500 } NumberAnimation { to: 0; duration: 60 } PauseAnimation { duration: 400 } NumberAnimation { to: 1; duration: 60 } } }
                    }
                    onTextChanged: dash.runnerModel.query = text
                    Keys.onPressed: e => {
                        var n = grid.count, c = grid.currentIndex, inGrid = c >= 0
                        e.accepted = true
                        if (e.key === Qt.Key_Down) grid.currentIndex = !inGrid ? (n ? 0 : -1) : Math.min(n - 1, c + grid.cols)
                        else if (e.key === Qt.Key_Up) grid.currentIndex = c - grid.cols
                        else if (e.key === Qt.Key_Right && (inGrid || !dash.searching)) grid.currentIndex = Math.min(n - 1, c + 1)
                        else if (e.key === Qt.Key_Left && (inGrid || !dash.searching)) grid.currentIndex = Math.max(-1, c - 1)
                        else if (e.key === Qt.Key_PageDown) grid.currentIndex = Math.min(n - 1, Math.max(0, c) + grid.cols * grid.rowsShown)
                        else if (e.key === Qt.Key_PageUp) grid.currentIndex = Math.max(0, c - grid.cols * grid.rowsShown)
                        else if (e.key === Qt.Key_Tab) dash.pick(dash.group + 1)
                        else if (e.key === Qt.Key_Backtab) dash.pick(dash.group - 1)
                        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) dash.run(inGrid ? c : dash.searching ? 0 : -1)
                        else { e.accepted = false; return }
                        if (grid.currentIndex < -1) grid.currentIndex = -1
                    }
                }
                Row { anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter } spacing: 6
                    Repeater { model: Math.floor(search.width / 10); Rectangle { required property int index; width: 4; height: 4; radius: 2; color: dash.searching ? "#f3531a" : page.ink; opacity: dash.searching ? 1 : 0.22 } } }
            }

            // Categories
            ListView {
                id: pills
                anchors { top: search.bottom; topMargin: 20; horizontalCenter: parent.horizontalCenter }
                width: Math.min(contentWidth, parent.width * 0.86); height: 34
                orientation: ListView.Horizontal; spacing: 8; clip: true
                boundsBehavior: Flickable.StopAtBounds
                opacity: dash.searching ? 0.35 : 1
                model: dash.groups
                delegate: Rectangle {
                    id: pill
                    required property var modelData
                    required property int index
                    readonly property bool on: index === dash.group && !dash.searching
                    width: name.implicitWidth + 26; height: 34; radius: 17
                    color: on ? "#f3531a" : Qt.rgba(page.ink.r, page.ink.g, page.ink.b, over.containsMouse ? 0.14 : 0.06)
                    border.width: 1; border.color: Qt.rgba(page.ink.r, page.ink.g, page.ink.b, on ? 0 : 0.18)
                    Accessible.role: Accessible.PageTab; Accessible.name: modelData.name; Accessible.onPressAction: dash.pick(index)
                    PC.Label { id: name; anchors.centerIn: parent; text: pill.modelData.name; textFormat: Text.PlainText; color: pill.on ? "#141414" : page.ink }
                    MouseArea { id: over; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: dash.pick(pill.index) }
                }
            }

            // Apps
            GridView {
                id: grid
                readonly property int cols: Math.max(3, Math.min(9, Math.floor(view.width * 0.84 / 140)))
                readonly property int rowsShown: Math.max(1, Math.floor(height / cellHeight))
                anchors { top: pills.bottom; topMargin: 26; bottom: power.top; bottomMargin: 20; horizontalCenter: parent.horizontalCenter }
                width: cols * cellWidth
                cellWidth: 140; cellHeight: 138
                clip: true; cacheBuffer: 600
                boundsBehavior: Flickable.StopAtBounds
                keyNavigationEnabled: false
                currentIndex: -1
                highlightFollowsCurrentItem: true; highlightMoveDuration: 0
                highlight: Item {}
                model: dash.current
                onModelChanged: currentIndex = -1
                delegate: Item {
                    id: app
                    required property var model
                    required property int index
                    readonly property bool on: GridView.isCurrentItem || (dash.searching && grid.currentIndex < 0 && index === 0)
                    width: grid.cellWidth; height: grid.cellHeight
                    Accessible.role: Accessible.Button; Accessible.name: model.display || ""; Accessible.onPressAction: dash.run(index)
                    Rectangle {
                        anchors { fill: parent; margins: 5 }
                        radius: 16
                        color: Qt.rgba(page.ink.r, page.ink.g, page.ink.b, app.on || hover.containsMouse ? 0.08 : 0)
                        border.width: 1; border.color: Qt.rgba(page.ink.r, page.ink.g, page.ink.b, app.on ? 0.34 : hover.containsMouse ? 0.18 : 0)
                    }
                    Kirigami.Icon { id: ic; anchors { top: parent.top; topMargin: 18; horizontalCenter: parent.horizontalCenter } width: 56; height: 56; source: app.model.decoration; animated: false; scale: hover.pressed ? 0.92 : 1 }
                    PC.Label { anchors { top: ic.bottom; topMargin: 8; left: parent.left; right: parent.right; margins: 12 } text: app.model.display || ""; textFormat: Text.PlainText; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight; font: Kirigami.Theme.smallFont; color: page.ink }
                    Rectangle { anchors { bottom: parent.bottom; bottomMargin: 9; horizontalCenter: parent.horizontalCenter } width: 6; height: 6; radius: 3; color: "#f3531a"; visible: app.on }
                    MouseArea {
                        id: hover
                        anchors.fill: parent
                        hoverEnabled: true; acceptedButtons: Qt.LeftButton | Qt.RightButton; cursorShape: Qt.PointingHandCursor
                        onClicked: m => { if (m.button === Qt.LeftButton) return dash.run(app.index)
                            menu.fid = app.model.favoriteId || ""; if (menu.fid && dash.favs) { menu.visualParent = app; menu.isFav = dash.favs.isFavorite(menu.fid); menu.open(m.x, m.y) } }
                    }
                }
            }
            // Where you are, as dots
            Column {
                anchors { left: grid.right; leftMargin: 18; verticalCenter: grid.verticalCenter }
                readonly property int pages: Math.min(20, Math.ceil(grid.contentHeight / Math.max(1, grid.height)))
                readonly property int at: grid.atYEnd ? pages - 1 : Math.min(pages - 1, Math.floor((grid.contentY - grid.originY) / Math.max(1, grid.height) + 0.25))
                id: where
                visible: pages > 1; spacing: 9
                Repeater { model: where.pages; Rectangle { required property int index; width: 8; height: 8; radius: 4; color: index === where.at ? "#f3531a" : page.ink; opacity: index === where.at ? 1 : 0.25
                    MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: grid.contentY = grid.originY + Math.min(index * grid.height, Math.max(0, grid.contentHeight - grid.height)) } } }
            }
            Column {
                anchors.centerIn: grid
                visible: dash.searching && grid.count === 0 && !dash.runnerModel.querying
                spacing: 14
                DotIcon { anchors.horizontalCenter: parent.horizontalCenter; pitch: 5; color: page.ink; opacity: 0.3
                    rows: ["..#####....", ".#.....#...", "#.......#..", "#.......#..", "#.......#..", "#.......#..", ".#.....#...", "..#####.#..", "........##.", ".........##", "..........#"] }
                Text { text: "NOTHING FOUND"; font.family: "FD Dots"; font.pointSize: 16; color: page.ink; opacity: 0.5 }
            }

            // Power
            Row {
                id: power
                anchors { bottom: parent.bottom; bottomMargin: Math.max(26, parent.height * 0.035); horizontalCenter: parent.horizontalCenter }
                spacing: 14
                Repeater {
                    model: dash.systemModel
                    Rectangle {
                        id: act
                        required property var model
                        required property int index
                        width: 46; height: 46; radius: 23
                        color: Qt.rgba(page.ink.r, page.ink.g, page.ink.b, am.containsMouse ? 0.14 : 0.06)
                        border.width: 1; border.color: am.containsMouse ? "#f3531a" : Qt.rgba(page.ink.r, page.ink.g, page.ink.b, 0.18)
                        Accessible.role: Accessible.Button; Accessible.name: model.display || ""; Accessible.onPressAction: { dash.systemModel.trigger(index, "", null); dash.done() }
                        Kirigami.Icon { anchors.centerIn: parent; width: 22; height: 22; source: act.model.decoration; isMask: true; color: am.containsMouse ? "#f3531a" : page.ink }
                        PC.Label { anchors { bottom: parent.top; bottomMargin: 5; horizontalCenter: parent.horizontalCenter } visible: am.containsMouse; text: act.model.display || ""; textFormat: Text.PlainText; font: Kirigami.Theme.smallFont; color: page.ink }
                        MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { dash.systemModel.trigger(act.index, "", null); dash.done() } }
                    }
                }
            }
        }
        PlasmaExtras.Menu {
            id: menu
            property string fid: ""
            property bool isFav: false
            PlasmaExtras.MenuItem { text: menu.isFav ? "Remove from favorites" : "Add to favorites"; icon: "emblem-favorite-symbolic"; onClicked: menu.isFav ? dash.favs.removeFavorite(menu.fid) : dash.favs.addFavorite(menu.fid) }
        }
    }
}
