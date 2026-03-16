pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
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

    // ── Day + date ──
    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: {
            const d = new Date()
            const days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
            const months = ["January", "February", "March", "April", "May", "June",
                            "July", "August", "September", "October", "November", "December"]
            return days[d.getDay()] + ", " + months[d.getMonth()] + " " + d.getDate()
        }
        font.pixelSize: Appearance.font.pixelSize.normal
        font.weight: Font.Medium
        color: Appearance.colors.colSubtext
    }

    // ── Month header with navigation ──
    RowLayout {
        Layout.fillWidth: true
        spacing: 0

        StyledText {
            Layout.fillWidth: true
            text: {
                const d = calendarView.focusedDate
                return d.toLocaleDateString(root.locale, "MMMM yyyy")
            }
            font.pixelSize: Appearance.font.pixelSize.normal
            font.weight: Font.DemiBold
            color: Appearance.colors.colOnLayer0
        }

        RippleButton {
            implicitWidth: 28; implicitHeight: 28
            buttonRadius: 14
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

        RippleButton {
            implicitWidth: 28; implicitHeight: 28
            buttonRadius: 14
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
    }

    // ── Day-of-week headers ──
    RowLayout {
        Layout.fillWidth: true
        spacing: 2

        Repeater {
            model: {
                const fdow = root.locale?.firstDayOfWeek ?? 1
                const items = []
                for (let i = 0; i < 7; i++) {
                    const dayIdx = (fdow + i) % 7
                    const dayNames = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
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
                font.weight: Font.Medium
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
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: dayDelegate.isToday ? Font.Bold : Font.Normal
                color: dayDelegate.isToday ? Appearance.colors.colOnPrimary
                     : dayDelegate.isCurrentMonth ? Appearance.colors.colOnLayer0
                     : ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.6)
            }
        }
    }
}
