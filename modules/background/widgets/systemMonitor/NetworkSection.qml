import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

RowLayout {
    id: root

    property var configEntry: ({})

    // Network data
    property string connectionType: ""
    property string connectionName: ""

    // Speed tracking
    property real lastRxBytes: 0
    property real lastTxBytes: 0
    property real rxSpeed: 0
    property real txSpeed: 0
    property string activeInterface: "br0"

    spacing: 10

    // ── Detect connection ──
    Process {
        id: netProc
        command: ["/usr/bin/bash", "-c",
            "nmcli -t -f TYPE,STATE,CONNECTION,DEVICE dev 2>/dev/null | grep ':connected:' | head -1"
        ]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                const line = data.trim()
                if (line === "") {
                    root.connectionType = "disconnected"
                    root.connectionName = ""
                    return
                }
                const parts = line.split(":")
                if (parts.length >= 4) {
                    root.connectionType = parts[0]
                    root.connectionName = parts[2]
                    root.activeInterface = parts[3]
                }
            }
        }
    }

    // ── Speed measurement ──
    Process {
        id: speedProc
        command: ["/usr/bin/bash", "-c",
            "cat /sys/class/net/" + root.activeInterface + "/statistics/rx_bytes /sys/class/net/" + root.activeInterface + "/statistics/tx_bytes 2>/dev/null"
        ]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                const lines = data.trim().split("\n")
                if (lines.length >= 2) {
                    const rx = parseFloat(lines[0])
                    const tx = parseFloat(lines[1])
                    if (root.lastRxBytes > 0) {
                        root.rxSpeed = Math.max(0, (rx - root.lastRxBytes) / 2)
                        root.txSpeed = Math.max(0, (tx - root.lastTxBytes) / 2)
                    }
                    root.lastRxBytes = rx
                    root.lastTxBytes = tx
                }
            }
        }
    }

    Component.onCompleted: {
        netProc.running = true
        speedProc.running = true
    }

    Timer {
        running: root.visible
        interval: 2000
        repeat: true
        onTriggered: speedProc.running = true
    }

    Timer {
        running: root.visible
        interval: 30000
        repeat: true
        triggeredOnStart: true
        onTriggered: netProc.running = true
    }

    // ── Icon ──
    MaterialSymbol {
        text: {
            if (root.connectionType === "wifi") return "wifi"
            if (root.connectionType === "ethernet" || root.connectionType === "bridge") return "lan"
            return "wifi_off"
        }
        iconSize: 16
        color: root.connectionType === "disconnected"
            ? Appearance.colors.colError
            : Appearance.colors.colPrimary
    }

    // ── Connection name ──
    StyledText {
        text: {
            if (root.connectionType === "disconnected") return "Disconnected"
            if (root.connectionType === "wifi") return root.connectionName
            if (root.connectionType === "bridge") return "Bridge (" + root.connectionName + ")"
            return "Ethernet"
        }
        font.pixelSize: Appearance.font.pixelSize.small
        font.weight: Font.Medium
        color: Appearance.colors.colOnLayer0
        elide: Text.ElideRight
    }

    Item { Layout.fillWidth: true }

    // ── Speed indicators ──
    MaterialSymbol {
        text: "arrow_downward"
        iconSize: 12
        color: Appearance.colors.colPrimary
    }
    StyledText {
        text: formatSpeed(root.rxSpeed)
        font.pixelSize: Appearance.font.pixelSize.smallest
        font.family: Appearance.font.family.monospace
        color: Appearance.colors.colSubtext
    }

    MaterialSymbol {
        text: "arrow_upward"
        iconSize: 12
        color: Appearance.colors.colSecondary
    }
    StyledText {
        text: formatSpeed(root.txSpeed)
        font.pixelSize: Appearance.font.pixelSize.smallest
        font.family: Appearance.font.family.monospace
        color: Appearance.colors.colSubtext
    }

    function formatSpeed(bytesPerSec) {
        if (bytesPerSec < 1024) return bytesPerSec.toFixed(0) + " B/s"
        if (bytesPerSec < 1048576) return (bytesPerSec / 1024).toFixed(1) + " KB/s"
        if (bytesPerSec < 1073741824) return (bytesPerSec / 1048576).toFixed(1) + " MB/s"
        return (bytesPerSec / 1073741824).toFixed(2) + " GB/s"
    }
}
