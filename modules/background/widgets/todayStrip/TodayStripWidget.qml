pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.common.functions
import qs.modules.background.widgets
import qs.services

// Today Strip — a compact horizontal Courier Console dispatch board.
// Five equal-width cells: TIME · NEXT · WEATHER · TASK · REMINDER.
// Standalone AbstractBackgroundWidget; sits alongside TimeCalendarWidget.
AbstractBackgroundWidget {
    id: root

    configEntryName: "todayStrip"

    readonly property var stripConfig: configEntry
    readonly property real cardWidth: stripConfig?.cardWidth ?? 720
    readonly property real cardOpacity: stripConfig?.cardOpacity ?? 0.85
    readonly property bool showWeather: stripConfig?.showWeather ?? true
    readonly property bool showTask: stripConfig?.showTask ?? true
    readonly property bool showReminder: stripConfig?.showReminder ?? true
    readonly property point screenPos: root.mapToItem(null, 0, 0)
    readonly property var locale: Qt.locale()
    readonly property date today: DateTime.clock.date

    // TIME + NEXT are always visible; the other three are toggleable.
    readonly property int visibleCellCount: 2
        + (showWeather ? 1 : 0)
        + (showTask ? 1 : 0)
        + (showReminder ? 1 : 0)
    readonly property real cellWidth: Math.floor(cardWidth / Math.max(1, visibleCellCount))
    // Divider suppression for the last visible cell is derived positionally
    // inside StripCell (StripCell._isLastVisible) — reorder-safe, no index map.

    // ── "next event" state — sourced from CalendarSync (caldav-events.json) ──
    // gcalcli is not installed on this system; the calendar-sync pipeline
    // populates caldav-events.json, which the CalendarSync singleton already
    // watches + parses. We consume that service rather than re-reading the file.
    property int _countdownTick: 0

    // First timed event today whose start is still in the future. Re-evaluates
    // when CalendarSync reloads the file AND every minute via _countdownTick, so
    // a just-passed event drops off and the next one surfaces without a resync.
    // All-day events are skipped (matches the old gcalcli "All day" hard-skip).
    readonly property var nextEvent: {
        void root._countdownTick // re-eval every minute
        const list = CalendarSync.list // re-eval on file reload
        if (!list || list.length === 0)
            return null
        const now = new Date()
        const todays = CalendarSync.getEventsForDate(now)
        const future = todays.filter(e =>
            !e.allDay && !isNaN(new Date(e.dateTime).getTime())
            && new Date(e.dateTime).getTime() > now.getTime()
        )
        if (future.length === 0)
            return null
        future.sort((a, b) => new Date(a.dateTime).getTime() - new Date(b.dateTime).getTime())
        const ev = future[0]
        return { time: ev.time, title: ev.title }
    }

    // ── oc-vault glance state ──
    property string glanceTask: ""
    property string glanceReminder: ""

    implicitWidth: cardWidth
    implicitHeight: cardContent.implicitHeight + cardContent.anchors.margins * 2

    // ── Drop shadow ──
    StyledRectangularShadow {
        target: cardBackground
        visible: !Appearance.inirEverywhere && !Appearance.auroraEverywhere
    }

    // ── Glass card background (Courier Console: square / micro-radius) ──
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

    // ── Content: five equal-width cells ──
    RowLayout {
        id: cardContent
        anchors.fill: parent
        anchors.margins: 4
        spacing: 0

        // ── Cell 1 — TIME (always visible) ──
        StripCell {
            Layout.preferredWidth: root.cellWidth
            Layout.fillHeight: true
            // Pin the layout's height floor to this cell's content-driven
            // implicitHeight, making the content→layout sizing direction
            // explicit so a future refactor can't introduce a cycle.
            Layout.minimumHeight: implicitHeight
            label: "TIME"

            ColumnLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 1

                StyledText {
                    Layout.fillWidth: true
                    text: DateTime.time
                    font.family: Appearance.font.family.numbers
                    font.pixelSize: Appearance.font.pixelSize.huge
                    font.weight: Font.Bold
                    color: Appearance.colors.colPrimary
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                StyledText {
                    Layout.fillWidth: true
                    text: {
                        const d = root.today
                        const dow = d.toLocaleDateString(root.locale, "ddd").toLowerCase()
                        const day = d.getDate()
                        const mon = d.toLocaleDateString(root.locale, "MMM").toLowerCase()
                        return dow + " " + day + " " + mon
                    }
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: Font.Medium
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }
        }

        // ── Cell 2 — NEXT (always visible) ──
        StripCell {
            Layout.preferredWidth: root.cellWidth
            Layout.fillHeight: true
            Layout.minimumHeight: implicitHeight
            label: "NEXT"

            ColumnLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 1

                CourierReceipt {
                    Layout.fillWidth: true
                    visible: !root.nextEvent
                    density: "compact"
                    state: "EMPTY"
                    source: "caldav"
                    omitStateLabel: false
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: !!root.nextEvent
                    text: root.nextEvent ? (root.nextEvent.time + "  " + root.nextEvent.title) : ""
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer0
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: !!root.nextEvent && text !== ""
                    text: {
                        void root._countdownTick // re-eval every minute
                        if (!root.nextEvent) return ""
                        return root.countdownString(root.nextEvent.time)
                    }
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: Font.Medium
                    color: Appearance.colors.colPrimary
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }
        }

        // ── Cell 3 — WEATHER ──
        StripCell {
            Layout.preferredWidth: root.cellWidth
            Layout.fillHeight: true
            Layout.minimumHeight: implicitHeight
            visible: root.showWeather
            label: "WEATHER"

            ColumnLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 1

                readonly property bool hasWeather: {
                    const t = String(Weather.data?.temp ?? "")
                    return t.length > 0 && !t.startsWith("--")
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: !parent.hasWeather
                    text: "—"
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Bold
                    color: Appearance.colors.colSubtext
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: parent.hasWeather
                    text: Weather.data?.temp ?? ""
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnLayer0
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: parent.hasWeather
                    text: Weather.data?.description ?? ""
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: Font.Medium
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }
        }

        // ── Cell 4 — TASK ──
        StripCell {
            id: taskCell
            Layout.preferredWidth: root.cellWidth
            Layout.fillHeight: true
            Layout.minimumHeight: implicitHeight
            visible: root.showTask
            label: "TASK"

            ColumnLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 1

                StyledText {
                    Layout.fillWidth: true
                    visible: root.glanceTask.length === 0
                    text: "—"
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Bold
                    color: Appearance.colors.colSubtext
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: root.glanceTask.length > 0
                    text: root.glanceTask
                    font.pixelSize: Appearance.font.pixelSize.smallie
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer0
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                    maximumLineCount: 3
                }
            }

            PopupToolTip {
                text: root.glanceTask
                anchorEdges: Edges.Bottom
                extraVisibleCondition: false
                alternativeVisibleCondition: taskCell.hovered && root.glanceTask.length > 0
            }
        }

        // ── Cell 5 — REMINDER ──
        StripCell {
            id: reminderCell
            Layout.preferredWidth: root.cellWidth
            Layout.fillHeight: true
            Layout.minimumHeight: implicitHeight
            visible: root.showReminder
            label: "REMINDER"

            ColumnLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 1

                StyledText {
                    Layout.fillWidth: true
                    visible: root.glanceReminder.length === 0
                    text: "—"
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Bold
                    color: Appearance.colors.colSubtext
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: root.glanceReminder.length > 0
                    text: root.glanceReminder
                    font.pixelSize: Appearance.font.pixelSize.smallie
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer0
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                    maximumLineCount: 3
                }
            }

            PopupToolTip {
                text: root.glanceReminder
                anchorEdges: Edges.Bottom
                extraVisibleCondition: false
                alternativeVisibleCondition: reminderCell.hovered && root.glanceReminder.length > 0
            }
        }
    }

    // ── Countdown math — "in 28m" / "in 1h 5m" for an HH:MM event today ──
    function countdownString(eventTime) {
        if (!eventTime || eventTime === "All day") return ""
        const timeParts = eventTime.split(":")
        if (timeParts.length < 2) return ""
        const now = new Date()
        const todayStr = now.getFullYear() + "-"
            + String(now.getMonth() + 1).padStart(2, "0") + "-"
            + String(now.getDate()).padStart(2, "0")
        const eventDate = new Date(todayStr + "T" + eventTime.padStart(5, "0") + ":00")
        if (isNaN(eventDate.getTime())) return ""
        const diffMs = eventDate.getTime() - now.getTime()
        if (diffMs <= 0) return ""
        const diffMin = Math.floor(diffMs / 60000)
        const hours = Math.floor(diffMin / 60)
        const mins = diffMin % 60
        let timeStr = ""
        if (hours > 0) timeStr += hours + "h "
        timeStr += mins + "m"
        return "in " + timeStr
    }

    // ── oc-vault glance fetcher — emits one TSV line: task<TAB>reminder ──
    Process {
        id: glanceFetch
        command: ["/usr/bin/bash", "-lc", "oc-vault glance 2>/dev/null"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                // NOTE: do NOT .trim() the whole line — \t is whitespace, so
                // trimming an empty-task line would shift the reminder into parts[0].
                const line = String(data).replace(/[\r\n]+$/, "")
                const parts = line.split("\t")
                root.glanceTask = (parts[0] ?? "").trim()
                root.glanceReminder = (parts[1] ?? "").trim()
            }
        }
    }

    function fetchGlance() {
        glanceFetch.running = true
    }

    Component.onCompleted: {
        Weather.ensureRunning()
        fetchGlance()
    }

    onVisibleChanged: {
        if (visible)
            root.fetchGlance()
    }

    // Refresh the vault glance every 5 minutes
    Timer {
        running: root.visible
        interval: 300000
        repeat: true
        onTriggered: root.fetchGlance()
    }

    // Re-evaluate the countdown every minute. Gated only on visibility (not on
    // nextEvent) so when an event's start time passes, the tick keeps firing,
    // nextEvent recomputes, and the next upcoming event surfaces on its own.
    Timer {
        running: root.visible
        interval: 60000
        repeat: true
        onTriggered: root._countdownTick++
    }
}
