import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services
import qs.modules.sidebarRight.notifications
import qs.modules.sidebarRight.volumeMixer
import Qt5Compat.GraphicalEffects as GE
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    radius: Appearance.sidebar.radiusCard
    // M3 tier audit: material fallback remains surfaceContainerHigh via sidebar.colCard.
    color: Appearance.sidebar.colCard
    border.width: Appearance.sidebar.borderWidth
    border.color: Appearance.sidebar.colCardBorder

    AngelPartialBorder { targetRadius: root.radius; coverage: 0.5 }

    NotificationList {
        anchors.fill: parent
        anchors.margins: 5
    }
}
