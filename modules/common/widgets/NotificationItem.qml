import qs
import qs.modules.common
import qs.services
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Services.Notifications

Item { // Notification item area
    id: root
    property var notificationObject
    property bool expanded: false
    property bool popup: false
    property bool onlyNotification: false
    property real fontSize: popup ? Appearance.font.pixelSize.normal : Appearance.font.pixelSize.small
    property real padding: onlyNotification ? 0 : 8
    property real summaryElideRatio: 0.85

    // Animation tokens — popup uses fast (200ms), sidebar uses standard (500ms)
    readonly property QtObject _dismissAnim: root.popup
        ? Appearance.animation.elementMoveFast
        : Appearance.animation.elementMove
    readonly property QtObject _contentAnim: Appearance.animation.elementMoveFast

    property real dragConfirmThreshold: 70 // Drag to discard notification
    property real dismissOvershoot: 58 // Account for gaps and bouncy animations (was notificationIcon.implicitWidth + 20)
    property var qmlParent: root?.parent?.parent // There's something between this and the parent ListView
    property var parentDragIndex: qmlParent?.dragIndex ?? -1
    property var parentDragDistance: qmlParent?.dragDistance ?? 0
    property var dragIndexDiff: Math.abs(parentDragIndex - index)
    property real xOffset: dragIndexDiff == 0 ? parentDragDistance : 0

    implicitHeight: background.implicitHeight

    function destroyWithAnimation(left = false) {
        background.anchors.leftMargin = root.xOffset; // Break binding, capture current position
        background.implicitHeight = background.implicitHeight; // Freeze height so it doesn't resize during dismiss
        root.implicitHeight = root.implicitHeight; // Freeze delegate height in ListView
        root.qmlParent.resetDrag()
        destroyAnimation.left = left;
        destroyAnimation.running = true;
    }

    TextMetrics {
        id: summaryTextMetrics
        font.pixelSize: root.fontSize
        text: root.notificationObject.summary || ""
    }

    SequentialAnimation { // Drag finish animation
        id: destroyAnimation
        property bool left: true
        running: false

        NumberAnimation {
            target: background.anchors
            property: "leftMargin"
            to: (root.width + root.dismissOvershoot) * (destroyAnimation.left ? -1 : 1)
            duration: root._dismissAnim.duration
            easing.type: root._dismissAnim.type
            easing.bezierCurve: root._dismissAnim.bezierCurve
        }
        onFinished: () => {
            Notifications.discardNotification(notificationObject.notificationId);
        }
    }

    DragManager { // Drag manager
        id: dragManager
        anchors.fill: root
        anchors.leftMargin: root.expanded ? -root.dismissOvershoot : 0
        interactive: expanded
        automaticallyReset: false
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

        onClicked: (mouse) => {
            if (mouse.button === Qt.MiddleButton) {
                root.destroyWithAnimation();
            }
        }

        onDraggingChanged: () => {
            if (dragging) {
                root.qmlParent.dragIndex = root.index ?? root.parent.children.indexOf(root);
            }
        }

        onDragDiffXChanged: () => {
            root.qmlParent.dragDistance = dragDiffX;
        }

        onDragReleased: (diffX, diffY) => {
            if (Math.abs(diffX) > root.dragConfirmThreshold)
                root.destroyWithAnimation(diffX < 0);
            else
                dragManager.resetDrag();
        }
    }

    // Note: App icon for expanded notifications with images is now handled by NotificationAppIcon
    // within the image itself (small corner icon) - no separate icon needed here to avoid duplication

    Rectangle { // Background of notification item
        id: background
        width: parent.width
        anchors.left: parent.left
        radius: 4
        anchors.leftMargin: root.xOffset

        Behavior on anchors.leftMargin {
            enabled: !dragManager.dragging
            NumberAnimation {
                duration: root._contentAnim.duration
                easing.type: root._contentAnim.type
                easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial
            }
        }

        color: (expanded && !onlyNotification) ?
            (notificationObject.urgency == NotificationUrgency.Critical) ?
                ColorUtils.mix(Appearance.colors.colSecondaryContainer, Appearance.colors.colLayer2, 0.35) :
                (Appearance.angelEverywhere ? Appearance.angel.colGlassCard
                    : Appearance.inirEverywhere ? Appearance.inir.colLayer2
                    : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurface
                    : Appearance.colors.colLayer3) :
            "transparent"
        border.width: 0

        // Signature accent bar — 2px, #ff1100, anchored to the left edge
        Rectangle {
            id: accentBar
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 2
            color: "#ff1100"
            visible: (expanded && !onlyNotification)
        }

        implicitHeight: expanded ? (contentColumn.implicitHeight + padding * 2) : summaryRow.implicitHeight
        Behavior on implicitHeight {
            // Sidebar: subtle fast transition; Popup: instant (window resize handled by parent)
            enabled: !root.popup && Appearance.animationsEnabled
            NumberAnimation {
                duration: root._contentAnim.duration / 2
                easing.type: root._contentAnim.type
                easing.bezierCurve: root._contentAnim.bezierCurve
            }
        }

        ColumnLayout { // Content column
            id: contentColumn
            anchors.fill: parent
            anchors.margins: expanded ? root.padding : 0
            spacing: 3

            Behavior on anchors.margins {
                // Sidebar: smooth margin transition; Popup: instant
                enabled: !root.popup && Appearance.animationsEnabled
                animation: NumberAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
            }

            RowLayout { // Summary row
                id: summaryRow
                visible: !root.onlyNotification || !root.expanded
                Layout.fillWidth: true
                implicitHeight: summaryText.implicitHeight
                StyledText {
                    id: summaryText
                    Layout.fillWidth: summaryTextMetrics.width >= summaryRow.implicitWidth * root.summaryElideRatio
                    visible: !root.onlyNotification
                    font.pixelSize: root.fontSize
                    color: Appearance.colors.colOnLayer3
                    elide: Text.ElideRight
                    text: root.notificationObject.summary || ""
                }
                MaterialSymbol {
                    visible: (notificationObject.hasInlineReply ?? false) && !root.expanded
                    text: "reply"
                    iconSize: Appearance.font.pixelSize.small
                    color: Appearance.m3colors.m3primary
                    opacity: 0.7
                    Layout.alignment: Qt.AlignVCenter
                }
                StyledText {
                    opacity: !root.expanded ? 1 : 0
                    visible: opacity > 0
                    Layout.fillWidth: true
                    Behavior on opacity {
                        animation: NumberAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
                    }
                    font.pixelSize: root.fontSize
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                    wrapMode: Text.Wrap // Needed for proper eliding????
                    maximumLineCount: 1
                    textFormat: Text.StyledText
                    text: {
                        return NotificationUtils.processNotificationBody(notificationObject.body, notificationObject.appName || notificationObject.summary).replace(/\n/g, "<br/>")
                    }
                }
            }

            // First action chip (collapsed state only)
            RippleButton {
                visible: !root.expanded && (notificationObject.actions?.length ?? 0) > 0
                implicitHeight: 24
                implicitWidth: firstActionLabel.implicitWidth + 16
                buttonRadius: Appearance.rounding.small
                colBackground: ColorUtils.transparentize(Appearance.m3colors.m3primary, 0.88)
                colBackgroundHover: ColorUtils.transparentize(Appearance.m3colors.m3primary, 0.78)
                colRipple: ColorUtils.transparentize(Appearance.m3colors.m3primary, 0.6)
                Layout.alignment: Qt.AlignRight
                onClicked: {
                    const action = notificationObject.actions[0]
                    if (action) Notifications.attemptInvokeAction(notificationObject.notificationId, action.identifier)
                }

                contentItem: StyledText {
                    id: firstActionLabel
                    anchors.centerIn: parent
                    text: notificationObject.actions?.[0]?.text ?? ""
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    font.weight: Font.Medium
                    color: Appearance.m3colors.m3primary
                }
            }

            ColumnLayout { // Expanded content
                id: expandedContentColumn
                Layout.fillWidth: true
                opacity: root.expanded ? 1 : 0
                visible: opacity > 0

                StyledText { // Notification body (expanded)
                    id: notificationBodyText
                    Behavior on opacity {
                        animation: NumberAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
                    }
                    Layout.fillWidth: true
                    font.pixelSize: root.fontSize
                    color: Appearance.colors.colSubtext
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                    textFormat: Text.RichText
                    text: {
                        return `<style>img{max-width:${expandedContentColumn.width}px;}</style>` +
                            `${NotificationUtils.processNotificationBody(notificationObject.body, notificationObject.appName || notificationObject.summary).replace(/\n/g, "<br/>")}`
                    }

                    onLinkActivated: (link) => {
                        Qt.openUrlExternally(link)
                        GlobalStates.sidebarRightOpen = false
                    }

                    PointingHandLinkHover {}
                }

                Item {
                    Layout.fillWidth: true
                    implicitWidth: actionsFlickable.implicitWidth
                    implicitHeight: actionsFlickable.implicitHeight

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: actionsFlickable.width
                            height: actionsFlickable.height
                            radius: Appearance.angelEverywhere ? Appearance.angel.roundingSmall
                                : Appearance.inirEverywhere ? Appearance.inir.roundingSmall : Appearance.rounding.small
                        }
                    }

                    ScrollEdgeFade {
                        target: actionsFlickable
                        vertical: false
                    }

                    StyledFlickable { // Notification actions
                        id: actionsFlickable
                        anchors.fill: parent
                        implicitHeight: actionRowLayout.implicitHeight
                        contentWidth: actionRowLayout.implicitWidth

                        Behavior on opacity {
                            animation: NumberAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
                        }
                        Behavior on height {
                            animation: NumberAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
                        }
                        Behavior on implicitHeight {
                            animation: NumberAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
                        }

                        RowLayout {
                            id: actionRowLayout
                            Layout.alignment: Qt.AlignBottom

                            NotificationActionButton {
                                Layout.fillWidth: true
                                buttonText: Translation.tr("Close")
                                urgency: notificationObject.urgency
                                implicitWidth: (notificationObject.actions.length == 0) ? ((actionsFlickable.width - actionRowLayout.spacing) / 3) :
                                    (contentItem.implicitWidth + leftPadding + rightPadding)

                                onClicked: {
                                    root.destroyWithAnimation()
                                }

                                contentItem: MaterialSymbol {
                                    iconSize: Appearance.font.pixelSize.larger
                                    horizontalAlignment: Text.AlignHCenter
                                    color: (notificationObject.urgency == NotificationUrgency.Critical) ?
                                        Appearance.m3colors.m3onSurfaceVariant : Appearance.m3colors.m3onSurface
                                    text: "close"
                                }
                            }

                            Repeater {
                                id: actionRepeater
                                model: notificationObject.actions
                                NotificationActionButton {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    buttonText: modelData.text
                                    urgency: notificationObject.urgency
                                    onClicked: {
                                        Notifications.attemptInvokeAction(notificationObject.notificationId, modelData.identifier);
                                    }
                                }
                            }

                            // "Open app" button — shown for history items with no live actions
                            NotificationActionButton {
                                visible: notificationObject.actions.length === 0 && !root.popup
                                Layout.fillWidth: true
                                buttonText: Translation.tr("Open")
                                urgency: notificationObject.urgency
                                onClicked: {
                                    Notifications.focusOrLaunchApp(
                                        notificationObject.appIcon,
                                        notificationObject.appName
                                    )
                                }
                            }

                            NotificationActionButton {
                                Layout.fillWidth: true
                                urgency: notificationObject.urgency
                                implicitWidth: (notificationObject.actions.length == 0) ? ((actionsFlickable.width - actionRowLayout.spacing) / 3) :
                                    (contentItem.implicitWidth + leftPadding + rightPadding)

                                onClicked: {
                                    Quickshell.clipboardText = notificationObject.body
                                    copyIcon.text = "inventory"
                                    copyIconTimer.restart()
                                }

                                Timer {
                                    id: copyIconTimer
                                    interval: 1500
                                    repeat: false
                                    onTriggered: {
                                        copyIcon.text = "content_copy"
                                    }
                                }

                                contentItem: MaterialSymbol {
                                    id: copyIcon
                                    iconSize: Appearance.font.pixelSize.larger
                                    horizontalAlignment: Text.AlignHCenter
                                    color: (notificationObject.urgency == NotificationUrgency.Critical) ?
                                        Appearance.m3colors.m3onSurfaceVariant : Appearance.m3colors.m3onSurface
                                    text: "content_copy"
                                }
                            }

                        }
                    }
                }

                // Inline reply field — shown for messaging apps that support it
                RowLayout {
                    id: replyRow
                    visible: root.expanded && (notificationObject.hasInlineReply ?? false)
                    Layout.fillWidth: true
                    spacing: 4

                    TextField {
                        id: replyField
                        Layout.fillWidth: true
                        placeholderText: notificationObject.inlineReplyPlaceholder || Translation.tr("Reply...")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.m3colors.m3onSurface
                        placeholderTextColor: Appearance.colors.colSubtext

                        background: Rectangle {
                            radius: Appearance.rounding.small
                            color: Appearance.inirEverywhere ? Appearance.inir.colLayer1
                                : Appearance.angelEverywhere ? Appearance.angel.colGlassCard
                                : Appearance.colors.colLayer1
                            border.width: replyField.activeFocus ? 2 : 1
                            border.color: replyField.activeFocus ? Appearance.m3colors.m3primary
                                : Appearance.colors.colOutlineVariant
                        }

                        onActiveFocusChanged: {
                            Notifications.replyActive = activeFocus
                        }

                        Keys.onReturnPressed: {
                            if (replyField.text.trim().length > 0) {
                                Notifications.sendInlineReply(
                                    notificationObject.notificationId,
                                    replyField.text.trim()
                                )
                                replyField.text = ""
                            }
                        }
                        Keys.onEscapePressed: {
                            replyField.focus = false
                            Notifications.replyActive = false
                        }
                    }

                    NotificationActionButton {
                        urgency: notificationObject.urgency
                        implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
                        enabled: replyField.text.trim().length > 0

                        onClicked: {
                            if (replyField.text.trim().length > 0) {
                                Notifications.sendInlineReply(
                                    notificationObject.notificationId,
                                    replyField.text.trim()
                                )
                                replyField.text = ""
                            }
                        }

                        contentItem: MaterialSymbol {
                            iconSize: Appearance.font.pixelSize.larger
                            horizontalAlignment: Text.AlignHCenter
                            color: replyField.text.trim().length > 0
                                ? Appearance.m3colors.m3primary
                                : Appearance.colors.colSubtext
                            text: "send"
                        }
                    }
                }
            }
        }
    }
}
