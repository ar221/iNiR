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

    configEntryName: "timeCalendar"

    readonly property var calendarConfig: configEntry
    readonly property real cardWidth: calendarConfig.cardWidth ?? 300
    readonly property real cardOpacity: calendarConfig.cardOpacity ?? 0.85
    readonly property point screenPos: root.mapToItem(null, 0, 0)
    readonly property var locale: Qt.locale()
    readonly property date today: DateTime.clock.date
    readonly property int currentMonth: calendarView.focusedMonth

    property var events: []
    property bool gcalAvailable: false
    property bool eventsLoading: false
    property int _countdownTick: 0

    implicitWidth: cardWidth
    implicitHeight: cardContent.implicitHeight + cardContent.anchors.margins * 2

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
        anchors.margins: 20
        spacing: 8

        // ── Clock ──
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: DateTime.time
            font.pixelSize: 52
            font.family: Appearance.font.family.numbers
            font.weight: Font.Bold
            color: Appearance.colors.colPrimary
        }

        // ── Compact date line ──
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: {
                const d = root.today
                const dow = d.toLocaleDateString(root.locale, "ddd").toLowerCase()
                const day = d.getDate()
                const mon = d.toLocaleDateString(root.locale, "MMM").toLowerCase()
                return dow + " " + day + " " + mon
            }
            font.pixelSize: Appearance.font.pixelSize.small
            font.weight: Font.Medium
            color: Appearance.colors.colSubtext
        }

        // ── Separator ──
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            Layout.topMargin: 4
            color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.88)
        }

        // ── Month/Year navigation row ──
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 0

            RippleButton {
                implicitWidth: 26; implicitHeight: 26
                buttonRadius: 13
                colBackground: "transparent"
                colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.85)
                onClicked: calendarView.scrollMonthsAndSnap(-1)
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: "chevron_left"
                    iconSize: 16
                    color: Appearance.colors.colSubtext
                }
            }

            StyledText {
                text: {
                    const d = calendarView.focusedDate
                    return d.toLocaleDateString(root.locale, "MMMM")
                }
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer0
            }

            RippleButton {
                implicitWidth: 26; implicitHeight: 26
                buttonRadius: 13
                colBackground: "transparent"
                colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.85)
                onClicked: calendarView.scrollMonthsAndSnap(1)
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: "chevron_right"
                    iconSize: 16
                    color: Appearance.colors.colSubtext
                }
            }

            Item { Layout.fillWidth: true }

            StyledText {
                text: calendarView.focusedDate.getFullYear().toString()
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer0
            }
        }

        // ── Day-of-week headers ──
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 0

            Repeater {
                model: {
                    const fdow = root.locale?.firstDayOfWeek ?? 0
                    const items = []
                    for (let i = 0; i < 7; i++) {
                        const dayIdx = (fdow + i) % 7
                        const refDate = new Date(2024, 0, 7 + dayIdx)
                        items.push(refDate.toLocaleDateString(root.locale, "ddd").substring(0, 3).toLowerCase())
                    }
                    return items
                }

                StyledText {
                    required property string modelData
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colSubtext
                }
            }
        }

        // ── Calendar grid ──
        CalendarView {
            id: calendarView
            Layout.fillWidth: true
            locale: root.locale
            buttonSize: 32
            buttonSpacing: 2
            paddingWeeks: 1

            delegate: Item {
                id: dayDelegate
                required property var model
                implicitWidth: 32
                implicitHeight: 32

                readonly property bool isToday: model.today
                readonly property bool isCurrentMonth: model.month === root.currentMonth

                Rectangle {
                    anchors.centerIn: parent
                    width: 28
                    height: 28
                    radius: 14
                    color: dayDelegate.isToday ? Appearance.colors.colPrimary : "transparent"
                }

                StyledText {
                    anchors.centerIn: parent
                    text: model.day
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    font.weight: dayDelegate.isToday ? Font.Bold : Font.Normal
                    color: dayDelegate.isToday ? Appearance.colors.colOnPrimary
                         : dayDelegate.isCurrentMonth ? Appearance.colors.colOnLayer0
                         : ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.6)
                }
            }
        }

        // ── Events section (only when gcalcli available) ──
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.gcalAvailable
            spacing: 6

            // Separator before events
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.88)
            }

            // Section header
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                MaterialSymbol {
                    text: "event"
                    iconSize: 16
                    color: Appearance.colors.colSubtext
                }

                StyledText {
                    Layout.fillWidth: true
                    text: "Today's Events"
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer0
                }

                RippleButton {
                    implicitWidth: 22; implicitHeight: 22
                    buttonRadius: 11
                    colBackground: "transparent"
                    colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.85)
                    onClicked: root.fetchEvents()
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "refresh"
                        iconSize: 14
                        color: Appearance.colors.colSubtext
                    }
                }
            }

            // Loading indicator
            StyledText {
                visible: root.eventsLoading
                text: "Loading events..."
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colSubtext
            }

            // No events
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                visible: root.gcalAvailable && !root.eventsLoading && root.events.length === 0
                radius: Appearance.rounding.small
                color: ColorUtils.transparentize(Appearance.colors.colSurfaceContainer, 0.4)

                StyledText {
                    anchors.centerIn: parent
                    text: "No events today"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }
            }

            // Event items
            Repeater {
                model: root.events

                Rectangle {
                    id: eventItem
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    Layout.preferredHeight: eventRow.implicitHeight + 10
                    radius: Appearance.rounding.small
                    color: ColorUtils.transparentize(Appearance.colors.colSurfaceContainer, 0.4)

                    RowLayout {
                        id: eventRow
                        anchors.fill: parent
                        anchors.margins: 5
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        Rectangle {
                            Layout.preferredWidth: 3
                            Layout.fillHeight: true
                            radius: 1.5
                            color: eventItem.index === 0 ? Appearance.colors.colPrimary
                                 : eventItem.index === 1 ? Appearance.colors.colSecondary
                                 : Appearance.colors.colTertiary
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            StyledText {
                                Layout.fillWidth: true
                                text: eventItem.modelData.title
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer0
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            StyledText {
                                text: {
                                    const t = eventItem.modelData.time
                                    if (eventItem.modelData.endTime)
                                        return t + " - " + eventItem.modelData.endTime
                                    return t
                                }
                                font.pixelSize: Appearance.font.pixelSize.smallest
                                color: Appearance.colors.colSubtext
                            }
                        }
                    }
                }
            }
        }

        // ── Next event countdown (within 2 hours) ──
        StyledText {
            id: nextEventCountdown
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 4
            visible: text !== ""
            font.pixelSize: Appearance.font.pixelSize.small
            font.weight: Font.Medium
            color: Appearance.colors.colPrimary

            text: {
                void root._countdownTick // force re-eval every minute
                if (!root.gcalAvailable || root.events.length === 0) return ""
                const now = new Date()
                const todayStr = now.getFullYear() + "-"
                    + String(now.getMonth() + 1).padStart(2, "0") + "-"
                    + String(now.getDate()).padStart(2, "0")

                for (let i = 0; i < root.events.length; i++) {
                    const ev = root.events[i]
                    if (!ev.time || ev.time === "All day") continue
                    const timeParts = ev.time.split(":")
                    if (timeParts.length < 2) continue
                    const eventDate = new Date(todayStr + "T" + ev.time.padStart(5, "0") + ":00")
                    if (isNaN(eventDate.getTime())) continue
                    const diffMs = eventDate.getTime() - now.getTime()
                    if (diffMs <= 0) continue
                    const diffMin = Math.floor(diffMs / 60000)
                    if (diffMin > 120) continue
                    const hours = Math.floor(diffMin / 60)
                    const mins = diffMin % 60
                    let timeStr = ""
                    if (hours > 0) timeStr += hours + "h "
                    timeStr += mins + "m"
                    return ev.title + " in " + timeStr
                }
                return ""
            }
        }
    }

    // ── gcalcli availability check ──
    Process {
        id: gcalCheck
        command: ["/usr/bin/which", "gcalcli"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                root.gcalAvailable = data.trim().length > 0
                if (root.gcalAvailable) root.fetchEvents()
            }
        }
    }

    Component.onCompleted: gcalCheck.running = true

    // ── Event fetcher ──
    Process {
        id: gcalFetch
        command: ["/usr/bin/bash", "-lc",
            "gcalcli agenda --nocolor --tsv $(date +%Y-%m-%dT00:00) $(date +%Y-%m-%dT23:59) 2>/dev/null"
        ]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                root.eventsLoading = false
                const lines = data.trim().split("\n")
                const parsed = []
                for (const line of lines) {
                    if (line.trim() === "") continue
                    const parts = line.split("\t")
                    if (parts.length >= 4) {
                        const title = parts.slice(4).join(" ").trim()
                        if (title) {
                            parsed.push({
                                time: parts[1] || "All day",
                                endTime: parts[3] || "",
                                title: title
                            })
                        }
                    }
                }
                root.events = parsed
            }
        }
    }

    function fetchEvents() {
        root.eventsLoading = true
        gcalFetch.running = true
    }

    // Refresh events every 5 minutes
    Timer {
        running: root.visible && root.gcalAvailable
        interval: 300000
        repeat: true
        onTriggered: root.fetchEvents()
    }

    // Re-evaluate countdown every minute
    Timer {
        running: root.visible && root.gcalAvailable && root.events.length > 0
        interval: 60000
        repeat: true
        onTriggered: root._countdownTick++
    }
}
