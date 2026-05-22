pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects as GE
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Rectangle {
    id: root
    Layout.fillWidth: true
    implicitHeight: wallpaperLayout.implicitHeight + 16
    readonly property bool showSchemeChips: Config.options?.controlPanel?.showWallpaperSchemeChips ?? false
    
    readonly property bool inirEverywhere: Appearance.inirEverywhere
    readonly property bool auroraEverywhere: Appearance.auroraEverywhere

    radius: Appearance.controlPanel.radiusCard
    color: Appearance.controlPanel.colCard
    border.width: Appearance.angelEverywhere ? Appearance.angel.cardBorderWidth : Appearance.controlPanel.borderWidth
    border.color: Appearance.controlPanel.colCardBorder

    ColumnLayout {
        id: wallpaperLayout
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            MaterialSymbol {
                text: "wallpaper"
                iconSize: 16
                color: Appearance.controlPanel.colAccent
            }

            StyledText {
                text: Translation.tr("Wallpaper")
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.Medium
                color: Appearance.controlPanel.colText
            }

            Item { Layout.fillWidth: true }

            RippleButton {
                implicitWidth: 26
                implicitHeight: 26
                buttonRadius: Appearance.controlPanel.radiusButton
                colBackground: "transparent"
                colBackgroundHover: Appearance.controlPanel.colButtonHover
                onClicked: Wallpapers.randomFromCurrentFolder()
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: "shuffle"
                    iconSize: 14
                    color: Appearance.controlPanel.colTextSecondary
                }
                StyledToolTip { text: Translation.tr("Random") }
            }

            RippleButton {
                implicitWidth: 26
                implicitHeight: 26
                buttonRadius: Appearance.controlPanel.radiusButton
                colBackground: "transparent"
                colBackgroundHover: Appearance.controlPanel.colButtonHover
                onClicked: GlobalActions.runLauncher(["wallpaperSelector", "toggle"])
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: "folder_open"
                    iconSize: 14
                    color: Appearance.controlPanel.colTextSecondary
                }
                StyledToolTip { text: Translation.tr("Browse") }
            }
        }

        // Preview
        Item {
            id: previewContainer
            Layout.fillWidth: true
            Layout.preferredHeight: 100

            Rectangle {
                id: previewMask
                anchors.fill: parent
                radius: Appearance.controlPanel.radiusSmall
                visible: false
            }

            Image {
                id: wallpaperPreview
                anchors.fill: parent
                source: Wallpapers.effectiveWallpaperUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                smooth: true
                mipmap: true
                sourceSize.width: previewContainer.width * 2
                sourceSize.height: previewContainer.height * 2
                layer.enabled: true
                layer.effect: GE.OpacityMask {
                    maskSource: previewMask
                }
            }

            // Dark fade at bottom (masked to match preview corners)
            Item {
                id: fadeContainer
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 32

                Rectangle {
                    id: fadeMask
                    anchors.fill: parent
                    radius: Appearance.controlPanel.radiusSmall
                    visible: false
                }

                Rectangle {
                    id: fadeRect
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.4) }
                    }
                    visible: false
                }

                GE.OpacityMask {
                    anchors.fill: parent
                    source: fadeRect
                    maskSource: fadeMask
                }
            }
        }

        Loader {
            Layout.fillWidth: true
            active: root.showSchemeChips
            sourceComponent: ConfigSelectionArray {
                Layout.fillWidth: true
                enabled: (Config.options?.appearance?.theme ?? "auto") !== "apollo"
                opacity: enabled ? 1.0 : 0.45
                currentValue: Config.options?.appearance?.palette?.type ?? "auto"
                onSelected: newValue => {
                    Config.setNestedValue("appearance.palette.type", newValue)
                    if (ThemeService.isAutoTheme) {
                        Quickshell.execDetached(["/usr/bin/bash", "-c", `${Directories.wallpaperSwitchScriptPath} --noswitch --type ${newValue}`]);
                    } else {
                        const hex = MaterialThemeLoader.colorToHex(Appearance.m3colors.m3primary)
                        const mode = Appearance.m3colors.darkmode ? "dark" : "light"
                        MaterialThemeLoader.applySchemeVariant(hex, newValue, mode)
                    }
                }
                options: [
                    { "value": "auto", "displayName": Translation.tr("Auto") },
                    { "value": "scheme-content", "displayName": Translation.tr("Content") },
                    { "value": "scheme-expressive", "displayName": Translation.tr("Expressive") },
                    { "value": "scheme-fidelity", "displayName": Translation.tr("Fidelity") },
                    { "value": "scheme-fruit-salad", "displayName": Translation.tr("Fruit Salad") },
                    { "value": "scheme-monochrome", "displayName": Translation.tr("Monochrome") },
                    { "value": "scheme-neutral", "displayName": Translation.tr("Neutral") },
                    { "value": "scheme-rainbow", "displayName": Translation.tr("Rainbow") },
                    { "value": "scheme-tonal-spot", "displayName": Translation.tr("Tonal Spot") }
                ]
            }
        }
    }
}
