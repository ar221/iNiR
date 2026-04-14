import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

RippleButton {
    id: button
    property string day
    property int isToday
    property bool bold
    property bool isHeader: false  // True for weekday labels (Mon, Tue, etc.)
    property int eventCount: 0  // Number of events on this day

    Layout.fillWidth: false
    Layout.fillHeight: false
    implicitWidth: 38; 
    implicitHeight: 38;

    toggled: (isToday == 1) && !isHeader  // Headers don't get toggled background
    buttonRadius: Appearance.angelEverywhere ? Appearance.angel.roundingSmall
        : Appearance.inirEverywhere ? Appearance.inir.roundingSmall : Appearance.rounding.small
    
    contentItem: Item {
        anchors.fill: parent
        
        StyledText {
            anchors.centerIn: parent
            text: button.day
            horizontalAlignment: Text.AlignHCenter
            font.weight: button.bold ? Font.DemiBold : Font.Normal
            color: button.isHeader && (button.isToday == 1) 
                ? (Appearance.angelEverywhere ? Appearance.angel.colPrimary
                    : Appearance.inirEverywhere ? Appearance.inir.colPrimary : Appearance.colors.colPrimary)
                : (button.isToday == 1) 
                    ? (Appearance.angelEverywhere ? Appearance.angel.colOnPrimary
                        : Appearance.inirEverywhere ? Appearance.inir.colOnPrimary : Appearance.colors.colOnPrimary)
                    : (button.isToday == 0) 
                        ? (Appearance.angelEverywhere ? Appearance.angel.colText
                            : Appearance.inirEverywhere ? Appearance.inir.colText : Appearance.colors.colOnLayer1)
                        : (Appearance.angelEverywhere ? Appearance.angel.colTextSecondary
                            : Appearance.inirEverywhere ? Appearance.inir.colTextSecondary 
                            : Appearance.auroraEverywhere ? Appearance.colors.colSubtext
                            : Appearance.colors.colOutlineVariant)

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
        }
        
        // Event indicator — bar at bottom, count badge in top-right when multiple
        Rectangle {
            id: eventBar
            visible: button.eventCount > 0 && !button.isHeader
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 3
            width: 12
            height: 3
            radius: 1.5
            color: button.isToday == 1
                ? (Appearance.angelEverywhere ? Appearance.angel.colOnPrimary
                    : Appearance.inirEverywhere ? Appearance.inir.colOnPrimary : Appearance.colors.colOnPrimary)
                : (Appearance.angelEverywhere ? Appearance.angel.colPrimary
                    : Appearance.inirEverywhere ? Appearance.inir.colPrimary : Appearance.colors.colPrimary)
        }

        // Count badge — top-right corner, only when >1 event
        Rectangle {
            visible: button.eventCount > 1 && !button.isHeader
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 2
            anchors.rightMargin: 2
            width: 13
            height: 13
            radius: 6.5
            color: Appearance.angelEverywhere ? Appearance.angel.colPrimary
                : Appearance.inirEverywhere ? Appearance.inir.colPrimary
                : Appearance.colors.colPrimary

            StyledText {
                anchors.centerIn: parent
                text: button.eventCount > 9 ? "9+" : button.eventCount
                font.pixelSize: 9
                font.weight: Font.Bold
                color: Appearance.angelEverywhere ? Appearance.angel.colOnPrimary
                    : Appearance.inirEverywhere ? Appearance.inir.colOnPrimary
                    : Appearance.colors.colOnPrimary
            }
        }
    }
}

