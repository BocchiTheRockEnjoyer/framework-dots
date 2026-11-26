import QtQuick
import org.kde.taskmanager as TaskManager
import org.kde.kwindowsystem

// Whether this screen's desktop is hidden: by a maximised or full-screen window, or by windows side by side
Item {
    id: cv
    property rect screen
    readonly property bool covered: _covered && !KWindowSystem.showingDesktop
    property bool _covered: false

    TaskManager.ActivityInfo { id: activityInfo }
    TaskManager.VirtualDesktopInfo { id: desktopInfo }
    TaskManager.TasksModel {
        id: tasks
        groupMode: TaskManager.TasksModel.GroupDisabled
        filterByVirtualDesktop: true
        virtualDesktop: desktopInfo.currentDesktop
        filterByActivity: true
        activity: activityInfo.currentActivity
        filterByScreen: true
        screenGeometry: cv.screen
        filterMinimized: true
        onDataChanged: later.restart()
        onCountChanged: later.restart()
    }
    // Windows move in many small steps: look again once they've settled
    Timer { id: later; interval: 300; onTriggered: cv.check() }
    onScreenChanged: later.restart()
    Component.onCompleted: later.restart()

    function role(i, name) { return tasks.data(tasks.makeModelIndex(i), TaskManager.AbstractTasksModel[name]) }
    function check() {
        var s = cv.screen, rects = []
        if (s.width <= 0) { _covered = false; return }
        for (var i = 0; i < tasks.count; i++) {
            if (role(i, "IsWindow") !== true || role(i, "IsMinimized") === true) continue
            if (role(i, "IsFullScreen") === true || role(i, "IsMaximized") === true) { _covered = true; return }
            var g = role(i, "Geometry")
            if (g && g.width > 0) rects.push(g)
        }
        // Side by side: check a grid of points, and count the desktop as hidden when almost none show through
        var seen = 0, total = 0
        for (var y = 0; y < 12; y++) for (var x = 0; x < 16; x++) {
            var px = s.x + (x + 0.5) * s.width / 16, py = s.y + (y + 0.5) * s.height / 12, hit = false
            for (var k = 0; k < rects.length && !hit; k++) { var r = rects[k]; hit = px >= r.x && px < r.x + r.width && py >= r.y && py < r.y + r.height }
            total++; if (!hit) seen++
        }
        _covered = rects.length > 0 && seen / total < 0.08
    }
}
