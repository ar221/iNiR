import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

/**
 * Context Strip — slim row at the very bottom of the cockpit.
 *
 * Session A: stub placeholder. Session H will build the rotating-slot logic
 * (ProjectPulse / NextUp / SteamStatus) with tap-to-cycle and pinned default.
 */
Rectangle {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: 52

    color: Appearance.colors.colLayer2
    radius: Appearance.rounding.normal
    border.width: 1
    border.color: Appearance.colors.colOutlineVariant

    StyledText {
        anchors.centerIn: parent
        text: "[ContextStrip placeholder]"
        color: Appearance.colors.colOnLayer1Inactive
        font.pixelSize: Appearance.font.pixelSize.smaller
    }
}
