import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Rectangle {
    id: root

    property bool editMode: false
    property bool compactMode: false
    readonly property bool cardStyle: Config.options?.sidebar?.cardStyle ?? false

    radius: Appearance.sidebar.radiusCard
    color: cardStyle ? Appearance.sidebar.colCard : "transparent"
    border.width: cardStyle ? Appearance.sidebar.borderWidth : 0
    border.color: cardStyle ? Appearance.sidebar.colCardBorder : "transparent"

    AngelPartialBorder { targetRadius: root.radius; coverage: 0.5; visible: Appearance.angelEverywhere && root.cardStyle }

    signal openAudioOutputDialog()
    signal openAudioInputDialog()
    signal openBluetoothDialog()
    signal openHotspotDialog()
    signal openNightLightDialog()
    signal openWifiDialog()
}
