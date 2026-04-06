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

    // ── Month/Year navigation row ──
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 8
        spacing: 0

        // Month nav: < monthName >
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

        // Year display
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
                    // Build a date known to be that day of week, get short name
                    const refDate = new Date(2024, 0, 7 + dayIdx) // 2024-01-07 is Sunday
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

    // ── Full-width calendar grid ──
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
