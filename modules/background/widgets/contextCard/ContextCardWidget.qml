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
import "root:"

AbstractBackgroundWidget {
    id: root

    configEntryName: "contextCard"

    readonly property var cardConfig: configEntry
    readonly property real cardWidth: cardConfig.cardWidth ?? 280
    readonly property real cardOpacity: cardConfig.cardOpacity ?? 0.85
    readonly property point screenPos: root.mapToItem(null, 0, 0)
    readonly property bool showPackageUpdates: cardConfig.showPackageUpdates ?? true
    readonly property bool showMarketStatus: cardConfig.showMarketStatus ?? true
    readonly property bool showPomodoro: cardConfig.showPomodoro ?? true
    readonly property bool showFocusMode: cardConfig.showFocusMode ?? true
    readonly property bool showServiceHealth: cardConfig.showServiceHealth ?? true

    implicitWidth: cardWidth
    implicitHeight: cardContent.implicitHeight + cardContent.anchors.margins * 2

    // ── Package updates ──
    property int pendingUpdates: -1
    property bool updatesLoading: false

    Process {
        id: updateCheckProc
        command: ["/usr/bin/bash", "-c", "checkupdates 2>/dev/null | wc -l"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                root.updatesLoading = false
                const count = parseInt(data.trim())
                root.pendingUpdates = Number.isFinite(count) ? count : 0
            }
        }
    }

    // Package update poll — every 30 min, NOT on start
    Timer {
        running: root.visible && root.showPackageUpdates
        interval: 1800000
        repeat: true
        triggeredOnStart: false
        onTriggered: {
            root.updatesLoading = true
            updateCheckProc.running = true
        }
    }

    // First check after 10s delay (avoid startup burst)
    Timer {
        id: firstUpdateCheck
        running: root.visible && root.showPackageUpdates
        interval: 10000
        repeat: false
        onTriggered: {
            root.updatesLoading = true
            updateCheckProc.running = true
        }
    }

    // ── Market status ──
    property string marketState: ""

    Process {
        id: marketReadProc
        command: ["/usr/bin/bash", "-c", "cat ~/.local/state/inir/market-state 2>/dev/null || echo unknown"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                root.marketState = data.trim()
            }
        }
    }

    Timer {
        running: root.visible && root.showMarketStatus
        interval: 300000  // 5 min
        repeat: true
        triggeredOnStart: true
        onTriggered: marketReadProc.running = true
    }

    // ── Service health ──
    property int failedServices: -1

    Process {
        id: serviceHealthProc
        command: ["/usr/bin/bash", "-c", "systemctl --user --failed --no-legend 2>/dev/null | wc -l"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                const count = parseInt(data.trim())
                root.failedServices = Number.isFinite(count) ? count : 0
            }
        }
    }

    Timer {
        running: root.visible && root.showServiceHealth
        interval: 600000  // 10 min
        repeat: true
        triggeredOnStart: false
        onTriggered: serviceHealthProc.running = true
    }

    Timer {
        running: root.visible && root.showServiceHealth
        interval: 15000  // first check after 15s
        repeat: false
        onTriggered: serviceHealthProc.running = true
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
        radius: Appearance.rounding.unsharpen
        color: "transparent"
        clip: true

        GlassBackground {
            anchors.fill: parent
            radius: parent.radius
            screenX: root.screenPos.x
            screenY: root.screenPos.y
            fallbackColor: ColorUtils.transparentize(
                Appearance.mission.colCanvas,
                1.0 - root.cardOpacity
            )
        }

        Rectangle {
            anchors.fill: parent
            visible: !Appearance.auroraEverywhere && !Appearance.angelEverywhere
            radius: parent.radius
            color: ColorUtils.transparentize(
                Appearance.mission.colCanvas,
                1.0 - root.cardOpacity
            )
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.width: 1
            border.color: Appearance.mission.colBorder
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
                GradientStop { position: 0.0; color: ColorUtils.transparentize(Appearance.mission.colCanvas, 0.7) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        // ── Accent stripe (Context Card signature) ──
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: Appearance.rounding.unsharpen
            anchors.bottomMargin: Appearance.rounding.unsharpen
            width: 3
            color: Appearance.mission.colAccent
            opacity: 0.85
        }
    }

    // ── Content ──
    ColumnLayout {
        id: cardContent
        anchors.fill: parent
        anchors.margins: 16
        anchors.leftMargin: 22  // Extra left margin for accent stripe
        spacing: 10

        // ── Header ──
        StyledText {
            text: "STATUS"
            font.pixelSize: Appearance.font.pixelSize.smallest
            font.family: Appearance.font.family.monospace
            font.letterSpacing: 2.0
            font.weight: Font.DemiBold
            color: Appearance.mission.colTextSecondary
        }

        // ── FocusMode chip ──
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: focusRow.implicitHeight + 12
            visible: root.showFocusMode
            radius: Appearance.rounding.small
            color: FocusMode.active
                ? ColorUtils.transparentize(FocusMode.accentColor, 0.8)
                : ColorUtils.transparentize(Appearance.mission.colSurface, 0.4)

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: FocusMode.cycleMode()
            }

            RowLayout {
                id: focusRow
                anchors.fill: parent
                anchors.margins: 6
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                MaterialSymbol {
                    text: FocusMode.icon || "routine"
                    iconSize: 18
                    color: FocusMode.active
                        ? FocusMode.accentColor
                        : Appearance.mission.colTextSecondary
                }

                StyledText {
                    Layout.fillWidth: true
                    text: FocusMode.label || "Auto"
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                    color: FocusMode.active
                        ? FocusMode.accentColor
                        : Appearance.mission.colText
                }

                StyledText {
                    visible: FocusMode.active
                    text: "active"
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    font.weight: Font.DemiBold
                    color: FocusMode.accentColor
                }
            }
        }

        // ── Pomodoro timer ──
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: pomodoroRow.implicitHeight + 12
            visible: root.showPomodoro && TimerService.pomodoroRunning
            radius: Appearance.rounding.small
            color: ColorUtils.transparentize(
                TimerService.pomodoroBreak ? Appearance.mission.colWaiting : Appearance.mission.colAccent,
                0.85
            )

            RowLayout {
                id: pomodoroRow
                anchors.fill: parent
                anchors.margins: 6
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                // Mini progress ring
                Item {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28

                    Canvas {
                        id: pomodoroCanvas
                        anchors.fill: parent
                        onPaint: {
                            const ctx = getContext("2d")
                            ctx.reset()
                            const cx = width / 2
                            const cy = height / 2
                            const r = 11
                            const progress = TimerService.pomodoroLapDuration > 0
                                ? (TimerService.pomodoroLapDuration - TimerService.pomodoroSecondsLeft) / TimerService.pomodoroLapDuration
                                : 0
                            const color = TimerService.pomodoroBreak
                                ? Appearance.mission.colWaiting
                                : Appearance.mission.colAccent

                            // Track
                            ctx.beginPath()
                            ctx.arc(cx, cy, r, 0, 2 * Math.PI)
                            ctx.lineWidth = 2.5
                            ctx.strokeStyle = Qt.rgba(color.r, color.g, color.b, 0.2)
                            ctx.stroke()

                            // Progress
                            if (progress > 0.005) {
                                ctx.beginPath()
                                ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + progress * 2 * Math.PI)
                                ctx.lineWidth = 2.5
                                ctx.strokeStyle = color.toString()
                                ctx.lineCap = "round"
                                ctx.stroke()
                            }
                        }
                    }

                    Connections {
                        target: TimerService
                        function onPomodoroSecondsLeftChanged() { pomodoroCanvas.requestPaint() }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        text: TimerService.pomodoroBreak
                            ? (TimerService.pomodoroLongBreak ? "Long Break" : "Break")
                            : "Focus"
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Medium
                        color: Appearance.mission.colText
                    }

                    StyledText {
                        text: {
                            const secs = TimerService.pomodoroSecondsLeft
                            const m = Math.floor(secs / 60)
                            const s = secs % 60
                            return m + ":" + (s < 10 ? "0" : "") + s
                        }
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.family: Appearance.font.family.numbers
                        font.weight: Font.Bold
                        color: TimerService.pomodoroBreak
                            ? Appearance.mission.colWaiting
                            : Appearance.mission.colAccent
                    }
                }

                StyledText {
                    text: (TimerService.pomodoroCycle + 1) + "/" + (TimerService.cyclesBeforeLongBreak ?? 4)
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    font.family: Appearance.font.family.numbers
                    color: Appearance.mission.colTextSecondary
                }
            }
        }

        // ── Separator ──
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            visible: root.showMarketStatus || root.showPackageUpdates || root.showServiceHealth
            color: Appearance.mission.colBorder
        }

        // ── Status badges ──
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            // Market status
            RowLayout {
                Layout.fillWidth: true
                visible: root.showMarketStatus && root.marketState !== ""
                spacing: 8

                Rectangle {
                    width: 6; height: 6; radius: 3
                    color: root.marketState === "open" ? Appearance.mission.colDone : Appearance.mission.colTextSecondary
                    Layout.alignment: Qt.AlignVCenter
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.marketState === "open" ? "NYSE Open" : "NYSE Closed"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: root.marketState === "open"
                        ? Appearance.mission.colText
                        : Appearance.mission.colTextSecondary
                }
            }

            // Package updates
            RowLayout {
                Layout.fillWidth: true
                visible: root.showPackageUpdates && root.pendingUpdates >= 0
                spacing: 8

                MaterialSymbol {
                    text: root.pendingUpdates > 0 ? "system_update_alt" : "verified"
                    iconSize: 14
                    color: root.pendingUpdates > 0
                        ? Appearance.mission.colAccent
                        : Appearance.mission.colTextSecondary
                    Layout.alignment: Qt.AlignVCenter
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.updatesLoading ? "Checking..."
                        : root.pendingUpdates === 0 ? "System up to date"
                        : root.pendingUpdates + " update" + (root.pendingUpdates !== 1 ? "s" : "") + " available"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: root.pendingUpdates > 0
                        ? Appearance.mission.colText
                        : Appearance.mission.colTextSecondary
                }
            }

            // Service health
            RowLayout {
                Layout.fillWidth: true
                visible: root.showServiceHealth && root.failedServices >= 0
                spacing: 8

                MaterialSymbol {
                    text: root.failedServices > 0 ? "error" : "check_circle"
                    iconSize: 14
                    color: root.failedServices > 0 ? Appearance.mission.colCritical : Appearance.mission.colTextSecondary
                    Layout.alignment: Qt.AlignVCenter
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.failedServices === 0 ? "Services healthy"
                        : root.failedServices + " failed service" + (root.failedServices !== 1 ? "s" : "")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: root.failedServices > 0
                        ? Appearance.mission.colCritical
                        : Appearance.mission.colTextSecondary
                }
            }
        }
    }
}
