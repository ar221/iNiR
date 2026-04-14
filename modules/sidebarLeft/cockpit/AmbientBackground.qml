import qs.modules.common
import QtQuick

/**
 * Cockpit ambient surface — the sidebar's skin.
 *
 * Session A: stub placeholder. Session B will make it reactive to album art
 * + wallpaper palette with a base gradient from colLayer1 -> a subtle tinted
 * variant, plus a low-opacity reactive layer on top.
 */
Rectangle {
    id: root
    anchors.fill: parent
    color: Appearance.colors.colLayer1
    radius: Appearance.rounding.small

    StyledText {
        anchors.centerIn: parent
        text: "[AmbientBackground placeholder]"
        color: Appearance.colors.colOnLayer1Inactive
        opacity: 0.4
        font.pixelSize: Appearance.font.pixelSize.smaller
    }
}
