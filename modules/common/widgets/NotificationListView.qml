pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import Quickshell

StyledListView { // Scrollable window
    id: root
    property bool popup: false

    spacing: 3

    // Sidebar: full transitions with pop-in; Popup: no built-in transitions
    popin: !popup
    animateAppearance: !popup

    // Entry animation for popup mode — slide from anchor side
    property bool isRightAnchored: {
        const pos = Config.options?.notifications?.position ?? "topRight"
        return pos.includes("Right")
    }

    // Custom add transition for popup (slide-in from edge)
    add: Transition {
        enabled: root.popup
        NumberAnimation {
            property: "x"
            from: root.isRightAnchored ? 400 : -400
            to: 0
            duration: 400
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            property: "opacity"
            from: 0
            to: 1
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    // Smooth displacement when new notifications push existing ones
    addDisplaced: Transition {
        enabled: root.popup
        NumberAnimation {
            properties: "y"
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    // Custom removeDisplaced for popup mode: smooth gap-filling when a group is dismissed.
    // Uses elementMoveFast (200ms) for snappy feel without Wayland stair-stepping.
    removeDisplaced: Transition {
        enabled: root.popup
        NumberAnimation {
            property: "y"
            duration: Appearance.animation.elementMoveFast.duration
            easing.type: Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
        }
        NumberAnimation {
            property: "opacity"
            to: 1
            duration: Appearance.animation.elementMoveFast.duration
            easing.type: Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
        }
    }

    model: ScriptModel {
        values: root.popup ? Notifications.popupAppNameList : Notifications.appNameList
    }
    delegate: NotificationGroup {
        required property int index
        required property var modelData
        popup: root.popup
        anchors.left: parent?.left
        anchors.right: parent?.right
        notificationGroup: popup ?
            Notifications.popupGroupsByAppName[modelData] :
            Notifications.groupsByAppName[modelData]
    }
}
