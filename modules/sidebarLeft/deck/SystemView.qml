pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.services

/**
 * SystemView — System monitoring view for the Deck sidebar (View 2).
 *
 * Layout:
 *   ArcGauge row (CPU + GPU)
 *   UsageBar (RAM)
 *   UsageBar (VRAM)
 *   Network row (▲ up / ▼ down)
 *   DeckDivider
 *   UsageBar (/ root)
 *   UsageBar (/home)  — if different partition
 *   UsageBar (/mnt/hdd)  — if mounted
 *   DeckDivider
 *   ContextCards
 *
 * No SystemStrip — redundant at this depth.
 */
Item {
    id: root

    // ── Resource polling gate ──────────────────────────────────────────
    Component.onCompleted: {
        if (GlobalStates.sidebarLeftOpen) ResourceUsage.ensureRunning()
    }

    Connections {
        target: GlobalStates
        function onSidebarLeftOpenChanged() {
            if (GlobalStates.sidebarLeftOpen && root.visible) ResourceUsage.ensureRunning()
        }
    }

    // ── Network: poll /proc/net/dev, compute rates ────────────────────
    property real _netRxBytesPerSec: 0
    property real _netTxBytesPerSec: 0
    property real _prevRx: -1
    property real _prevTx: -1
    property real _prevPollTime: 0

    // Format bytes/s to a human-readable string
    function _fmtRate(bytesPerSec) {
        if (bytesPerSec < 1024)
            return bytesPerSec.toFixed(0) + " B/s"
        if (bytesPerSec < 1024 * 1024)
            return (bytesPerSec / 1024).toFixed(1) + " KB/s"
        return (bytesPerSec / (1024 * 1024)).toFixed(1) + " MB/s"
    }

    Timer {
        id: netPollTimer
        interval: 2000
        repeat: true
        running: GlobalStates.sidebarLeftOpen && root.visible
        onTriggered: netProc.running = true
        onRunningChanged: {
            if (running && !netProc.running) netProc.running = true
        }
    }

    Process {
        id: netProc
        command: ["bash", "-c",
            "awk '/^\\s*[a-z]/{if($1!=\"lo:\"){split($1,a,\":\"); rx+=$2; tx+=$10}} END{print rx\" \"tx}' /proc/net/dev"
        ]
        running: false
        stdout: StdioCollector {
            id: netCollector
            onStreamFinished: {
                const parts = netCollector.text.trim().split(" ")
                if (parts.length < 2) return
                const rx = parseFloat(parts[0]) || 0
                const tx = parseFloat(parts[1]) || 0
                const now = Date.now()

                if (root._prevRx >= 0 && root._prevPollTime > 0) {
                    const dt = (now - root._prevPollTime) / 1000  // seconds
                    if (dt > 0) {
                        root._netRxBytesPerSec = Math.max(0, (rx - root._prevRx) / dt)
                        root._netTxBytesPerSec = Math.max(0, (tx - root._prevTx) / dt)
                    }
                }
                root._prevRx = rx
                root._prevTx = tx
                root._prevPollTime = now
            }
        }
    }

    // ── Disk: df for /, /home, /mnt/hdd ──────────────────────────────
    // Bytes (df -B1). Track each partition separately.
    property real _diskRootTotal: 1
    property real _diskRootUsed: 0
    property real _diskHomeTotal: 1
    property real _diskHomeUsed: 0
    property bool _diskHomeVisible: false
    property real _diskHddTotal: 1
    property real _diskHddUsed: 0
    property bool _diskHddVisible: false

    // Parse helper: convert bytes to GB
    function _bytesToGb(bytes) { return bytes / (1024 * 1024 * 1024) }

    Timer {
        id: diskPollTimer
        interval: 10000
        repeat: true
        running: GlobalStates.sidebarLeftOpen && root.visible
        onTriggered: diskProc.running = true
    }

    // Trigger first disk poll when view becomes visible
    onVisibleChanged: {
        if (visible && GlobalStates.sidebarLeftOpen && !diskProc.running) {
            diskProc.running = true
        }
    }

    Process {
        id: diskProc
        command: ["bash", "-c", "df -B1 / /home /mnt/hdd 2>/dev/null | tail -n +2"]
        running: false
        stdout: StdioCollector {
            id: diskCollector
            onStreamFinished: {
                const lines = diskCollector.text.trim().split("\n")
                for (const line of lines) {
                    const parts = line.trim().split(/\s+/)
                    if (parts.length < 6) continue
                    // df columns: Filesystem 1B-blocks Used Available Use% Mounted-on
                    const total     = parseFloat(parts[1]) || 1
                    const used      = parseFloat(parts[2]) || 0
                    const mountpt   = parts[5]

                    if (mountpt === "/") {
                        root._diskRootTotal = total
                        root._diskRootUsed  = used
                    } else if (mountpt === "/home") {
                        root._diskHomeTotal   = total
                        root._diskHomeUsed    = used
                        root._diskHomeVisible = true
                    } else if (mountpt === "/mnt/hdd") {
                        root._diskHddTotal   = total
                        root._diskHddUsed    = used
                        root._diskHddVisible = true
                    }
                }
            }
        }
    }

    // ── Layout ────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // Arc row: CPU + GPU
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ArcGauge {
                Layout.fillWidth: true
                value: ResourceUsage.cpuUsage
                label: "CPU"
                temperature: ResourceUsage.cpuTemp
            }

            ArcGauge {
                Layout.fillWidth: true
                value: ResourceUsage.gpuUsage
                label: "GPU"
                temperature: ResourceUsage.gpuTemp
            }
        }

        // Memory section
        DeckLabel { text: "MEMORY" }

        // RAM
        UsageBar {
            label: "RAM"
            // memoryUsed/Total are in kB — convert to GB
            used:  ResourceUsage.memoryUsed  / (1024 * 1024)
            total: ResourceUsage.memoryTotal / (1024 * 1024)
            unit: "GB"
        }

        // VRAM
        UsageBar {
            label: "VRAM"
            // vramUsed/Total are in bytes
            used:  ResourceUsage.vramUsed  / (1024 * 1024 * 1024)
            total: ResourceUsage.vramTotal / (1024 * 1024 * 1024)
            unit: "GB"
        }

        // Network row
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "▲ " + root._fmtRate(root._netTxBytesPerSec)
                font.family: Appearance.font.family.monospace
                font.pixelSize: 12
                color: Appearance.colors.colOnLayer1Inactive
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "▼ " + root._fmtRate(root._netRxBytesPerSec)
                font.family: Appearance.font.family.monospace
                font.pixelSize: 12
                color: Appearance.colors.colOnLayer1Inactive
            }
        }

        // Disk section
        DeckLabel { text: "DISK" }

        // Disk: root
        UsageBar {
            label: "/"
            used:  root._bytesToGb(root._diskRootUsed)
            total: root._bytesToGb(root._diskRootTotal)
            unit: "GB"
            hotThreshold: 0.85
        }

        // Disk: /home (hidden if same partition as /)
        UsageBar {
            visible: root._diskHomeVisible
            label: "/home"
            used:  root._bytesToGb(root._diskHomeUsed)
            total: root._bytesToGb(root._diskHomeTotal)
            unit: "GB"
            hotThreshold: 0.85
        }

        // Disk: /mnt/hdd (hidden if not mounted)
        UsageBar {
            visible: root._diskHddVisible
            label: "/mnt/hdd"
            used:  root._bytesToGb(root._diskHddUsed)
            total: root._bytesToGb(root._diskHddTotal)
            unit: "GB"
            hotThreshold: 0.85
        }

        DeckDivider {}

        ContextCards {
            Layout.fillWidth: true
            active: root.visible && GlobalStates.sidebarLeftOpen
        }

        // Spacer
        Item { Layout.fillHeight: true }
    }
}
