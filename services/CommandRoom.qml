pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string sourcePath: Directories.statePath + "/command-room/cockpit.json"
    property bool available: false
    property string lastError: ""
    property string generatedAt: ""
    property var openTasks: []
    property int openTaskCount: openTasks.length
    property int ageMinutes: {
        void ageTicker.tick
        if (!generatedAt || generatedAt.length === 0)
            return -1

        const generatedMs = Date.parse(generatedAt)
        if (!Number.isFinite(generatedMs))
            return -1

        return Math.max(0, Math.floor((Date.now() - generatedMs) / 60000))
    }
    property string freshnessState: {
        void ageTicker.tick
        if (lastError.length > 0)
            return lastError === "Projection missing" ? "missing" : "error"
        if (!available)
            return "missing"
        return ageMinutes >= 0 && ageMinutes < 30 ? "fresh" : "stale"
    }

    function refresh() {
        projectionFile.reload()
    }

    function _reset(message) {
        available = false
        lastError = message
        generatedAt = ""
        openTasks = []
    }

    function _readArray(value) {
        return Array.isArray(value) ? value : []
    }

    function _parseProjection(text) {
        if (!text || text.trim().length === 0) {
            _reset("Projection empty")
            return
        }

        try {
            const envelope = JSON.parse(text)
            const data = envelope?.data ?? envelope ?? {}
            generatedAt = String(data.generated_at ?? envelope?.generated_at ?? "")
            openTasks = _readArray(data.open_tasks ?? data.openTasks)
            lastError = ""
            available = true
            retryTimer.stop()
        } catch (e) {
            _reset("Parse error: " + e)
        }
    }

    FileView {
        id: projectionFile
        path: Qt.resolvedUrl("file://" + root.sourcePath)
        watchChanges: true
        onLoaded: root._parseProjection(projectionFile.text())
        onLoadFailed: (error) => {
            if (error === FileViewError.FileNotFound) {
                root._reset("Projection missing")
            } else {
                root._reset("Load error: " + error)
            }
            if (!retryTimer.running)
                retryTimer.start()
        }
    }

    Timer {
        id: retryTimer
        interval: 60000
        repeat: true
        onTriggered: projectionFile.reload()
    }

    Timer {
        id: ageTicker
        property int tick: 0
        interval: 60000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: tick++
    }
}
