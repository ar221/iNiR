import qs.modules.common
import QtQuick
import QtQuick.Layouts

/**
 * System Pulse instrument — middle of cockpit.
 *
 * Session A: stub placeholder. Session D will build CPU/GPU paired rings with
 * temp-as-color, RAM/VRAM secondary bars, ResourceUsage binding, sidebar-open
 * guard timers. Replaces StatusRings.qml (deleted in Session D).
 */
Rectangle {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: Math.round(parent ? parent.height * 0.22 : 120)
    Layout.minimumHeight: 100

    color: Appearance.colors.colLayer2
    radius: Appearance.rounding.normal
    border.width: 1
    border.color: Appearance.colors.colOutlineVariant

    StyledText {
        anchors.centerIn: parent
        text: "[SystemPulse placeholder]"
        color: Appearance.colors.colOnLayer1
        font.pixelSize: Appearance.font.pixelSize.small
    }
}
