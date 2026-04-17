import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.dashboard
import qs.services

// Command Center Dashboard — full-screen overlay with three-column layout.
// Triggered by GlobalStates.dashboardOpen (monogram click, IPC, or keybind).
Scope {
    id: root

    readonly property bool dashboardOpen: GlobalStates.dashboardOpen
    readonly property int animDuration: Config.options?.dashboard?.animationDuration ?? 350
    readonly property int exitDuration: Math.round(animDuration * 0.6) // Spec: exit 200-250ms
    readonly property real dimOpacity: Config.options?.dashboard?.backdrop?.dimOpacity ?? 0.45

    // Deferred show to drive animation after visible=true
    property bool _dashboardShown: false

    function _closeDashboard() {
        GlobalStates.dashboardOpen = false
    }

    PanelWindow {
        id: dashboardWindow

        Component.onCompleted: {
            visible = root.dashboardOpen
            root._dashboardShown = root.dashboardOpen
        }

        Connections {
            target: GlobalStates
            function onDashboardOpenChanged() {
                if (GlobalStates.dashboardOpen) {
                    _closeTimer.stop()
                    dashboardWindow.visible = true
                    Qt.callLater(() => { root._dashboardShown = true })
                } else if (!Appearance.animationsEnabled) {
                    root._dashboardShown = false
                    _closeTimer.stop()
                    dashboardWindow.visible = false
                } else {
                    root._dashboardShown = false
                    _closeTimer.restart()
                }
            }
        }

        Timer {
            id: _closeTimer
            interval: root.exitDuration
            onTriggered: dashboardWindow.visible = false
        }

        exclusiveZone: 0
        color: "transparent"
        WlrLayershell.namespace: "quickshell:dashboard"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.dashboardOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        // ── Click-outside dismiss ──
        MouseArea {
            anchors.fill: parent
            onClicked: mouse => {
                const localPos = mapToItem(dashboardContainer, mouse.x, mouse.y)
                if (localPos.x < 0 || localPos.x > dashboardContainer.width
                        || localPos.y < 0 || localPos.y > dashboardContainer.height) {
                    root._closeDashboard()
                }
            }
        }

        // ── Modal scrim (dimmed backdrop) ──
        Rectangle {
            id: modalScrim
            anchors.fill: parent
            color: Appearance.m3colors.m3scrim
            opacity: root._dashboardShown ? root.dimOpacity : 0

            Behavior on opacity {
                enabled: Appearance.animationsEnabled
                NumberAnimation {
                    duration: root.animDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves?.standardDecel ?? [0, 0, 0, 1, 1, 1]
                }
            }
        }

        // ── Dashboard container (centered, sized to ~65% x ~75% of screen) ──
        Rectangle {
            id: dashboardContainer

            anchors.centerIn: parent
            // Offset slightly toward top (closer to bar)
            anchors.verticalCenterOffset: -(parent.height * 0.04)

            width: Math.min(parent.width * 0.7, 1200)
            height: Math.min(parent.height * 0.85, 940)

            clip: true
            color: Appearance.m3colors.m3surface
            radius: 24
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.06)

            // ── Shadow ──
            StyledRectangularShadow {
                target: dashboardContainer
            }

            // ── Animation properties ──
            property real animTranslateY: root._dashboardShown ? 0 : -(dashboardWindow.height * 0.15)
            property real animOpacity: root._dashboardShown ? 1 : 0
            property real animScale: root._dashboardShown ? 1 : 0.95

            transform: Translate { y: dashboardContainer.animTranslateY }
            opacity: dashboardContainer.animOpacity
            scale: dashboardContainer.animScale

            Behavior on animTranslateY {
                enabled: Appearance.animationsEnabled
                NumberAnimation {
                    duration: root._dashboardShown ? root.animDuration : root.exitDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: root._dashboardShown
                        ? (Appearance.animationCurves?.emphasizedDecel ?? [0.05, 0.7, 0.1, 1, 1, 1])
                        : (Appearance.animationCurves?.emphasizedAccel ?? [0.3, 0, 0.8, 0.15, 1, 1])
                }
            }

            Behavior on animOpacity {
                enabled: Appearance.animationsEnabled
                NumberAnimation {
                    duration: root._dashboardShown ? Math.round(root.animDuration * 0.7) : Math.round(root.exitDuration * 0.7)
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: root._dashboardShown
                        ? (Appearance.animationCurves?.standardDecel ?? [0, 0, 0, 1, 1, 1])
                        : (Appearance.animationCurves?.emphasizedAccel ?? [0.3, 0, 0.8, 0.15, 1, 1])
                }
            }

            Behavior on animScale {
                enabled: Appearance.animationsEnabled
                NumberAnimation {
                    duration: root._dashboardShown ? root.animDuration : root.exitDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: root._dashboardShown
                        ? (Appearance.animationCurves?.emphasizedDecel ?? [0.05, 0.7, 0.1, 1, 1, 1])
                        : (Appearance.animationCurves?.emphasizedAccel ?? [0.3, 0, 0.8, 0.15, 1, 1])
                }
            }

            // ── Content ──
            DashboardContent {
                anchors.fill: parent
                anchors.margins: 28
            }

            // ── Keyboard navigation ──
            focus: root.dashboardOpen
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    root._closeDashboard()
                    event.accepted = true
                }
            }
        }
    }

    // ── IPC handler ──
    IpcHandler {
        target: "dashboard"

        function toggle(): void {
            GlobalStates.dashboardOpen = !GlobalStates.dashboardOpen
        }
        function open(): void {
            GlobalStates.dashboardOpen = true
        }
        function close(): void {
            GlobalStates.dashboardOpen = false
        }
    }
}
