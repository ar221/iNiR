import qs.modules.common
import qs.modules.common.widgets
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

    color: "transparent"

    StyledText {
        anchors.centerIn: parent
        text: "[NowPlayingHero placeholder]"
        color: Appearance.colors.colOnLayer1Inactive
        opacity: 0.4
        font.pixelSize: Appearance.font.pixelSize.small
    }
}
