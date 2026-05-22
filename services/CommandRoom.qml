pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string primaryPath: Directories.homePath + "/Documents/Ayaz OS/06 System/projections/inir-cards.json"
    property string legacyPath: Directories.homePath + "/.local/state/command-room/cockpit.json"
    property string sourcePath: primaryPath
    property bool usingFallback: false
    property bool available: false
    property string lastError: ""
    property string generatedAt: ""
    property var cards: []
    property var inirCounts: ({})
    property var openTasks: []
    property var observability: ({})
    property var anomalies: []
    property int openTaskCount: Number(inirCounts?.open_tasks ?? openTasks.length)
    property int runningRunCount: Number(inirCounts?.running_runs ?? observability?.running_runs ?? 0)
    property int staleRunCount: Number(inirCounts?.stale_runs ?? observability?.stale_runs ?? 0)
    property int pendingApprovalCount: Number(inirCounts?.pending_approvals ?? observability?.pending_approvals ?? 0)
    property int queuedDeliveryCount: Number(inirCounts?.queued_deliveries ?? observability?.queued_deliveries ?? 0)
    property int pendingMemoryWriteCount: Number(inirCounts?.pending_memory_writes ?? observability?.pending_memory_writes ?? 0)
    property int anomalyCount: Number(inirCounts?.anomalies ?? anomalies.length)
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
        primaryProjectionFile.reload()
        if (usingFallback)
            legacyProjectionFile.reload()
    }

    function _reset(message) {
        available = false
        lastError = message
        generatedAt = ""
        cards = []
        inirCounts = ({})
        openTasks = []
        observability = ({})
        anomalies = []
    }

    function _readArray(value) {
        return Array.isArray(value) ? value : []
    }

    function _readObject(value) {
        return value && typeof value === "object" && !Array.isArray(value) ? value : ({})
    }

    function _parseInirCards(envelope) {
        const counts = _readObject(envelope?.counts)
        sourcePath = primaryPath
        usingFallback = false
        generatedAt = String(envelope?.generated_at ?? "")
        cards = _readArray(envelope?.cards)
        inirCounts = counts
        openTasks = []
        observability = ({
            running_runs: Number(counts?.running_runs ?? 0),
            stale_runs: Number(counts?.stale_runs ?? 0),
            pending_approvals: Number(counts?.pending_approvals ?? 0),
            queued_deliveries: Number(counts?.queued_deliveries ?? 0),
            pending_memory_writes: Number(counts?.pending_memory_writes ?? 0),
            anomaly_count: Number(counts?.anomalies ?? 0)
        })
        anomalies = []
        lastError = ""
        available = true
        retryTimer.stop()
    }

    function _parseLegacyProjection(envelope) {
        const data = envelope?.data ?? envelope ?? {}
        const obs = _readObject(envelope?.observability ?? data?.observability)
        sourcePath = legacyPath
        usingFallback = true
        generatedAt = String(data.generated_at ?? envelope?.generated_at ?? "")
        cards = []
        inirCounts = ({})
        openTasks = _readArray(data.open_tasks ?? data.openTasks)
        observability = obs
        anomalies = _readArray(obs.anomalies)
        lastError = ""
        available = true
        retryTimer.stop()
    }

    function _parseProjection(text, legacy) {
        if (!text || text.trim().length === 0) {
            _reset("Projection empty")
            return
        }

        try {
            const envelope = JSON.parse(text)
            if (!legacy && envelope?.schema_version === "inir-cards/v1")
                _parseInirCards(envelope)
            else
                _parseLegacyProjection(envelope)
        } catch (e) {
            _reset("Parse error: " + e)
            if (!legacy)
                legacyProjectionFile.reload()
        }
    }

    FileView {
        id: primaryProjectionFile
        path: Qt.resolvedUrl("file://" + encodeURI(root.primaryPath))
        watchChanges: true
        onLoaded: root._parseProjection(primaryProjectionFile.text(), false)
        onLoadFailed: (error) => {
            if (error === FileViewError.FileNotFound) {
                legacyProjectionFile.reload()
            } else {
                root._reset("Load error: " + error)
                legacyProjectionFile.reload()
            }
            if (!retryTimer.running)
                retryTimer.start()
        }
    }

    FileView {
        id: legacyProjectionFile
        path: Qt.resolvedUrl("file://" + encodeURI(root.legacyPath))
        watchChanges: true
        onLoaded: {
            if (!root.available || root.usingFallback)
                root._parseProjection(legacyProjectionFile.text(), true)
        }
        onLoadFailed: (error) => {
            if (!root.available || root.usingFallback) {
                if (error === FileViewError.FileNotFound)
                    root._reset("Projection missing")
                else
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
        onTriggered: root.refresh()
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
