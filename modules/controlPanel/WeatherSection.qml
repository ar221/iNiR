pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Rectangle {
    id: root
    Layout.fillWidth: true
    implicitHeight: visible ? contentLayout.implicitHeight + 16 : 0
    visible: Weather.readyForDisplay
    readonly property bool compactMode: Config.options?.controlPanel?.compactMode ?? true
    
    readonly property bool inirEverywhere: Appearance.inirEverywhere
    readonly property bool auroraEverywhere: Appearance.auroraEverywhere
    readonly property bool hideLocation: Config.options?.waffles?.widgetsPanel?.weatherHideLocation ?? false
    readonly property string weatherDescription: Weather.describeWeather(Weather.data?.wCode ?? "113")
    readonly property string locationText: Weather.visibleCity
    readonly property string secondaryText: locationText || root.weatherDescription

    radius: Appearance.controlPanel.radiusCard
    color: Appearance.controlPanel.colCard
    border.width: Appearance.controlPanel.borderWidth
    border.color: Appearance.controlPanel.colCardBorder

    AngelPartialBorder { targetRadius: parent.radius; coverage: 0.45 }

    ColumnLayout {
        id: contentLayout
        anchors.fill: parent
        anchors.margins: root.compactMode ? 6 : 8
        spacing: root.compactMode ? 2 : 4

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            MaterialSymbol {
                text: Icons.getWeatherIcon(Weather.data?.wCode, Weather.isNightNow()) ?? "cloud"
                iconSize: root.compactMode ? 26 : 32
                color: Appearance.controlPanel.colAccent
                Layout.alignment: Qt.AlignVCenter
            }

            StyledText {
                text: Weather.data?.temp ?? "--°"
                font.pixelSize: root.compactMode ? Appearance.font.pixelSize.larger : Appearance.font.pixelSize.huge
                font.weight: Font.Medium
                font.family: Appearance.font.family.numbers
                color: Appearance.controlPanel.colText
                Layout.alignment: Qt.AlignVCenter
            }

            Item {
                Layout.fillWidth: true
            }

            RowLayout {
                spacing: 4
                Layout.alignment: Qt.AlignVCenter

                MaterialSymbol {
                    text: root.hideLocation ? "visibility_off" : "visibility"
                    iconSize: 14
                    color: Appearance.controlPanel.colTextSecondary
                    opacity: root.hideLocation ? 1 : 0.7
                }

                StyledSwitch {
                    id: privacySwitch
                    checked: root.hideLocation
                    scale: 0.6
                    Layout.alignment: Qt.AlignVCenter
                    onToggled: Config.setNestedValue("waffles.widgetsPanel.weatherHideLocation", checked)
                    StyledToolTip {
                        text: Translation.tr("Hide weather location")
                    }
                }
            }

            RippleButton {
                implicitWidth: root.compactMode ? 24 : 28
                implicitHeight: root.compactMode ? 24 : 28
                buttonRadius: Appearance.controlPanel.radiusButton
                colBackground: "transparent"
                colBackgroundHover: Appearance.controlPanel.colButtonHover
                onClicked: Weather.forceRefresh()
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: "refresh"
                    iconSize: root.compactMode ? 14 : 16
                    color: Appearance.controlPanel.colTextSecondary
                }
                StyledToolTip { text: Translation.tr("Refresh") }
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: root.compactMode ? 34 : 42
            text: root.secondaryText
            font.pixelSize: root.hideLocation ? Appearance.font.pixelSize.small : Appearance.font.pixelSize.smallest
            color: Appearance.controlPanel.colTextSecondary
            elide: Text.ElideRight
        }
    }
}
