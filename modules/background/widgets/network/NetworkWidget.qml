pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects as GE
import Quickshell
import Quickshell.Io
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.common.functions
import qs.modules.background.widgets
import qs.services

AbstractBackgroundWidget {
    id: root

    configEntryName: "network"

    readonly property var netConfig: configEntry
    readonly property real cardWidth: netConfig.cardWidth ?? 320
    readonly property real cardOpacity: netConfig.cardOpacity ?? 0.85
    readonly property point screenPos: root.mapToItem(null, 0, 0)

    implicitWidth: cardWidth
    implicitHeight: 160

    // ── Network data ──
    property string connectionType: ""
    property string connectionName: ""
    property string ipAddress: ""
    property string activeInterface: "br0"

    // ── Speed tracking ──
    property real lastRxBytes: 0
    property real lastTxBytes: 0
    property real rxSpeed: 0
    property real txSpeed: 0

    // ── Sparkline history (last 30 samples) ──
    property var rxHistory: []
    property var txHistory: []
    readonly property int maxSamples: 30

    // ── Ping quality ──
    property real pingMs: -1
    property color pingColor: {
        if (pingMs < 0) return Appearance.colors.colSubtext
        if (pingMs < 20) return "#4caf50"
        if (pingMs <= 100) return "#ffc107"
        return "#f44336"
    }

    // ── Copy feedback ──
    property bool showCopied: false

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
                root.ipAddress = data.trim() || "\u2014"
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

    // ── Ping latency ──
    Process {
        id: pingProc
        command: ["/usr/bin/bash", "-c",
            "ping -c 1 -W 1 1.1.1.1 2>/dev/null | grep -oP 'time=\\K[\\d.]+' || echo '-1'"
        ]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                const val = parseFloat(data.trim())
                root.pingMs = Number.isFinite(val) ? val : -1
            }
        }
    }

    // ── Copy IP to clipboard ──
    Process {
        id: copyProc
        command: ["/usr/bin/bash", "-c",
            "echo -n '" + root.ipAddress + "' | wl-copy"
        ]
    }

    Component.onCompleted: {
        netProc.running = true
        ipProc.running = true
        speedProc.running = true
        pingProc.running = true
    }

    // Speed poll — every 2s
    Timer {
        running: root.visible
        interval: 2000
        repeat: true
        onTriggered: speedProc.running = true
    }

    // Connection + IP poll — every 30s
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

    // Ping poll — every 15s
    Timer {
        running: root.visible
        interval: 15000
        repeat: true
        triggeredOnStart: true
        onTriggered: pingProc.running = true
    }

    // Copy feedback reset
    Timer {
        id: copiedTimer
        interval: 1500
        onTriggered: root.showCopied = false
    }

    // ── Drop shadow ──
    StyledRectangularShadow {
        target: cardBackground
        visible: !Appearance.inirEverywhere && !Appearance.auroraEverywhere
    }

    // ── Glass card background ──
    Rectangle {
        id: cardBackground
        anchors.fill: parent
        radius: Appearance.rounding.large
        color: "transparent"
        clip: true

        GlassBackground {
            anchors.fill: parent
            radius: parent.radius
            screenX: root.screenPos.x
            screenY: root.screenPos.y
            fallbackColor: ColorUtils.transparentize(
                Appearance.colors.colLayer0,
                1.0 - root.cardOpacity
            )
        }

        Rectangle {
            anchors.fill: parent
            visible: !Appearance.auroraEverywhere && !Appearance.angelEverywhere
            radius: parent.radius
            color: ColorUtils.transparentize(
                Appearance.colors.colLayer0,
                1.0 - root.cardOpacity
            )
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.width: 1
            border.color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.88)
        }

        // Inset depth — top edge gradient
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 1
            height: 6
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.7) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }

    // ── Content ──
    ColumnLayout {
        id: cardContent
        anchors.fill: parent
        anchors.margins: 16
        spacing: 6

        // ── Header row ──
        RowLayout {
            Layout.fillWidth: true

            StyledText {
                text: "NETWORK"
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.letterSpacing: 2.0
                font.weight: Font.DemiBold
                color: Appearance.colors.colSubtext
            }

            Item { Layout.fillWidth: true }

            MaterialSymbol {
                iconSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colSubtext
                text: {
                    if (root.connectionType === "wifi") return "wifi"
                    if (root.connectionType === "ethernet" || root.connectionType === "bridge") return "lan"
                    if (root.connectionType === "disconnected") return "signal_disconnected"
                    return "language"
                }
            }
        }

        // ── IP address with click-to-copy ──
        MouseArea {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: ipRow.implicitWidth
            implicitHeight: ipRow.implicitHeight
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                copyProc.running = true
                root.showCopied = true
                copiedTimer.restart()
            }

            RowLayout {
                id: ipRow
                spacing: 6

                // Ping quality dot
                Rectangle {
                    width: 6
                    height: 6
                    radius: 3
                    color: root.pingColor
                    Layout.alignment: Qt.AlignVCenter
                }

                StyledText {
                    text: root.showCopied ? "Copied" : (root.ipAddress || "\u2014")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.family: Appearance.font.family.monospace
                    font.weight: Font.Medium
                    color: root.showCopied
                        ? Appearance.colors.colSecondary
                        : Appearance.colors.colPrimary
                }
            }
        }

        // ── Speed indicators ──
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 16

            StyledText {
                text: "\u2193 " + formatSpeed(root.rxSpeed)
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.family: Appearance.font.family.monospace
                color: Appearance.colors.colPrimary
            }

            StyledText {
                text: "\u2191 " + formatSpeed(root.txSpeed)
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.family: Appearance.font.family.monospace
                color: Appearance.colors.colSecondary
            }
        }

        // ── Mirrored area-fill sparkline ──
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 50

            Canvas {
                id: sparkCanvas
                anchors.fill: parent

                onPaint: {
                    const ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    const w = width
                    const h = height
                    const midY = h / 2

                    // Find max for scaling
                    let maxVal = 1024
                    for (const v of root.rxHistory) maxVal = Math.max(maxVal, v)
                    for (const v of root.txHistory) maxVal = Math.max(maxVal, v)

                    // RX (download) — fills from midY toward top
                    drawAreaFill(ctx, root.rxHistory, w, h, midY, maxVal,
                        Appearance.colors.colPrimary, true)
                    // TX (upload) — fills from midY toward bottom
                    drawAreaFill(ctx, root.txHistory, w, h, midY, maxVal,
                        Appearance.colors.colSecondary, false)

                    // Center baseline
                    ctx.beginPath()
                    ctx.moveTo(0, midY)
                    ctx.lineTo(w, midY)
                    ctx.strokeStyle = Qt.rgba(
                        Appearance.colors.colSubtext.r,
                        Appearance.colors.colSubtext.g,
                        Appearance.colors.colSubtext.b,
                        0.2
                    )
                    ctx.lineWidth = 0.5
                    ctx.stroke()
                }

                function drawAreaFill(ctx, data, w, h, baseline, maxVal, color, flipUp) {
                    if (data.length < 2) return
                    const stepX = w / (root.maxSamples - 1)
                    const startIdx = root.maxSamples - data.length

                    // Build points with bezier smoothing
                    const pts = []
                    for (let i = 0; i < data.length; i++) {
                        const x = (startIdx + i) * stepX
                        const norm = Math.min(data[i] / maxVal, 1.0)
                        const y = flipUp
                            ? baseline - norm * (h * 0.45)
                            : baseline + norm * (h * 0.45)
                        pts.push({x: x, y: y})
                    }

                    // Filled area with gradient
                    ctx.beginPath()
                    ctx.moveTo(pts[0].x, baseline)
                    ctx.lineTo(pts[0].x, pts[0].y)
                    for (let i = 1; i < pts.length; i++) {
                        const prev = pts[i - 1]
                        const curr = pts[i]
                        const cpx1 = prev.x + (curr.x - prev.x) * 0.3
                        const cpx2 = curr.x - (curr.x - prev.x) * 0.3
                        ctx.bezierCurveTo(cpx1, prev.y, cpx2, curr.y, curr.x, curr.y)
                    }
                    ctx.lineTo(pts[pts.length - 1].x, baseline)
                    ctx.closePath()

                    const grad = flipUp
                        ? ctx.createLinearGradient(0, baseline - h * 0.45, 0, baseline)
                        : ctx.createLinearGradient(0, baseline + h * 0.45, 0, baseline)
                    grad.addColorStop(0, Qt.rgba(color.r, color.g, color.b, 0.25))
                    grad.addColorStop(1, "transparent")
                    ctx.fillStyle = grad
                    ctx.fill()

                    // Stroke line on top
                    ctx.beginPath()
                    ctx.moveTo(pts[0].x, pts[0].y)
                    for (let i = 1; i < pts.length; i++) {
                        const prev = pts[i - 1]
                        const curr = pts[i]
                        const cpx1 = prev.x + (curr.x - prev.x) * 0.3
                        const cpx2 = curr.x - (curr.x - prev.x) * 0.3
                        ctx.bezierCurveTo(cpx1, prev.y, cpx2, curr.y, curr.x, curr.y)
                    }
                    ctx.strokeStyle = Qt.rgba(color.r, color.g, color.b, 0.9)
                    ctx.lineWidth = 1.5
                    ctx.stroke()
                }
            }

            // Repaint when data changes
            Connections {
                target: root
                function onRxHistoryChanged() { sparkCanvas.requestPaint() }
                function onTxHistoryChanged() { sparkCanvas.requestPaint() }
            }
        }
    }

    function formatSpeed(bytesPerSec: real): string {
        if (bytesPerSec < 1024) return bytesPerSec.toFixed(0) + " B/s"
        if (bytesPerSec < 1048576) return (bytesPerSec / 1024).toFixed(1) + " KB/s"
        if (bytesPerSec < 1073741824) return (bytesPerSec / 1048576).toFixed(1) + " MB/s"
        return (bytesPerSec / 1073741824).toFixed(2) + " GB/s"
    }
}
