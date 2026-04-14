import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Quickshell.Io
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// SidebarShell — parameterized PanelWindow wrapper for left/right sidebars.
// Absorbs: deferred-open pattern, close timer, animation state machine (6 types),
// backdrop click-to-dismiss, CompositorFocusGrab, IPC handler, Hyprland shortcuts.
Scope {
    id: root

    // ── Required properties ──────────────────────────────────────
    required property string side               // "left" or "right"
    required property Component contentComponent // What to render inside

    // ── Optional properties ──────────────────────────────────────
    property bool pluginViewActive: false        // Left-only: webapp expansion
    property bool soundEnabled: false            // Right-only: open sound

    // ── Derived from side ────────────────────────────────────────
    readonly property bool isRight: side === "right"
    readonly property bool sidebarOpen: isRight ? GlobalStates.sidebarRightOpen : GlobalStates.sidebarLeftOpen
    readonly property string keepLoadedKey: isRight ? "keepRightSidebarLoaded" : "keepLeftSidebarLoaded"

    // ── Screen info (for content to bind to) ────────────────────
    readonly property var panelScreen: sidebarRoot.screen ?? null
    readonly property int screenWidth: sidebarRoot.screen?.width ?? 1920
    readonly property int screenHeight: sidebarRoot.screen?.height ?? 1080

    // ── Config ───────────────────────────────────────────────────
    property int sidebarWidth: Appearance.sizes.sidebarWidth
    readonly property bool instantOpen: Config.options?.sidebar?.instantOpen ?? false
    readonly property string animationType: Config.options?.sidebar?.animationType ?? "slide"

    // ── Plugin transition tracking (left-only) ───────────────────
    property bool _pluginTransitioning: false
    onPluginViewActiveChanged: {
        root._pluginTransitioning = true
        _pluginTransitionTimer.restart()
    }
    Timer {
        id: _pluginTransitionTimer
        interval: 50
        onTriggered: root._pluginTransitioning = false
    }
    readonly property real effectiveSidebarWidth: pluginViewActive
        ? Appearance.sizes.sidebarWidthExtended
        : sidebarWidth

    // ── Deferred slide trigger ───────────────────────────────────
    property bool _sidebarShown: false

    // ── Sidebar open sound (right-only) ──────────────────────────
    property bool _sidebarSoundReady: false
    Timer { interval: 2000; running: root.soundEnabled; onTriggered: root._sidebarSoundReady = true }
    Connections {
        enabled: root.soundEnabled
        target: GlobalStates
        function onSidebarRightOpenChanged() {
            if (root._sidebarSoundReady && GlobalStates.sidebarRightOpen) {
                if (Config.options?.sounds?.sidebar ?? false)
                    Audio.playSystemSound("dialog-information")
            }
        }
    }

    function _setSidebarOpen(val) {
        if (isRight) GlobalStates.sidebarRightOpen = val
        else GlobalStates.sidebarLeftOpen = val
    }

    PanelWindow {
        id: sidebarRoot

        Component.onCompleted: {
            visible = root.sidebarOpen
            root._sidebarShown = root.sidebarOpen
        }

        Connections {
            target: GlobalStates
            function onSidebarRightOpenChanged() { if (root.isRight) root._handleOpenChanged() }
            function onSidebarLeftOpenChanged()  { if (!root.isRight) root._handleOpenChanged() }
        }

        Timer {
            id: _closeTimer
            interval: 120 // Reduced from 300ms — matches exit animation duration
            onTriggered: sidebarRoot.visible = false
        }

        function hide() {
            root._setSidebarOpen(false)
        }

        exclusiveZone: 0
        implicitWidth: screen?.width ?? 1920
        WlrLayershell.namespace: root.isRight ? "quickshell:sidebarRight" : "quickshell:sidebarLeft"
        WlrLayershell.keyboardFocus: root.sidebarOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: "transparent"

        anchors {
            top: true
            right: true
            bottom: true
            left: true
        }

        CompositorFocusGrab {
            id: grab
            windows: [ sidebarRoot ]
            active: CompositorService.isHyprland && sidebarRoot.visible
            onCleared: () => {
                if (!active) sidebarRoot.hide()
            }
        }

        MouseArea {
            id: backdropClickArea
            anchors.fill: parent
            onClicked: mouse => {
                const localPos = mapToItem(sidebarContentLoader, mouse.x, mouse.y)
                if (localPos.x < 0 || localPos.x > sidebarContentLoader.width
                        || localPos.y < 0 || localPos.y > sidebarContentLoader.height) {
                    sidebarRoot.hide()
                }
            }
        }

        Loader {
            id: sidebarContentLoader
            active: root.sidebarOpen || (Config?.options?.sidebar?.[root.keepLoadedKey] ?? true)
            anchors {
                top: parent.top
                bottom: parent.bottom
                margins: Appearance.sizes.hyprlandGapsOut
            }
            // Side-dependent anchoring
            Component.onCompleted: {
                if (root.isRight) {
                    anchors.right = parent.right
                    anchors.rightMargin = Qt.binding(() => Appearance.sizes.hyprlandGapsOut)
                    anchors.leftMargin = Qt.binding(() => Appearance.sizes.elevationMargin)
                } else {
                    anchors.left = parent.left
                    anchors.leftMargin = Qt.binding(() => Appearance.sizes.hyprlandGapsOut)
                    anchors.rightMargin = Qt.binding(() => Appearance.sizes.elevationMargin)
                }
            }
            width: root.effectiveSidebarWidth - Appearance.sizes.hyprlandGapsOut - Appearance.sizes.elevationMargin
            Behavior on width {
                // Only active for left sidebar plugin transitions
                enabled: Appearance.animationsEnabled && !root.isRight && !root._pluginTransitioning
                NumberAnimation {
                    duration: Appearance.animation.elementResize.duration
                    easing.type: Appearance.animation.elementResize.type
                    easing.bezierCurve: Appearance.animation.elementResize.bezierCurve
                }
            }
            height: parent.height - Appearance.sizes.hyprlandGapsOut * 2

            // ── Animation properties ─────────────────────────────
            readonly property real _translateSign: root.isRight ? 1 : -1
            readonly property real _offscreenX: _translateSign * (root.effectiveSidebarWidth + Appearance.sizes.hyprlandGapsOut)

            property real animTranslateX: _offscreenX
            property real animOpacity: 1
            property real animScale: 1
            property bool useClip: root.animationType === "reveal"
            property real clipWidth: root.effectiveSidebarWidth - Appearance.sizes.hyprlandGapsOut - Appearance.sizes.elevationMargin
            property real animTranslateY: 0
            property real animScaleX: 1

            property bool animating: false
            transform: [
                Translate { x: sidebarContentLoader.animTranslateX; y: sidebarContentLoader.animTranslateY },
                Scale {
                    xScale: sidebarContentLoader.animScaleX
                    origin.x: root.isRight ? sidebarContentLoader.width : 0
                    origin.y: sidebarContentLoader.height / 2
                }
            ]
            opacity: sidebarContentLoader.animOpacity
            scale: sidebarContentLoader.animScale

            states: [
                State {
                    name: "open"
                    when: root._sidebarShown
                    PropertyChanges {
                        target: sidebarContentLoader
                        animTranslateX: 0
                        animOpacity: 1
                        animScale: 1
                        animTranslateY: 0
                        animScaleX: 1
                        clipWidth: root.effectiveSidebarWidth - Appearance.sizes.hyprlandGapsOut - Appearance.sizes.elevationMargin
                    }
                },
                State {
                    name: "closed"
                    when: !root._sidebarShown
                    PropertyChanges {
                        target: sidebarContentLoader
                        animTranslateX: root.animationType === "slide" || root.animationType === "reveal"
                            ? sidebarContentLoader._offscreenX
                            : 0
                        animOpacity: (root.animationType === "slide" || root.animationType === "reveal") ? 1 : 0
                        animScale: root.animationType === "elastic" ? 0.88
                            : root.animationType === "pop" ? 0.94 : 1
                        animTranslateY: root.animationType === "drop"
                            ? -(sidebarContentLoader.height + Appearance.sizes.hyprlandGapsOut * 2) : 0
                        animScaleX: root.animationType === "swing" ? 0 : 1
                        clipWidth: root.animationType === "reveal" ? 0
                            : root.effectiveSidebarWidth - Appearance.sizes.hyprlandGapsOut - Appearance.sizes.elevationMargin
                    }
                }
            ]
            transitions: [
                Transition {
                    to: "open"
                    enabled: Appearance.animationsEnabled && !root._pluginTransitioning && !root.instantOpen
                    ParallelAnimation {
                        NumberAnimation {
                            target: sidebarContentLoader; property: "animTranslateX"
                            duration: Appearance.animation?.elementMoveEnter?.duration ?? 400
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.animationCurves?.emphasizedDecel ?? [0.05, 0.7, 0.1, 1, 1, 1]
                        }
                        NumberAnimation {
                            target: sidebarContentLoader; property: "animTranslateY"
                            duration: Appearance.animation?.elementMoveEnter?.duration ?? 400
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.animationCurves?.emphasizedDecel ?? [0.05, 0.7, 0.1, 1, 1, 1]
                        }
                        NumberAnimation {
                            target: sidebarContentLoader; property: "animOpacity"
                            duration: Math.round((Appearance.animation?.elementMoveEnter?.duration ?? 400) * 0.7)
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.animationCurves?.standardDecel ?? [0, 0, 0, 1, 1, 1]
                        }
                        SequentialAnimation {
                            NumberAnimation {
                                target: sidebarContentLoader; property: "animScale"
                                from: root.animationType === "elastic" ? 0.88
                                    : root.animationType === "pop" ? 0.94 : 1
                                to: root.animationType === "elastic" ? 1.04
                                    : root.animationType === "pop" ? 1.018 : 1
                                duration: Math.round((Appearance.animation?.elementMoveEnter?.duration ?? 400) * 0.62)
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Appearance.animationCurves?.emphasizedDecel ?? [0.05, 0.7, 0.1, 1, 1, 1]
                            }
                            NumberAnimation {
                                target: sidebarContentLoader; property: "animScale"
                                to: 1
                                duration: Math.round((Appearance.animation?.elementMoveEnter?.duration ?? 400) * 0.38)
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Appearance.animationCurves?.expressiveEffects ?? [0.34, 0.80, 0.34, 1.00, 1, 1]
                            }
                        }
                        NumberAnimation {
                            target: sidebarContentLoader; property: "animScaleX"
                            duration: Appearance.animation?.elementMoveEnter?.duration ?? 400
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.animationCurves?.emphasizedDecel ?? [0.05, 0.7, 0.1, 1, 1, 1]
                        }
                        NumberAnimation {
                            target: sidebarContentLoader; property: "clipWidth"
                            duration: Appearance.animation?.elementMoveEnter?.duration ?? 400
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.animationCurves?.emphasizedDecel ?? [0.05, 0.7, 0.1, 1, 1, 1]
                        }
                    }
                    onRunningChanged: sidebarContentLoader.animating = running
                },
                Transition {
                    to: "closed"
                    enabled: Appearance.animationsEnabled && !root._pluginTransitioning && !root.instantOpen
                    ParallelAnimation {
                        NumberAnimation {
                            target: sidebarContentLoader; property: "animTranslateX"
                            duration: Appearance.animation?.elementMoveExit?.duration ?? 200
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.animationCurves?.emphasizedAccel ?? [0.3, 0, 0.8, 0.15, 1, 1]
                        }
                        NumberAnimation {
                            target: sidebarContentLoader; property: "animTranslateY"
                            duration: Appearance.animation?.elementMoveExit?.duration ?? 200
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.animationCurves?.emphasizedAccel ?? [0.3, 0, 0.8, 0.15, 1, 1]
                        }
                        NumberAnimation {
                            target: sidebarContentLoader; property: "animOpacity"
                            duration: Math.round((Appearance.animation?.elementMoveExit?.duration ?? 200) * 0.7)
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.animationCurves?.standardAccel ?? [0.3, 0, 1, 1, 1, 1]
                        }
                        NumberAnimation {
                            target: sidebarContentLoader; property: "animScale"
                            duration: Appearance.animation?.elementMoveExit?.duration ?? 200
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.animationCurves?.emphasizedAccel ?? [0.3, 0, 0.8, 0.15, 1, 1]
                        }
                        NumberAnimation {
                            target: sidebarContentLoader; property: "animScaleX"
                            duration: Appearance.animation?.elementMoveExit?.duration ?? 200
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.animationCurves?.emphasizedAccel ?? [0.3, 0, 0.8, 0.15, 1, 1]
                        }
                        NumberAnimation {
                            target: sidebarContentLoader; property: "clipWidth"
                            duration: Appearance.animation?.elementMoveExit?.duration ?? 200
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.animationCurves?.emphasizedAccel ?? [0.3, 0, 0.8, 0.15, 1, 1]
                        }
                    }
                    onRunningChanged: sidebarContentLoader.animating = running
                }
            ]

            clip: sidebarContentLoader.useClip

            focus: root.sidebarOpen
            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape) {
                    sidebarRoot.hide();
                }
            }

            sourceComponent: root.contentComponent
        }
    }

    function _handleOpenChanged() {
        if (root.sidebarOpen) {
            _closeTimer.stop()
            sidebarRoot.visible = true
            Qt.callLater(() => { root._sidebarShown = true })
        } else if (root.instantOpen || !Appearance.animationsEnabled) {
            root._sidebarShown = false
            _closeTimer.stop()
            sidebarRoot.visible = false
        } else {
            root._sidebarShown = false
            _closeTimer.restart()
        }
    }

    // ── IPC ──────────────────────────────────────────────────────
    IpcHandler {
        target: root.isRight ? "sidebarRight" : "sidebarLeft"

        function toggle(): void { root._setSidebarOpen(!root.sidebarOpen) }
        function close(): void  { root._setSidebarOpen(false) }
        function open(): void   { root._setSidebarOpen(true) }
    }

    // ── Hyprland shortcuts ───────────────────────────────────────
    Loader {
        active: CompositorService.isHyprland
        sourceComponent: Item {
            GlobalShortcut {
                name: root.isRight ? "sidebarRightToggle" : "sidebarLeftToggle"
                description: `Toggles ${root.side} sidebar on press`
                onPressed: root._setSidebarOpen(!root.sidebarOpen)
            }
            GlobalShortcut {
                name: root.isRight ? "sidebarRightOpen" : "sidebarLeftOpen"
                description: `Opens ${root.side} sidebar on press`
                onPressed: root._setSidebarOpen(true)
            }
            GlobalShortcut {
                name: root.isRight ? "sidebarRightClose" : "sidebarLeftClose"
                description: `Closes ${root.side} sidebar on press`
                onPressed: root._setSidebarOpen(false)
            }
        }
    }
}
