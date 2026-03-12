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

    spacing: 8

    // ── Big time + day display ──
    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        // Large digital clock
        StyledText {
            text: DateTime.time
            font.pixelSize: 48
            font.family: Appearance.font.family.numbers
            font.weight: Font.Bold
            color: Appearance.colors.colPrimary
        }

        // Day name + full date (right side)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                text: {
                    const d = new Date()
                    const days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
                    return days[d.getDay()]
                }
                font.pixelSize: Appearance.font.pixelSize.larger
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer0
            }

            RowLayout {
                spacing: 4

                StyledText {
                    Layout.fillWidth: true
                    text: {
                        const d = calendarView.focusedDate
                        return d.toLocaleDateString(root.locale, "MMMM yyyy")
                    }
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }

                RippleButton {
                    implicitWidth: 20; implicitHeight: 20
                    buttonRadius: 10
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
                    implicitWidth: 20; implicitHeight: 20
                    buttonRadius: 10
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
        }
    }

    // ── Day-of-week headers (with month nav arrows on the right) ──
    RowLayout {
        Layout.fillWidth: true
        spacing: 0

        Repeater {
            model: {
                const fdow = root.locale?.firstDayOfWeek ?? 1
                const todayDow = new Date().getDay() // 0=Sun
                const items = []
                for (let i = 0; i < 7; i++) {
                    const dayIdx = (fdow + i) % 7
                    const dayNames = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
                    items.push({ name: dayNames[dayIdx], isToday: dayIdx === todayDow })
                }
                return items
            }

            Item {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 28

                Rectangle {
                    anchors.centerIn: parent
                    width: 26
                    height: 26
                    radius: 13
                    color: modelData.isToday ? Appearance.colors.colPrimary : "transparent"
                }

                StyledText {
                    anchors.centerIn: parent
                    text: modelData.name
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: modelData.isToday ? Font.Bold : Font.Medium
                    color: modelData.isToday ? Appearance.colors.colOnPrimary : Appearance.colors.colSubtext
                }
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
