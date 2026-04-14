pragma ComponentBehavior: Bound

import qs.modules.common
import qs.services
import qs.modules.sidebarLeft
import QtQuick
import QtQuick.Layouts

/**
 * CockpitSurface — the left sidebar's composed ambient surface.
 *
 * Session A: scaffolding only. Each slot is a placeholder rectangle.
 * Session F: expand-in-place state machine. Tapping NowPlayingHero
 *            expands YtMusicView in place with a parallel fade+scale
 *            transition. Back button or Escape collapses back.
 *
 * State architecture: two layers (cockpitLayer + expandedLayer) with
 * property-based states and explicit Behaviors. No StackLayout, no Loader
 * swap — both layers coexist in the tree so cross-fade works correctly
 * and expanded content persists across collapse/expand cycles.
 */
Item {
    id: root

    // ── Public API ────────────────────────────────────────────────────────
    property Item expandedContent: null
    readonly property bool expanded: expandedContent !== null

    function expand(contentItem) {
        root.expandedContent = contentItem
    }

    function collapse() {
        root.expandedContent = null
    }

    // ── State string ──────────────────────────────────────────────────────
    state: root.expanded ? "expanded" : "cockpit"

    // ── Keyboard: intercept Escape before SidebarBackground gets it ───────
    // Focus is granted by SidebarLeftContent.focusActiveItem() on sidebar open.
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape && root.expanded) {
            root.collapse()
            event.accepted = true
        }
        // Non-expanded Escape bubbles up to SidebarBackground → closes sidebar.
    }

    // ── Reset to cockpit when sidebar closes ──────────────────────────────
    Connections {
        target: GlobalStates
        function onSidebarLeftOpenChanged() {
            if (!GlobalStates.sidebarLeftOpen) {
                root.collapse()
            }
        }
    }

    // ── Ambient surface — z:0, behind everything, never touched by state ──
    AmbientBackground {
        id: ambient
        anchors.fill: parent
        z: 0
    }

    // ── Cockpit layer — the five-slot composition ─────────────────────────
    Item {
        id: cockpitLayer
        anchors.fill: parent
        z: 1
        transformOrigin: Item.Center
        opacity: 1.0
        scale: 1.0

        ColumnLayout {
            id: slots
            anchors.fill: parent
            spacing: 8

            NowPlayingHero {
                id: hero
                onExpandRequested: root.expand(ytMusicView)
            }
            SystemPulse {}
            WallpaperPalette {
                id: palette
                // Session G: onExpandRequested: root.expand(wallhavenView)
            }
            ContextStrip {}
        }
    }

    // ── Expanded layer — wraps whichever expandedContent is live ──────────
    ExpandedSurface {
        id: expandedLayer
        anchors.fill: parent
        z: 2
        transformOrigin: Item.Center
        opacity: 0.0
        scale: 0.96
        visible: false
        content: root.expandedContent
        title: root.expandedContent && root.expandedContent.expandTitle !== undefined
               ? root.expandedContent.expandTitle
               : ""
        onCloseRequested: root.collapse()
    }

    // ── Cached expand targets ─────────────────────────────────────────────
    // Instantiated once at CockpitSurface load, never destroyed.
    // parent: null keeps them out of the render tree until ExpandedSurface
    // re-parents them into contentSlot on demand.
    YtMusicView {
        id: ytMusicView
        parent: null
    }
    // Session G adds: WallhavenView { id: wallhavenView; parent: null }

    // ── States ────────────────────────────────────────────────────────────
    states: [
        State {
            name: "cockpit"
            // Default values — cockpitLayer visible/full, expandedLayer hidden.
        },
        State {
            name: "expanded"
            PropertyChanges { target: cockpitLayer;  opacity: 0.0; scale: 0.96 }
            PropertyChanges { target: expandedLayer; opacity: 1.0; scale: 1.0; visible: true }
            PropertyChanges { target: hero;          enabled: false }
        }
    ]

    // ── Transitions ───────────────────────────────────────────────────────
    transitions: [
        // Expand: cockpit → expanded (150ms, expressiveDefaultSpatial / elementMove)
        Transition {
            from: "cockpit"
            to: "expanded"
            ParallelAnimation {
                NumberAnimation {
                    target: cockpitLayer; property: "opacity"
                    duration: Appearance.animation.elementMove.duration
                    easing.type: Appearance.animation.elementMove.type
                    easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                }
                NumberAnimation {
                    target: cockpitLayer; property: "scale"
                    duration: Appearance.animation.elementMove.duration
                    easing.type: Appearance.animation.elementMove.type
                    easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                }
                NumberAnimation {
                    target: expandedLayer; property: "opacity"
                    duration: Appearance.animation.elementMove.duration
                    easing.type: Appearance.animation.elementMove.type
                    easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                }
                NumberAnimation {
                    target: expandedLayer; property: "scale"
                    duration: Appearance.animation.elementMove.duration
                    easing.type: Appearance.animation.elementMove.type
                    easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                }
                // visible on expandedLayer is set by the state entering, not animated.
            }
        },
        // Collapse: expanded → cockpit (120ms, elementMoveEnter — cockpit re-emerging is the entrance)
        Transition {
            from: "expanded"
            to: "cockpit"
            SequentialAnimation {
                ParallelAnimation {
                    NumberAnimation {
                        target: cockpitLayer; property: "opacity"
                        duration: Appearance.animation.elementMoveEnter.duration
                        easing.type: Appearance.animation.elementMoveEnter.type
                        easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
                    }
                    NumberAnimation {
                        target: cockpitLayer; property: "scale"
                        duration: Appearance.animation.elementMoveEnter.duration
                        easing.type: Appearance.animation.elementMoveEnter.type
                        easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
                    }
                    NumberAnimation {
                        target: expandedLayer; property: "opacity"
                        duration: Appearance.animation.elementMoveEnter.duration
                        easing.type: Appearance.animation.elementMoveEnter.type
                        easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
                    }
                    NumberAnimation {
                        target: expandedLayer; property: "scale"
                        duration: Appearance.animation.elementMoveEnter.duration
                        easing.type: Appearance.animation.elementMoveEnter.type
                        easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
                    }
                }
                // Hide the expanded layer AFTER the fade completes, not at state entry.
                // Without this, the layer vanishes immediately and the collapse fade is invisible.
                PropertyAction { target: expandedLayer; property: "visible"; value: false }
            }
        }
    ]
}
