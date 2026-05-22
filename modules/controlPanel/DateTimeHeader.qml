pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root
    Layout.fillWidth: true
    implicitHeight: dateTimeRow.implicitHeight + 24
    
    readonly property bool inirEverywhere: Appearance.inirEverywhere
    readonly property bool auroraEverywhere: Appearance.auroraEverywhere
    
    // Reactive property to force date re-evaluation
    property int _tick: 0
    readonly property date _currentDate: { _tick; return new Date() }

    radius: Appearance.controlPanel.radiusCard
    color: Appearance.controlPanel.colCard
    border.width: Appearance.controlPanel.borderWidth
    border.color: Appearance.controlPanel.colCardBorder

    AngelPartialBorder { targetRadius: parent.radius; coverage: 0.45 }

    RowLayout {
        id: dateTimeRow
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                text: Qt.formatDateTime(root._currentDate, "dddd")
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.Medium
                color: Appearance.controlPanel.colAccent
            }

            StyledText {
                text: Qt.formatDateTime(root._currentDate, "MMMM d, yyyy")
                font.pixelSize: Appearance.font.pixelSize.larger
                font.weight: Font.Medium
                color: Appearance.controlPanel.colText
            }

            StyledText {
                text: Translation.tr("Uptime") + ": " + DateTime.uptime
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.controlPanel.colTextSecondary
            }
        }

        StyledText {
            text: DateTime.time
            font.pixelSize: Appearance.font.pixelSize.huge * 1.5
            font.weight: Font.Light
            font.family: Appearance.font.family.numbers
            color: Appearance.controlPanel.colText
        }
    }

    Timer {
        interval: 60000  // Update every minute (day/date don't need second precision)
        running: GlobalStates.controlPanelOpen
        repeat: true
        triggeredOnStart: true
        onTriggered: root._tick++
    }
}
