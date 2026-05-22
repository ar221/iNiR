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
    buttonRadius: Appearance.sidebar.radiusSmall
    
    contentItem: Item {
        anchors.fill: parent
        
        StyledText {
            anchors.centerIn: parent
            text: button.day
            horizontalAlignment: Text.AlignHCenter
            font.weight: button.bold ? Font.DemiBold : Font.Normal
            color: button.isHeader && (button.isToday == 1) 
                ? Appearance.sidebar.colAccent
                : (button.isToday == 1) 
                    ? Appearance.sidebar.colOnAccent
                    : (button.isToday == 0) 
                        ? Appearance.sidebar.colText
                        : Appearance.sidebar.colTextSecondary

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
                ? Appearance.sidebar.colOnAccent
                : Appearance.sidebar.colAccent
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
            color: Appearance.sidebar.colAccent

            StyledText {
                anchors.centerIn: parent
                text: button.eventCount > 9 ? "9+" : button.eventCount
                font.pixelSize: 9
                font.weight: Font.Bold
                color: Appearance.sidebar.colOnAccent
            }
        }
    }
}
