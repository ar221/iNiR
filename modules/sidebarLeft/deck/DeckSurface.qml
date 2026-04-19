pragma ComponentBehavior: Bound

import QtQuick
import qs
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.sidebarLeft
import qs.services

/**
 * DeckSurface — the Deck sidebar's nav-rail + view composition.
 *
 * Tasks 1-10: three views (Media, Wallhaven, System) behind a NavigationRail.
 * Task 11: expand-in-place state machine. Requesting expand() overlays
 *          ExpandedSurface over the content area while the rail stays visible.
 *          Back button, Escape, or view switch collapses back.
 *
 * State architecture mirrors CockpitSurface: two layers (viewContainer +
 * expandedLayer) inside contentArea, property-based states, explicit
 * transitions. Rail is excluded from the fade — it remains anchored at z:1.
 */
Item {
    id: root

    // ── Public API ────────────────────────────────────────────────────────
    property int currentView: Config.options?.sidebar?.deck?.defaultView ?? 0

    property Item expandedContent: null
    readonly property bool expanded: expandedContent !== null

    function expand(contentItem) {
        root.expandedContent = contentItem
    }

    function collapse() {
        root.expandedContent = null
    }

    // ── State string ──────────────────────────────────────────────────────
    state: root.expanded ? "expanded" : "deck"

    // ── Collapse when switching views while expanded ───────────────────────
    onCurrentViewChanged: {
        if (root.expanded) root.collapse()
    }

    // ── Keyboard ──────────────────────────────────────────────────────────
    // 4 sets the AudioFX view only when audioFX is enabled — otherwise it
    // would land on a hidden tab and look broken.
    readonly property bool _audioFXEnabled:
        Config.options?.sidebar?.deck?.audioFX?.enable ?? true

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_1) { root.currentView = 0; event.accepted = true }
        else if (event.key === Qt.Key_2) { root.currentView = 1; event.accepted = true }
        else if (event.key === Qt.Key_3) { root.currentView = 2; event.accepted = true }
        else if (event.key === Qt.Key_4 && root._audioFXEnabled) {
            root.currentView = 3; event.accepted = true
        }
        else if (event.key === Qt.Key_Escape && root.expanded) {
            root.collapse()
            event.accepted = true
            // Non-expanded Escape bubbles up to SidebarBackground → closes sidebar.
        } else if (event.key === Qt.Key_Escape) {
            GlobalStates.sidebarLeftOpen = false
            event.accepted = true
        }
    }

    // ── Reset on sidebar close ────────────────────────────────────────────
    Connections {
        target: GlobalStates
        function onSidebarLeftOpenChanged() {
            if (!GlobalStates.sidebarLeftOpen) root.collapse()
        }
    }

    // ── Background ───────────────────────────────────────────────────────
    AmbientBackground {
        anchors.fill: parent
        z: 0
    }

    // ── Layout: Rail | Content ───────────────────────────────────────
    NavigationRail {
        id: rail
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        currentView: root.currentView
        onViewRequested: (index) => { root.currentView = index }
        z: 1
    }

    // ── Content area ─────────────────────────────────────────────────
    Item {
        id: contentArea
        anchors.left: rail.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        z: 1

        // ── View container — fades out when expanded ──────────────────
        Item {
            id: viewContainer
            anchors.fill: parent
            transformOrigin: Item.Center
            opacity: 1.0
            scale: 1.0

            // View 0: Media
            MediaView {
                anchors.fill: parent
                anchors.margins: 12
                visible: root.currentView === 0
                opacity: root.currentView === 0 ? 1 : 0
                Behavior on opacity {
                    enabled: Appearance.animationsEnabled
                    NumberAnimation {
                        duration: Appearance.animation.elementMoveEnter.duration
                        easing.type: Appearance.animation.elementMoveEnter.type
                        easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
                    }
                }
            }

            // View 1: Wallhaven
            Item {
                anchors.fill: parent
                visible: root.currentView === 1
                opacity: root.currentView === 1 ? 1 : 0

                // Wallhaven browser fills the content area
                WallhavenView {
                    id: wallhavenView
                    anchors.fill: parent
                    anchors.margins: 4
                    // Reserve space at the bottom for palette + system strip
                    anchors.bottomMargin: paletteColumn.implicitHeight + 4 + 4
                }

                // Palette extract bar + SystemStrip pinned at bottom
                ColumnLayout {
                    id: paletteColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: 4
                    anchors.rightMargin: 4
                    anchors.bottomMargin: 4
                    spacing: 4
                    z: 2

                    PaletteExtractBar {}
                    SystemStrip {}
                }

                Behavior on opacity {
                    enabled: Appearance.animationsEnabled
                    NumberAnimation {
                        duration: Appearance.animation.elementMoveEnter.duration
                        easing.type: Appearance.animation.elementMoveEnter.type
                        easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
                    }
                }
            }

            // View 2: System
            SystemView {
                anchors.fill: parent
                anchors.margins: 12
                visible: root.currentView === 2
                opacity: root.currentView === 2 ? 1 : 0
                Behavior on opacity {
                    enabled: Appearance.animationsEnabled
                    NumberAnimation {
                        duration: Appearance.animation.elementMoveEnter.duration
                        easing.type: Appearance.animation.elementMoveEnter.type
                        easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
                    }
                }
            }

            // View 3: AudioFX (EasyEffects)
            // Gated on Config.sidebar.deck.audioFX.enable. When disabled, the
            // view never instantiates and the rail hides its button.
            Loader {
                anchors.fill: parent
                anchors.margins: 12
                active: root._audioFXEnabled
                visible: root.currentView === 3 && active
                opacity: visible ? 1 : 0
                asynchronous: false
                sourceComponent: AudioView {
                    onEditEqRequested: {
                        // EQ editor expand-in-place is post-v1; placeholder.
                    }
                }
                Behavior on opacity {
                    enabled: Appearance.animationsEnabled
                    NumberAnimation {
                        duration: Appearance.animation.elementMoveEnter.duration
                        easing.type: Appearance.animation.elementMoveEnter.type
                        easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
                    }
                }
            }
        }

        // ── Expanded layer — wraps whichever expandedContent is live ──
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
                   ? root.expandedContent.expandTitle : ""
            onCloseRequested: root.collapse()
        }
    }

    // ── Cached expand targets ─────────────────────────────────────────────
    // Instantiated once at DeckSurface load, never destroyed.
    // parent: null keeps them out of the render tree until ExpandedSurface
    // re-parents them into contentSlot on demand.
    YtMusicView {
        id: ytMusicView
        parent: null
        visible: false
    }

    // ── States ────────────────────────────────────────────────────────────
    states: [
        State {
            name: "deck"
            // Default values — viewContainer visible/full, expandedLayer hidden.
        },
        State {
            name: "expanded"
            PropertyChanges { target: viewContainer;  opacity: 0.0; scale: 0.96 }
            PropertyChanges { target: expandedLayer;  opacity: 1.0; scale: 1.0; visible: true }
        }
    ]

    // ── Transitions ───────────────────────────────────────────────────────
    transitions: [
        // Expand: deck → expanded (elementMove timing)
        Transition {
            from: "deck"
            to: "expanded"
            ParallelAnimation {
                NumberAnimation {
                    target: viewContainer; property: "opacity"
                    duration: Appearance.animation.elementMove.duration
                    easing.type: Appearance.animation.elementMove.type
                    easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                }
                NumberAnimation {
                    target: viewContainer; property: "scale"
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
                // visible on expandedLayer is set by state entry, not animated.
            }
        },
        // Collapse: expanded → deck (elementMoveEnter — deck re-emerging is the entrance)
        Transition {
            from: "expanded"
            to: "deck"
            SequentialAnimation {
                ParallelAnimation {
                    NumberAnimation {
                        target: viewContainer; property: "opacity"
                        duration: Appearance.animation.elementMoveEnter.duration
                        easing.type: Appearance.animation.elementMoveEnter.type
                        easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
                    }
                    NumberAnimation {
                        target: viewContainer; property: "scale"
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
                // Hide expandedLayer AFTER fade completes, not at state entry.
                // Without this, the layer vanishes immediately and the collapse is invisible.
                PropertyAction { target: expandedLayer; property: "visible"; value: false }
            }
        }
    ]
}
