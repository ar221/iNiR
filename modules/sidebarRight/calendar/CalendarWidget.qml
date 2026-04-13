pragma ComponentBehavior: Bound
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import "calendar_layout.js" as CalendarLayout
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root

    // Emitted when a day with events is clicked, carrying the date
    signal dayWithEventsClicked(var date)
    
    // Selected date for inline event display (null = none selected)
    property var selectedDate: null

    // Trigger to force recomputation when events change
    property int _eventsTrigger: 0
    Connections {
        target: Events
        function onEventAdded(event) { root._eventsTrigger++ }
        function onEventRemoved(id) { root._eventsTrigger++ }
        function onEventUpdated(event) { root._eventsTrigger++ }
    }
    Connections {
        target: CalendarSync
        function onEventsChanged() { root._eventsTrigger++ }
    }

    // Style tokens (5-style support)
    readonly property color colText: Appearance.angelEverywhere ? Appearance.angel.colText
        : Appearance.inirEverywhere ? Appearance.inir.colText : Appearance.colors.colOnLayer1
    readonly property color colTextSecondary: Appearance.angelEverywhere ? Appearance.angel.colTextSecondary
        : Appearance.inirEverywhere ? Appearance.inir.colTextSecondary : Appearance.colors.colSubtext
    readonly property color colPrimary: Appearance.angelEverywhere ? Appearance.angel.colPrimary
        : Appearance.inirEverywhere ? Appearance.inir.colPrimary : Appearance.colors.colPrimary
    readonly property color colCard: Appearance.angelEverywhere ? Appearance.angel.colGlassCard
        : Appearance.inirEverywhere ? Appearance.inir.colLayer1
        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurface
        : Appearance.colors.colLayer1
    readonly property real radius: Appearance.angelEverywhere ? Appearance.angel.roundingSmall
        : Appearance.inirEverywhere ? Appearance.inir.roundingSmall : Appearance.rounding.small

    property var locale: {
        const envLocale = Quickshell.env("LC_TIME") || Quickshell.env("LC_ALL") || Quickshell.env("LANG") || "";
        const cleaned = (envLocale.split(".")[0] ?? "").split("@")[0] ?? "";
        return cleaned ? Qt.locale(cleaned) : Qt.locale();
    }

    property list<var> weekDaysModel: {
        const fdow = locale?.firstDayOfWeek ?? Qt.locale().firstDayOfWeek;
        const first = DateUtils.getFirstDayOfWeek(new Date(), fdow);
        const days = [];
        for (let i = 0; i < 7; i++) {
            const d = new Date(first);
            d.setDate(first.getDate() + i);
            days.push({
                label: locale.toString(d, "ddd"),
                today: DateUtils.sameDate(d, DateTime.clock.date)
            });
        }
        return days;
    }

    property int monthShift: 0
    property var viewingDate: CalendarLayout.getDateInXMonthsTime(monthShift)
    property var calendarLayout: CalendarLayout.getCalendarLayout(viewingDate, monthShift === 0, locale?.firstDayOfWeek ?? 1)
    width: calendarColumn.width
    implicitHeight: calendarColumn.height + 10 * 2

    // Helper to get event count for a specific date
    function getEventCountForDay(day: int, weekRow: int, dayIndex: int): int {
        const _t = root._eventsTrigger // force dependency on trigger
        const cellData = root.calendarLayout[weekRow]?.[dayIndex]
        if (!cellData) return 0
        
        const year = root.viewingDate.getFullYear()
        const month = root.viewingDate.getMonth()
        
        // Adjust for days from adjacent months
        let targetMonth = month
        let targetYear = year
        if (cellData.today === -1) {
            // Previous month
            if (month === 0) {
                targetMonth = 11
                targetYear = year - 1
            } else {
                targetMonth = month - 1
            }
        }
        
        const targetDate = new Date(targetYear, targetMonth, day)
        return Events.getEventsForDate(targetDate).length + CalendarSync.getEventsForDate(targetDate).length
    }

    Keys.onPressed: (event) => {
        if ((event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp)
            && event.modifiers === Qt.NoModifier) {
            if (event.key === Qt.Key_PageDown) {
                monthShift++;
            } else if (event.key === Qt.Key_PageUp) {
                monthShift--;
            }
            event.accepted = true;
        }
    }
    MouseArea {
        anchors.fill: parent
        onWheel: (event) => {
            if (event.angleDelta.y > 0) {
                monthShift--;
            } else if (event.angleDelta.y < 0) {
                monthShift++;
            }
        }
    }

    ColumnLayout {
        id: calendarColumn
        anchors.centerIn: parent
        spacing: 8

        // Enhanced calendar header
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Today's date highlight
            Rectangle {
                visible: monthShift === 0
                Layout.preferredWidth: todayCol.implicitWidth + 16
                Layout.preferredHeight: todayCol.implicitHeight + 8
                radius: root.radius
                color: root.colPrimary

                ColumnLayout {
                    id: todayCol
                    anchors.centerIn: parent
                    spacing: -2

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: DateTime.clock.date.getDate()
                        font.pixelSize: Appearance.font.pixelSize.larger
                        font.weight: Font.Bold
                        font.family: Appearance.font.family.numbers
                        color: Appearance.angelEverywhere ? Appearance.angel.colOnPrimary
                            : Appearance.inirEverywhere ? Appearance.inir.colOnPrimary
                            : Appearance.colors.colOnPrimary
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: locale.toString(DateTime.clock.date, "ddd")
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.weight: Font.Medium
                        color: Appearance.angelEverywhere ? Appearance.angel.colOnPrimary
                            : Appearance.inirEverywhere ? Appearance.inir.colOnPrimary
                            : Appearance.colors.colOnPrimary
                        opacity: 0.9
                    }
                }
            }

            // Month/Year title
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    text: locale.toString(viewingDate, "MMMM")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: root.colText
                }

                StyledText {
                    text: locale.toString(viewingDate, "yyyy")
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: root.colTextSecondary
                }
            }

            // Navigation buttons
            RowLayout {
                spacing: 4

                // Jump to today (when not viewing current month)
                CalNavButton {
                    visible: monthShift !== 0
                    icon: "today"
                    tooltipText: Translation.tr("Jump to today")
                    onClicked: monthShift = 0
                }

                CalNavButton {
                    icon: "chevron_left"
                    tooltipText: Translation.tr("Previous month")
                    onClicked: monthShift--
                }

                CalNavButton {
                    icon: "chevron_right"
                    tooltipText: Translation.tr("Next month")
                    onClicked: monthShift++
                }
            }
        }

        // Week days row
        RowLayout {
            id: weekDaysRow
            Layout.alignment: Qt.AlignHCenter
            Layout.fillHeight: false
            Layout.topMargin: 4
            spacing: 5
            Repeater {
                model: weekDaysModel
                delegate: CalendarDayButton {
                    required property var modelData
                    day: modelData.label
                    isToday: modelData.today ? 1 : 0
                    isHeader: true
                    bold: true
                    enabled: false
                }
            }
        }

        // Real week rows
        Repeater {
            id: calendarRows
            model: 6
            delegate: RowLayout {
                required property int index
                property int weekRow: index
                Layout.alignment: Qt.AlignHCenter
                Layout.fillHeight: false
                spacing: 5
                Repeater {
                    model: Array(7).fill(parent.weekRow)
                    delegate: CalendarDayButton {
                        required property int index
                        required property int modelData
                        day: root.calendarLayout[modelData][index].day
                        isToday: root.calendarLayout[modelData][index].today
                        eventCount: root.getEventCountForDay(root.calendarLayout[modelData][index].day, modelData, index)
                        onClicked: {
                            const cellData = root.calendarLayout[modelData][index]
                            const year = root.viewingDate.getFullYear()
                            const month = root.viewingDate.getMonth()
                            let targetMonth = month
                            let targetYear = year
                            if (cellData.today === -1) {
                                if (month === 0) { targetMonth = 11; targetYear = year - 1 }
                                else targetMonth = month - 1
                            }
                            const clickedDate = new Date(targetYear, targetMonth, cellData.day)
                            // Toggle: click same date again to collapse
                            if (root.selectedDate && root.selectedDate.getTime() === clickedDate.getTime())
                                root.selectedDate = null
                            else
                                root.selectedDate = clickedDate
                            root.dayWithEventsClicked(clickedDate)
                        }
                    }
                }
            }
        }

        // Inline events for selected date
        DayEventsPanel {
            visible: root.selectedDate !== null
            Layout.fillWidth: true
            Layout.topMargin: 4
            date: root.selectedDate ?? new Date()
        }
    }

    // Reset selection when navigating months
    onMonthShiftChanged: selectedDate = null

    // Inline day events panel — appears below grid when a date is clicked
    component DayEventsPanel: ColumnLayout {
        id: dayPanel
        required property var date
        spacing: 4

        readonly property var localEvents: {
            const _t = root._eventsTrigger
            return Events.getAllEventsForDate(date)
        }
        readonly property var caldavEvents: {
            const _t = root._eventsTrigger
            return CalendarSync.getEventsForDate(date)
        }
        readonly property bool hasEvents: localEvents.length > 0 || caldavEvents.length > 0

        // Date header
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            StyledText {
                text: root.locale.toString(dayPanel.date, "ddd, d MMM")
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.DemiBold
                color: root.colText
            }

            Item { Layout.fillWidth: true }

            // CalDAV sync indicator
            StyledText {
                visible: CalendarSync.available && CalendarSync.lastSync !== ""
                text: "synced"
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: root.colTextSecondary
                opacity: 0.6
            }
        }

        // No events placeholder
        StyledText {
            visible: !dayPanel.hasEvents
            text: Translation.tr("No events")
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: root.colTextSecondary
        }

        // CalDAV events
        Repeater {
            model: dayPanel.caldavEvents

            Rectangle {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                Layout.preferredHeight: caldavEventRow.implicitHeight + 8
                radius: root.radius
                color: Appearance.angelEverywhere ? ColorUtils.transparentize(Appearance.angel.colPrimary, 0.85)
                    : Appearance.inirEverywhere ? Appearance.inir.colLayer1
                    : ColorUtils.transparentize(Appearance.colors.colSurfaceContainer, 0.4)

                RowLayout {
                    id: caldavEventRow
                    anchors.fill: parent
                    anchors.margins: 4
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 6

                    Rectangle {
                        Layout.preferredWidth: 3
                        Layout.fillHeight: true
                        radius: 1.5
                        color: index === 0 ? root.colPrimary
                            : Appearance.angelEverywhere ? Appearance.angel.colSecondary
                            : Appearance.inirEverywhere ? Appearance.inir.colSecondary
                            : Appearance.colors.colSecondary
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: modelData.title || ""
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            font.weight: Font.Medium
                            color: root.colText
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        RowLayout {
                            spacing: 4
                            StyledText {
                                text: {
                                    const t = modelData.time || ""
                                    if (modelData.endTime)
                                        return t + " – " + modelData.endTime
                                    return t
                                }
                                font.pixelSize: Appearance.font.pixelSize.smallest
                                color: root.colTextSecondary
                            }
                            StyledText {
                                visible: (modelData.location || "") !== ""
                                text: "· " + (modelData.location || "")
                                font.pixelSize: Appearance.font.pixelSize.smallest
                                color: root.colTextSecondary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }

        // Local events
        Repeater {
            model: dayPanel.localEvents

            Rectangle {
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: localEventRow.implicitHeight + 8
                radius: root.radius
                color: Appearance.angelEverywhere ? ColorUtils.transparentize(Appearance.angel.colPrimary, 0.85)
                    : Appearance.inirEverywhere ? Appearance.inir.colLayer1
                    : ColorUtils.transparentize(Appearance.colors.colSurfaceContainer, 0.4)

                RowLayout {
                    id: localEventRow
                    anchors.fill: parent
                    anchors.margins: 4
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 6

                    MaterialSymbol {
                        text: Events.getCategoryIcon(modelData.category || "general")
                        iconSize: 14
                        color: root.colTextSecondary
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: modelData.title || ""
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            font.weight: Font.Medium
                            color: root.colText
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        StyledText {
                            visible: (modelData.dateTime || "") !== ""
                            text: {
                                const d = new Date(modelData.dateTime)
                                return d.toLocaleTimeString(root.locale, "HH:mm")
                            }
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            color: root.colTextSecondary
                        }
                    }
                }
            }
        }
    }

    // Navigation button component
    component CalNavButton: Item {
        id: navBtn
        required property string icon
        property string tooltipText: ""

        signal clicked()

        implicitWidth: 32
        implicitHeight: 32

        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: {
                if (navBtnMA.containsPress)
                    return Appearance.angelEverywhere ? Appearance.angel.colGlassCardActive
                        : Appearance.inirEverywhere ? Appearance.inir.colLayer1Active
                        : Appearance.colors.colLayer1Active
                if (navBtnMA.containsMouse)
                    return Appearance.angelEverywhere ? Appearance.angel.colGlassCardHover
                        : Appearance.inirEverywhere ? Appearance.inir.colLayer1Hover
                        : Appearance.colors.colLayer1Hover
                return "transparent"
            }
            Behavior on color { ColorAnimation { duration: Appearance.animation.elementMoveFast.duration } }

            MaterialSymbol {
                anchors.centerIn: parent
                text: navBtn.icon
                iconSize: 18
                color: root.colTextSecondary
            }

            MouseArea {
                id: navBtnMA
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: navBtn.clicked()
            }

            StyledToolTip {
                visible: navBtnMA.containsMouse && navBtn.tooltipText !== ""
                text: navBtn.tooltipText
            }
        }
    }
}