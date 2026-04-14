import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

/**
 * Wallpaper Palette — ~25% of cockpit, near the bottom.
 *
 * Session A: stub placeholder. Session E will build thumbnail strip + Material
 * You palette swatches + tap-to-switch + expand-to-Wallhaven (Session G).
 */
Rectangle {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: Math.round(parent ? parent.height * 0.25 : 140)
    Layout.minimumHeight: 110

    color: "transparent"

    StyledText {
        anchors.centerIn: parent
        text: "[WallpaperPalette placeholder]"
        color: Appearance.colors.colOnLayer1Inactive
        opacity: 0.4
        font.pixelSize: Appearance.font.pixelSize.small
    }
}
