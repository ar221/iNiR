pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

/**
 * Network usage service — polls /proc/net/dev for RX/TX byte counters,
 * computes per-second speed deltas, and maintains normalized history
 * arrays for sparkline visualization.
 */
Singleton {
    id: root

    property real downloadSpeed: 0       // bytes per second
    property real uploadSpeed: 0         // bytes per second
    property string downloadSpeedStr: "" // human readable
    property string uploadSpeedStr: ""   // human readable
    property real downloadTotal: 0       // session total bytes
    property real uploadTotal: 0         // session total bytes
    property list<real> downloadHistory: []  // last 60 speed samples (normalized 0-1)
    property list<real> uploadHistory: []    // last 60 speed samples (normalized 0-1)
    property real maxSpeed: 1            // max speed seen (for normalization)

    readonly property int historyLength: Config.options?.network?.historyLength ?? 60

    property real _lastRx: 0
    property real _lastTx: 0
    property bool _firstPoll: true

    Timer {
        id: pollTimer
        interval: 2000
        running: true
        repeat: true
        onTriggered: netProc.running = true
    }

    Process {
        id: netProc
        command: ["/usr/bin/cat", "/proc/net/dev"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => root._parseNetDev(data)
        }
    }

    function _parseNetDev(output) {
        // /proc/net/dev format:
        //   Inter-|   Receive                                                |  Transmit
        //    face |bytes    packets ...                                      |bytes    packets ...
        //      lo: 12345   100 ...                                            12345   100 ...
        //   wlan0: 98765   200 ...                                            54321   150 ...
        //
        // Fields after "iface:": rx_bytes(0) rx_packets(1) ... tx_bytes(8) tx_packets(9) ...
        // Some interfaces put the colon glued to bytes: "iface:12345" — handle both.

        const lines = output.split("\n")
        let totalRx = 0, totalTx = 0

        for (const line of lines) {
            const trimmed = line.trim()
            if (!trimmed.includes(":")) continue

            // Skip loopback
            if (trimmed.startsWith("lo:")) continue

            // Split on whitespace
            const parts = trimmed.split(/\s+/)
            if (parts.length < 10) continue

            // parts[0] could be "iface:" or "iface:12345"
            const colonIdx = parts[0].indexOf(":")
            if (colonIdx < 0) continue

            const iface = parts[0].substring(0, colonIdx)
            // Skip header lines (contain "Inter" or "face")
            if (iface === "Inter" || iface === "face") continue

            // Check if bytes are glued to the colon: "iface:12345"
            const afterColon = parts[0].substring(colonIdx + 1)
            let rxIdx, txIdx
            if (afterColon.length > 0) {
                // rx_bytes is glued: parts[0]="iface:RX", parts[1..8] are remaining rx fields + tx_bytes at parts[8]
                totalRx += parseInt(afterColon) || 0
                totalTx += parseInt(parts[8]) || 0
            } else {
                // rx_bytes is parts[1], tx_bytes is parts[9]
                totalRx += parseInt(parts[1]) || 0
                totalTx += parseInt(parts[9]) || 0
            }
        }

        if (root._firstPoll) {
            root._lastRx = totalRx
            root._lastTx = totalTx
            root._firstPoll = false
            return
        }

        const deltaRx = Math.max(0, totalRx - root._lastRx)
        const deltaTx = Math.max(0, totalTx - root._lastTx)
        root._lastRx = totalRx
        root._lastTx = totalTx

        // Speed in bytes/sec (poll interval is 2 seconds)
        root.downloadSpeed = deltaRx / 2
        root.uploadSpeed = deltaTx / 2

        // Session totals
        root.downloadTotal += deltaRx
        root.uploadTotal += deltaTx

        // Update max for normalization (decay slowly so the graph isn't stuck at a spike)
        const currentMax = Math.max(root.downloadSpeed, root.uploadSpeed)
        if (currentMax > root.maxSpeed) {
            root.maxSpeed = currentMax
        } else {
            // Gentle decay: shrink max toward current peak over time
            root.maxSpeed = Math.max(root.maxSpeed * 0.995, currentMax, 1024) // floor at 1 KB/s
        }

        // Update history (normalized 0-1)
        const dlNorm = root.maxSpeed > 0 ? Math.min(root.downloadSpeed / root.maxSpeed, 1.0) : 0
        const ulNorm = root.maxSpeed > 0 ? Math.min(root.uploadSpeed / root.maxSpeed, 1.0) : 0

        let dlHist = [...root.downloadHistory, dlNorm]
        let ulHist = [...root.uploadHistory, ulNorm]
        if (dlHist.length > root.historyLength) dlHist = dlHist.slice(-root.historyLength)
        if (ulHist.length > root.historyLength) ulHist = ulHist.slice(-root.historyLength)
        root.downloadHistory = dlHist
        root.uploadHistory = ulHist

        // Format strings
        root.downloadSpeedStr = root._formatSpeed(root.downloadSpeed)
        root.uploadSpeedStr = root._formatSpeed(root.uploadSpeed)
    }

    function _formatSpeed(bytesPerSec) {
        if (bytesPerSec < 1024) return Math.round(bytesPerSec) + " B/s"
        if (bytesPerSec < 1048576) return (bytesPerSec / 1024).toFixed(1) + " KB/s"
        if (bytesPerSec < 1073741824) return (bytesPerSec / 1048576).toFixed(1) + " MB/s"
        return (bytesPerSec / 1073741824).toFixed(2) + " GB/s"
    }

    Component.onCompleted: netProc.running = true
}
