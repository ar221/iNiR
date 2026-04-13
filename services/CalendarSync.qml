pragma Singleton
pragma ComponentBehavior: Bound
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string filePath: Directories.caldavEventsPath
    property var list: []
    property string lastSync: ""
    property int eventCount: 0
    property bool available: list.length > 0

    signal eventsChanged()

    FileView {
        id: caldavFileView
        path: Qt.resolvedUrl(root.filePath)
        watchChanges: true
        onLoaded: {
            const fileContents = caldavFileView.text()
            if (!fileContents || fileContents.trim() === "") {
                root.list = []
                root.eventCount = 0
                root.lastSync = ""
                return
            }
            try {
                const data = JSON.parse(fileContents)
                root.list = data.events || []
                root.eventCount = data.eventCount || 0
                root.lastSync = data.lastSync || ""
                console.log("[CalendarSync] Loaded", root.list.length, "CalDAV events, last sync:", root.lastSync)
                root.eventsChanged()
                retryTimer.stop()
            } catch (e) {
                console.warn("[CalendarSync] Failed to parse file:", e)
                root.list = []
                root.eventCount = 0
            }
        }
        onLoadFailed: (error) => {
            if (error !== FileViewError.FileNotFound) {
                console.warn("[CalendarSync] Error loading file:", error)
            }
            root.list = []
            root.eventCount = 0
            // FileView can't watch a file that doesn't exist yet — retry periodically
            if (!retryTimer.running) retryTimer.start()
        }
    }

    // Poll for file creation when it doesn't exist yet
    Timer {
        id: retryTimer
        interval: 60000
        repeat: true
        onTriggered: caldavFileView.reload()
    }

    function getEventsForDate(date): var {
        const targetDate = new Date(date)
        targetDate.setHours(0, 0, 0, 0)

        return root.list.filter(event => {
            const eventDate = new Date(event.dateTime)
            eventDate.setHours(0, 0, 0, 0)
            return eventDate.getTime() === targetDate.getTime()
        })
    }

    function getUpcomingEvents(days): var {
        const now = new Date()
        const future = new Date()
        future.setDate(future.getDate() + (days || 7))

        return root.list.filter(event => {
            const eventDate = new Date(event.dateTime)
            return eventDate >= now && eventDate <= future
        }).sort((a, b) => new Date(a.dateTime) - new Date(b.dateTime))
    }

    function triggerSync(): void {
        console.log("[CalendarSync] Manual sync triggered")
        Quickshell.execDetached(["/usr/bin/env", "bash", "-c",
            "systemctl --user start calendar-sync.service 2>/dev/null || calendar-sync --no-sync"
        ])
    }
}
