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

    color: "transparent"

    StyledText {
        anchors.centerIn: parent
        text: "[ContextStrip placeholder]"
        color: Appearance.colors.colOnLayer1Inactive
        font.pixelSize: Appearance.font.pixelSize.smaller
    }
}
