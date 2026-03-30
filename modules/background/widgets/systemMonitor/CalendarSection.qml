pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

ColumnLayout {
    id: root

    property var configEntry: ({})
    readonly property var locale: Qt.locale()
    readonly property date today: DateTime.clock.date
    readonly property int currentMonth: calendarView.focusedMonth
    property var events: []
    property bool gcalAvailable: false
    property bool loading: false

    spacing: 12

    // ── Clock ──
    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: DateTime.time
        font.pixelSize: 52
        font.family: Appearance.font.family.numbers
        font.weight: Font.Bold
        color: Appearance.colors.colPrimary
    }

    // ── Two-column calendar layout ──
    RowLayout {
        Layout.fillWidth: true
        spacing: 16

    // ── Left column: Day, date, events ──
    ColumnLayout {
        Layout.fillHeight: true
        Layout.preferredWidth: root.width * 0.35
        Layout.alignment: Qt.AlignTop
        spacing: 4

        // Day name (uppercase)
        StyledText {
            text: {
                const days = ["SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY"]
                return days[root.today.getDay()]
            }
            font.pixelSize: Appearance.font.pixelSize.small
            font.weight: Font.Medium
            font.letterSpacing: 1.5
            color: Appearance.colors.colSubtext
        }

        // Large date number
        StyledText {
            text: root.today.getDate().toString()
            font.pixelSize: 64
            font.family: Appearance.font.family.numbers
            font.weight: Font.Light
            color: Appearance.colors.colOnLayer0
            Layout.topMargin: -8
            Layout.bottomMargin: -4
        }

        Item { Layout.fillHeight: true }

        // Events summary
        StyledText {
            text: {
                if (!root.gcalAvailable) return ""
                if (root.loading) return "Loading..."
                if (root.events.length === 0) return "No events today"
                const n = root.events.length
                return n + " event" + (n > 1 ? "s" : "") + " today"
            }
            visible: text !== ""
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colSubtext
        }
    }

    // ── Right column: Month grid ──
    ColumnLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignTop
        spacing: 6

        // Month name + navigation
        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: {
                    const d = calendarView.focusedDate
                    return d.toLocaleDateString(root.locale, "MMMM").toUpperCase()
                }
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.Medium
                font.letterSpacing: 1.5
                color: Appearance.colors.colSubtext
            }

            RippleButton {
                implicitWidth: 24; implicitHeight: 24
                buttonRadius: 12
                colBackground: "transparent"
                colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.85)
                onClicked: calendarView.scrollMonthsAndSnap(-1)
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: "chevron_left"
                    iconSize: 14
                    color: Appearance.colors.colSubtext
                }
            }

            RippleButton {
                implicitWidth: 24; implicitHeight: 24
                buttonRadius: 12
                colBackground: "transparent"
                colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.85)
                onClicked: calendarView.scrollMonthsAndSnap(1)
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: "chevron_right"
                    iconSize: 14
                    color: Appearance.colors.colSubtext
                }
            }
        }

        // Day-of-week headers
        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            Repeater {
                model: {
                    const fdow = root.locale?.firstDayOfWeek ?? 1
                    const items = []
                    for (let i = 0; i < 7; i++) {
                        const dayIdx = (fdow + i) % 7
                        const dayNames = ["S", "M", "T", "W", "T", "F", "S"]
                        items.push(dayNames[dayIdx])
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

        // Calendar grid
        CalendarView {
            id: calendarView
            Layout.fillWidth: true
            locale: root.locale
            buttonSize: 28
            buttonSpacing: 1
            paddingWeeks: 1

            delegate: Item {
                id: dayDelegate
                required property var model
                implicitWidth: 28
                implicitHeight: 28

                readonly property bool isToday: model.today
                readonly property bool isCurrentMonth: model.month === root.currentMonth

                Rectangle {
                    anchors.centerIn: parent
                    width: 26
                    height: 26
                    radius: 13
                    color: dayDelegate.isToday ? Appearance.colors.colPrimary : "transparent"
                    border.width: dayDelegate.isToday ? 0 : 0
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
    }

    } // end RowLayout

    // ── Event fetching (gcalcli) ──
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

    Process {
        id: gcalFetch
        command: ["/usr/bin/bash", "-lc",
            "gcalcli agenda --nocolor --tsv $(date +%Y-%m-%dT00:00) $(date +%Y-%m-%dT23:59) 2>/dev/null"
        ]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                root.loading = false
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
        root.loading = true
        gcalFetch.running = true
    }

    Timer {
        running: root.visible && root.gcalAvailable
        interval: 300000
        repeat: true
        onTriggered: root.fetchEvents()
    }
}
