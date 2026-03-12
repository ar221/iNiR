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

    spacing: 6

    // Month + year header with navigation
    RowLayout {
        Layout.fillWidth: true
        spacing: 4

        StyledText {
            Layout.fillWidth: true
            text: {
                const d = calendarView.focusedDate
                return d.toLocaleDateString(root.locale, "MMMM yyyy")
            }
            font.pixelSize: Appearance.font.pixelSize.small
            font.weight: Font.DemiBold
            color: Appearance.colors.colOnLayer0
        }

        RippleButton {
            implicitWidth: 22; implicitHeight: 22
            buttonRadius: 11
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
            implicitWidth: 22; implicitHeight: 22
            buttonRadius: 11
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
        spacing: 2

        Repeater {
            model: {
                const fdow = root.locale?.firstDayOfWeek ?? 1
                const names = []
                for (let i = 0; i < 7; i++) {
                    const dayIdx = (fdow + i) % 7
                    const dayNames = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
                    names.push(dayNames[dayIdx])
                }
                return names
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

    // Calendar grid
    CalendarView {
        id: calendarView
        Layout.fillWidth: true
        locale: root.locale
        buttonSize: 26
        buttonSpacing: 1
        paddingWeeks: 1

        delegate: Item {
            id: dayDelegate
            required property var model
            implicitWidth: 26
            implicitHeight: 26

            readonly property bool isToday: model.today
            readonly property bool isCurrentMonth: model.month === root.currentMonth

            Rectangle {
                anchors.centerIn: parent
                width: 24
                height: 24
                radius: 12
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
}
