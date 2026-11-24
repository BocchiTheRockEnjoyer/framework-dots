import QtQuick
import org.kde.notificationmanager as NM
Item {
    readonly property bool valid: NM.Server.valid
    readonly property alias model: history
    readonly property int count: history.count
    readonly property int unread: history.unreadNotificationsCount
    property date now: new Date()
    readonly property bool dnd: { var t = settings.notificationsInhibitedUntil; return !!t && !isNaN(t.getTime()) && t.getTime() > now.getTime() }
    function setDnd(on) {
        if (on) { var d = new Date(); d.setFullYear(d.getFullYear() + 1); settings.notificationsInhibitedUntil = d }
        else { settings.notificationsInhibitedUntil = undefined; settings.revokeApplicationInhibitions(); settings.fullscreenFocused = false; settings.screensMirrored = false }
        settings.save(); now = new Date()
    }
    function clearAll() { for (var i = history.count - 1; i >= 0; i--) close(i) }
    function close(i) { history.close(history.index(i, 0)) }
    function open(i) { history.invokeDefaultAction(history.index(i, 0), NM.Notifications.None) }
    function act(i, name) { history.invokeAction(history.index(i, 0), name, NM.Notifications.None) }
    Timer { interval: 30000; repeat: true; running: true; onTriggered: now = new Date() }
    NM.Settings { id: settings; live: true; onNotificationsInhibitedUntilChanged: now = new Date() }
    NM.Notifications {
        id: history
        showExpired: true; showDismissed: true; showJobs: false
        sortMode: NM.Notifications.SortByDate
        groupMode: NM.Notifications.GroupDisabled
        blacklistedDesktopEntries: settings.historyBlacklistedApplications
        blacklistedNotifyRcNames: settings.historyBlacklistedServices
        urgencies: NM.Notifications.CriticalUrgency | NM.Notifications.NormalUrgency | (settings.lowPriorityHistory ? NM.Notifications.LowUrgency : 0)
    }
}
