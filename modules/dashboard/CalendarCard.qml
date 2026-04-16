pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.dashboard
import qs.services

DashboardCard {
    id: root
    headerText: ""

    readonly property var locale: Qt.locale()
    readonly property date today: DateTime.clock.date

    // ── Hero date display ──
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 12

        // Large day number
        StyledText {
            text: root.today.getDate().toString()
            font.pixelSize: 52
            font.weight: Font.Bold
            font.family: Appearance.font.family.numbers
            color: Appearance.colors.colPrimary
        }

        ColumnLayout {
            Layout.fillHeight: true
            spacing: 0
            Layout.alignment: Qt.AlignVCenter

            StyledText {
                text: root.today.toLocaleDateString(root.locale, "MMMM").toUpperCase()
                font.pixelSize: 13
                font.weight: Font.DemiBold
                font.letterSpacing: 1.0
                color: Qt.rgba(1, 1, 1, 0.35)
            }

            StyledText {
                text: root.today.toLocaleDateString(root.locale, "yyyy")
                font.pixelSize: 13
                color: Qt.rgba(1, 1, 1, 0.25)
            }

            StyledText {
                text: root.today.toLocaleDateString(root.locale, "dddd")
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer0
            }
        }
    }

    // ── Separator ──
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Qt.rgba(1, 1, 1, 0.04)
    }

    // ── Upcoming events ──
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6
        visible: Events.list.length > 0

        StyledText {
            text: "UPCOMING"
            font.pixelSize: 10
            font.weight: Font.DemiBold
            font.letterSpacing: 1.5
            color: Qt.rgba(1, 1, 1, 0.3)
        }

        Repeater {
            // Show up to 3 upcoming events
            model: Events.list.slice(0, 3)

            RowLayout {
                id: eventRow
                required property var modelData
                Layout.fillWidth: true
                spacing: 10

                // Color dot
                Rectangle {
                    implicitWidth: 8
                    implicitHeight: 8
                    radius: 4
                    color: Appearance.colors.colPrimary
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    StyledText {
                        Layout.fillWidth: true
                        text: eventRow.modelData.title ?? eventRow.modelData.summary ?? ""
                        font.pixelSize: 11
                        color: Appearance.colors.colOnLayer0
                        elide: Text.ElideRight
                    }

                    StyledText {
                        text: eventRow.modelData.time ?? ""
                        font.pixelSize: 10
                        color: Qt.rgba(1, 1, 1, 0.3)
                        visible: text !== ""
                    }
                }
            }
        }
    }

    // ── No events placeholder ──
    StyledText {
        visible: Events.list.length === 0
        Layout.fillWidth: true
        text: "No upcoming events"
        font.pixelSize: 11
        color: Qt.rgba(1, 1, 1, 0.2)
        horizontalAlignment: Text.AlignHCenter
        Layout.topMargin: 8
    }

    Item { Layout.fillHeight: true }
}
