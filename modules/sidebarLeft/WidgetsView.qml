pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.sidebarLeft.widgets
import qs.services
import "root:"

Item {
    id: root
    
    // Exponer editMode para bloquear swipe del SwipeView padre
    readonly property bool editMode: widgetContainer.editMode
    
    // Animation state - start true if sidebar already open
    property bool animateIn: GlobalStates.sidebarLeftOpen
    
    Connections {
        target: GlobalStates
        function onSidebarLeftOpenChanged() {
            if (GlobalStates.sidebarLeftOpen) {
                root.animateIn = false
                animateInTimer.restart()
            } else {
                root.animateIn = false
            }
        }
    }
    
    Timer {
        id: animateInTimer
        interval: 50
        onTriggered: root.animateIn = true
    }

    Flickable {
        id: flickable
        anchors.fill: parent
        contentHeight: mainColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        // Bloquear scroll horizontal cuando se arrastra widget
        interactive: !root.editMode

        ColumnLayout {
            id: mainColumn
            width: flickable.width
            spacing: 0

            // Time header (always at top)
            GlanceHeader {
                id: glanceHeader
                Layout.fillWidth: true
                Layout.bottomMargin: 8
                
                opacity: root.animateIn ? 1 : 0
                scale: root.animateIn ? 1 : 0.97
                transformOrigin: Item.Top
                transform: Translate { y: root.animateIn ? 0 : 18 }
                
                Behavior on opacity {
                    enabled: Appearance.animationsEnabled
                    NumberAnimation { 
                        duration: 450
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
                    }
                }
                Behavior on scale {
                    enabled: Appearance.animationsEnabled
                    NumberAnimation { 
                        duration: 500
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
                    }
                }
                Behavior on transform {
                    enabled: Appearance.animationsEnabled
                    NumberAnimation { 
                        duration: 450
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
                    }
                }
            }

            // Draggable widgets container
            DraggableWidgetContainer {
                id: widgetContainer
                Layout.fillWidth: true
                animateIn: root.animateIn
            }

            Item { Layout.preferredHeight: 12 }
        }
    }
}
