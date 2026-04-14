import qs.modules.common
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

    color: Appearance.colors.colLayer2
    radius: Appearance.rounding.normal
    border.width: 1
    border.color: Appearance.colors.colOutlineVariant

    StyledText {
        anchors.centerIn: parent
        text: "[WallpaperPalette placeholder]"
        color: Appearance.colors.colOnLayer1
        font.pixelSize: Appearance.font.pixelSize.small
    }
}
