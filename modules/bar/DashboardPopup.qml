import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.bar.dashboard
import qs.services
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

LazyLoader {
    id: root

    property Item hoverTarget
    property bool dashboardOpen: false
    property bool popupHovered: false

    signal requestClose()

    property bool _animatingClose: false

    active: dashboardOpen || _animatingClose

    onDashboardOpenChanged: {
        if (dashboardOpen) {
            _animatingClose = false
        } else if (active && !dashboardOpen) {
            _animatingClose = true
        }
    }

    onActiveChanged: {
        if (!root.active)
            root.popupHovered = false
    }

    // Click-outside backdrop
    PanelWindow {
        id: clickOutsideBackdrop
        visible: root.active
        color: "#01000000"
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:popup-catcher"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: root.requestClose()
        }
    }

    component: PanelWindow {
        id: popupWindow
        color: "transparent"

        HoverHandler {
            id: popupHoverHandler
            onHoveredChanged: root.popupHovered = hovered
        }

        anchors.left: !(Config.options?.bar?.vertical ?? false) || ((Config.options?.bar?.vertical ?? false) && !(Config.options?.bar?.bottom ?? false))
        anchors.right: (Config.options?.bar?.vertical ?? false) && (Config.options?.bar?.bottom ?? false)
        anchors.top: (Config.options?.bar?.vertical ?? false) || (!(Config.options?.bar?.vertical ?? false) && !(Config.options?.bar?.bottom ?? false))
        anchors.bottom: !(Config.options?.bar?.vertical ?? false) && (Config.options?.bar?.bottom ?? false)

        implicitWidth: popupBackground.implicitWidth + Appearance.sizes.elevationMargin * 2
        implicitHeight: popupBackground.implicitHeight + Appearance.sizes.elevationMargin * 2

        mask: Region {
            item: popupBackground
        }

        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        margins {
            left: {
                if (!(Config.options?.bar?.vertical ?? false) && root.QsWindow && root.hoverTarget && root.hoverTarget.width > 0) {
                    // Center popup under the clock, clamped to screen
                    const mapped = root.QsWindow.mapFromItem(
                        root.hoverTarget,
                        (root.hoverTarget.width - popupBackground.implicitWidth) / 2, 0
                    ).x
                    return Math.max(8, mapped)
                }
                return Appearance.sizes.verticalBarWidth
            }
            top: {
                if (!(Config.options?.bar?.vertical ?? false)) return Appearance.sizes.barHeight
                if (root.QsWindow && root.hoverTarget && root.hoverTarget.height > 0) {
                    return root.QsWindow.mapFromItem(
                        root.hoverTarget,
                        0, (root.hoverTarget.height - popupBackground.implicitHeight) / 2
                    ).y
                }
                return Appearance.sizes.barHeight
            }
            right: Appearance.sizes.verticalBarWidth
            bottom: Appearance.sizes.barHeight
        }
        WlrLayershell.namespace: "quickshell:popup"
        WlrLayershell.layer: WlrLayer.Overlay

        StyledRectangularShadow {
            target: popupBackground
        }

        Rectangle {
            id: popupBackground
            anchors {
                fill: parent
                leftMargin: Appearance.sizes.elevationMargin
                rightMargin: Appearance.sizes.elevationMargin
                topMargin: Appearance.sizes.elevationMargin
                bottomMargin: Appearance.sizes.elevationMargin
            }
            implicitWidth: dashboardContent.implicitWidth + 20
            implicitHeight: dashboardContent.implicitHeight + 20
            color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.15)
            radius: Appearance.rounding.large
            border.width: 1
            border.color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.85)

            opacity: 0
            scale: 0.92
            transformOrigin: {
                const isVertical = Config.options?.bar?.vertical ?? false
                if (isVertical)
                    return (Config.options?.bar?.bottom ?? false) ? Item.Right : Item.Left
                return (Config.options?.bar?.bottom ?? false) ? Item.Bottom : Item.Top
            }

            Component.onCompleted: {
                if (Appearance.animationsEnabled)
                    entryAnim.start()
                else {
                    popupBackground.opacity = 1
                    popupBackground.scale = 1
                }
            }

            ParallelAnimation {
                id: entryAnim
                NumberAnimation { target: popupBackground; property: "opacity"; to: 1; duration: Appearance.animation.elementMoveEnter.duration; easing.type: Appearance.animation.elementMoveEnter.type; easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve }
                NumberAnimation { target: popupBackground; property: "scale"; to: 1; duration: Appearance.animation.elementMove.duration; easing.type: Appearance.animation.elementMove.type; easing.bezierCurve: Appearance.animation.elementMove.bezierCurve }
            }

            ParallelAnimation {
                id: exitAnim
                NumberAnimation { target: popupBackground; property: "opacity"; to: 0; duration: 150; easing.type: Easing.InCubic }
                NumberAnimation { target: popupBackground; property: "scale"; to: 0.95; duration: 150; easing.type: Easing.InCubic }
                onFinished: root._animatingClose = false
            }

            Connections {
                target: root
                function on_AnimatingCloseChanged() {
                    if (root._animatingClose) {
                        if (Appearance.animationsEnabled)
                            exitAnim.start()
                        else
                            root._animatingClose = false
                    }
                }
            }

            // ── Dashboard content ──
            ColumnLayout {
                id: dashboardContent
                anchors.fill: parent
                anchors.margins: 10
                spacing: 0

                // Keyboard navigation
                focus: true
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.requestClose()
                        event.accepted = true
                    } else if (event.key === Qt.Key_H || (event.key === Qt.Key_Tab && event.modifiers & Qt.ShiftModifier)) {
                        tabStack.currentIndex = Math.max(0, tabStack.currentIndex - 1)
                        event.accepted = true
                    } else if (event.key === Qt.Key_L || event.key === Qt.Key_Tab) {
                        tabStack.currentIndex = Math.min(tabStack.count - 1, tabStack.currentIndex + 1)
                        event.accepted = true
                    }
                }

                // ── Tab bar ──
                Item {
                    Layout.fillWidth: true
                    implicitHeight: tabBarRow.implicitHeight

                    RowLayout {
                        id: tabBarRow
                        anchors.fill: parent
                        spacing: 0

                        // Scroll wheel to switch tabs
                        WheelHandler {
                            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                            onWheel: event => {
                                if (event.angleDelta.y > 0)
                                    tabStack.currentIndex = Math.max(0, tabStack.currentIndex - 1)
                                else if (event.angleDelta.y < 0)
                                    tabStack.currentIndex = Math.min(tabStack.count - 1, tabStack.currentIndex + 1)
                            }
                        }

                        Repeater {
                            id: tabRepeater
                            model: [
                                { label: "Overview", icon: "dashboard" },
                                { label: "Media", icon: "music_note" },
                                { label: "Performance", icon: "speed" },
                                { label: "Niri", icon: "settings_ethernet" }
                            ]

                            Item {
                                id: tabButton
                                required property var modelData
                                required property int index

                                Layout.fillWidth: true
                                implicitHeight: 48

                                Rectangle {
                                    anchors.fill: parent
                                    radius: Appearance.rounding.small
                                    color: tabMouse.containsMouse && tabStack.currentIndex !== tabButton.index
                                        ? ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.92)
                                        : "transparent"
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 2

                                    MaterialSymbol {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: tabButton.modelData.icon
                                        iconSize: 18
                                        color: tabStack.currentIndex === tabButton.index
                                            ? Appearance.colors.colPrimary
                                            : Appearance.colors.colSubtext
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                    }

                                    StyledText {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: tabButton.modelData.label
                                        font.pixelSize: Appearance.font.pixelSize.smallest
                                        font.weight: tabStack.currentIndex === tabButton.index ? Font.DemiBold : Font.Normal
                                        color: tabStack.currentIndex === tabButton.index
                                            ? Appearance.colors.colOnLayer0
                                            : Appearance.colors.colSubtext
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                    }
                                }

                                MouseArea {
                                    id: tabMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: tabStack.currentIndex = tabButton.index
                                }
                            }
                        }
                    }

                    // Sliding active indicator
                    Rectangle {
                        id: tabIndicator
                        y: tabBarRow.height - height
                        height: 3
                        radius: 1.5
                        color: Appearance.colors.colPrimary
                        width: {
                            const item = tabRepeater.itemAt(tabStack.currentIndex)
                            return item ? item.width * 0.5 : 0
                        }
                        x: {
                            const item = tabRepeater.itemAt(tabStack.currentIndex)
                            return item ? item.x + (item.width - width) / 2 : 0
                        }
                        Behavior on x { NumberAnimation { duration: Appearance.animation.elementMove.duration; easing.type: Appearance.animation.elementMove.type; easing.bezierCurve: Appearance.animation.elementMove.bezierCurve } }
                        Behavior on width { NumberAnimation { duration: Appearance.animation.elementMove.duration; easing.type: Appearance.animation.elementMove.type; easing.bezierCurve: Appearance.animation.elementMove.bezierCurve } }
                    }
                }

                // Tab separator
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.88)
                }

                // ── Tab content ──
                StackLayout {
                    id: tabStack
                    Layout.fillWidth: true
                    Layout.preferredWidth: 720
                    Layout.preferredHeight: 460
                    currentIndex: 0

                    // Overview tab
                    DashboardTab {}

                    // Media tab
                    MediaTab {}

                    // Performance tab
                    PerformanceTab {}

                    // Niri tab
                    NiriTab {}
                }
            }
        }
    }
}
