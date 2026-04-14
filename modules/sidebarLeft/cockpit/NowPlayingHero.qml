import qs.modules.common
import QtQuick
import QtQuick.Layouts

/**
 * Now Playing hero — top ~40% of cockpit.
 *
 * Session A: stub placeholder. Session C will build out large album art,
 * track metadata, controls, album-art-derived accents, tap-to-expand.
 */
Rectangle {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: Math.round(parent ? parent.height * 0.40 : 200)
    Layout.minimumHeight: 160

    color: Appearance.colors.colLayer2
    radius: Appearance.rounding.normal
    border.width: 1
    border.color: Appearance.colors.colOutlineVariant

    StyledText {
        anchors.centerIn: parent
        text: "[NowPlayingHero placeholder]"
        color: Appearance.colors.colOnLayer1
        font.pixelSize: Appearance.font.pixelSize.small
    }
}
