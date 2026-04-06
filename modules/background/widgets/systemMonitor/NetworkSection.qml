import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

ColumnLayout {
    id: root

    property var configEntry: ({})

    // Network data
    property string connectionType: ""
    property string connectionName: ""
    property string ipAddress: ""

    // Speed tracking
    property real lastRxBytes: 0
    property real lastTxBytes: 0
    property real rxSpeed: 0
    property real txSpeed: 0
    property string activeInterface: "br0"

    // Sparkline history (last 30 samples)
    property var rxHistory: []
    property var txHistory: []
    readonly property int maxSamples: 30

    spacing: 8

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

    // ── Get IP address ──
    Process {
        id: ipProc
        command: ["/usr/bin/bash", "-c",
            "ip -4 addr show " + root.activeInterface + " 2>/dev/null | grep -oP '(?<=inet )\\S+' | cut -d/ -f1 | head -1"
        ]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                root.ipAddress = data.trim() || "—"
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

                        // Push to history
                        const rxH = root.rxHistory.slice()
                        const txH = root.txHistory.slice()
                        rxH.push(root.rxSpeed)
                        txH.push(root.txSpeed)
                        if (rxH.length > root.maxSamples) rxH.shift()
                        if (txH.length > root.maxSamples) txH.shift()
                        root.rxHistory = rxH
                        root.txHistory = txH
                    }
                    root.lastRxBytes = rx
                    root.lastTxBytes = tx
                }
            }
        }
    }

    Component.onCompleted: {
        netProc.running = true
        ipProc.running = true
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
        onTriggered: {
            netProc.running = true
            ipProc.running = true
        }
    }

    // ── IP address centered ──
    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: root.ipAddress || "—"
        font.pixelSize: Appearance.font.pixelSize.normal
        font.family: Appearance.font.family.monospace
        font.weight: Font.Medium
        color: Appearance.colors.colPrimary
    }

    // ── Sparkline graph ──
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 60

        Canvas {
            id: sparkCanvas
            anchors.fill: parent

            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                const w = width
                const h = height
                const midY = h / 2

                // Find max for scaling
                let maxVal = 1024 // minimum scale: 1 KB/s
                for (const v of root.rxHistory) maxVal = Math.max(maxVal, v)
                for (const v of root.txHistory) maxVal = Math.max(maxVal, v)

                // Draw RX (download) — top half, line going up
                drawSparkline(ctx, root.rxHistory, w, midY, 0, maxVal,
                    Appearance.colors.colPrimary.toString(), true)

                // Draw TX (upload) — bottom half, line going down
                drawSparkline(ctx, root.txHistory, w, midY, midY, maxVal,
                    Appearance.colors.colSecondary.toString(), false)
            }

            function drawSparkline(ctx, data, w, halfH, yOffset, maxVal, color, flipUp) {
                if (data.length < 2) return

                const stepX = w / (root.maxSamples - 1)
                const startIdx = root.maxSamples - data.length

                ctx.beginPath()
                ctx.strokeStyle = color
                ctx.lineWidth = 1.5
                ctx.lineJoin = "round"
                ctx.lineCap = "round"

                for (let i = 0; i < data.length; i++) {
                    const x = (startIdx + i) * stepX
                    const norm = Math.min(data[i] / maxVal, 1.0)
                    const y = flipUp
                        ? yOffset + halfH - (norm * (halfH - 4))
                        : yOffset + (norm * (halfH - 4)) + 2
                    if (i === 0) ctx.moveTo(x, y)
                    else ctx.lineTo(x, y)
                }
                ctx.stroke()
            }
        }

        // Repaint when data changes
        Connections {
            target: root
            function onRxHistoryChanged() { sparkCanvas.requestPaint() }
            function onTxHistoryChanged() { sparkCanvas.requestPaint() }
        }

        // ↑↓ indicators on the left edge
        ColumnLayout {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            StyledText {
                text: "\u2193"
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.weight: Font.Bold
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: "\u2191"
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.weight: Font.Bold
                color: Appearance.colors.colSecondary
            }
        }
    }

    function formatSpeed(bytesPerSec) {
        if (bytesPerSec < 1024) return bytesPerSec.toFixed(0) + " B/s"
        if (bytesPerSec < 1048576) return (bytesPerSec / 1024).toFixed(1) + " KB/s"
        if (bytesPerSec < 1073741824) return (bytesPerSec / 1048576).toFixed(1) + " MB/s"
        return (bytesPerSec / 1073741824).toFixed(2) + " GB/s"
    }
}
