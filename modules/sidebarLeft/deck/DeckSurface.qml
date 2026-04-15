pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.services

Item {
    id: root

    // ── Public API (mirrors CockpitSurface for drop-in swap) ─────────
    property int currentView: Config.options?.sidebar?.deck?.defaultView ?? 0

    // ── Keyboard ─────────────────────────────────────────────────────
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_1) { root.currentView = 0; event.accepted = true }
        else if (event.key === Qt.Key_2) { root.currentView = 1; event.accepted = true }
        else if (event.key === Qt.Key_3) { root.currentView = 2; event.accepted = true }
    }

    // ── Placeholder content ──────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: Appearance.colors.colLayer0

        Text {
            anchors.centerIn: parent
            text: "The Deck — View " + root.currentView
            color: "#ff1100"
            font.pixelSize: 16
            font.bold: true
        }
    }
}
