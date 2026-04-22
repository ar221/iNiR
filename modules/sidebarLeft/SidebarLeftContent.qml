import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.sidebarLeft.deck
import QtQuick
import QtQuick.Layouts
import Quickshell

/**
 * Left sidebar content — The Deck.
 *
 * Hosts DeckSurface: a nav-rail-driven surface with three views (Media, Wallhaven,
 * System). Replaced the Cockpit (CockpitSurface) in The Deck Campaign 2026-04.
 */
Item {
    id: root
    property int sidebarWidth: Appearance.sizes.sidebarWidth
    property int sidebarPadding: 10
    property int screenWidth: 1920
    property int screenHeight: 1080
    property var panelScreen: null

    function focusActiveItem() {
        deck.forceActiveFocus()
    }

    SidebarBackground {
        id: bg
        anchors.fill: parent
        side: "left"
        panelScreen: root.panelScreen
        screenWidth: root.screenWidth
        screenHeight: root.screenHeight
        sidebarWidth: root.sidebarWidth
        sidebarPadding: root.sidebarPadding
        audioTrail: true

        DeckSurface {
            id: deck
            anchors.fill: parent
            anchors.margins: root.sidebarPadding
            anchors.topMargin: Appearance.angelEverywhere ? root.sidebarPadding + 4
                : Appearance.inirEverywhere ? root.sidebarPadding + 6 : root.sidebarPadding
        }

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                GlobalStates.sidebarLeftOpen = false
            }
        }
    }
}
