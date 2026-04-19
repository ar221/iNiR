pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

ContentPage {
    settingsPageIndex: 2
    settingsPageName: Translation.tr("Audio Effects")
    settingsPageIcon: "equalizer"

    // ── EasyEffects Integration ───────────────────────────────────────────────
    SettingsCardSection {
        expanded: true
        icon: "equalizer"
        title: Translation.tr("EasyEffects")

        SettingsGroup {

            // Status row (read-only info)
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                MaterialSymbol {
                    text: EasyEffects.available ? "check_circle" : "cancel"
                    iconSize: 16
                    color: EasyEffects.available
                        ? Appearance.colors.colPrimary
                        : ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.45)
                }

                Text {
                    Layout.fillWidth: true
                    text: EasyEffects.available
                        ? (EasyEffects.nativeInstalled
                            ? Translation.tr("EasyEffects: native install detected")
                            : Translation.tr("EasyEffects: flatpak install detected"))
                        : Translation.tr("EasyEffects: not found")
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.family: Appearance.font.family.main
                    color: Appearance.colors.colOnSurfaceVariant
                    wrapMode: Text.WordWrap
                }
            }

            // Socket connection status
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    width: 8
                    height: 8
                    radius: 4
                    color: {
                        if (EasyEffects.socketConnected) return "#4caf50"
                        if (EasyEffects.active)          return "#ff9800"
                        return ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.30)
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: EasyEffects.socketConnected
                        ? Translation.tr("Socket: connected")
                        : (EasyEffects.active
                            ? Translation.tr("Socket: connecting…")
                            : Translation.tr("Socket: not connected"))
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.family: Appearance.font.family.main
                    color: Appearance.colors.colOnSurfaceVariant
                }
            }

            // Show Audio FX view in Deck toggle
            SettingsSwitch {
                buttonIcon: "equalizer"
                text: Translation.tr("Show Audio FX in Deck")
                checked: Config.options?.sidebar?.deck?.audioFX?.enable ?? true
                onCheckedChanged: Config.setNestedValue("sidebar.deck.audioFX.enable", checked)
            }

            // Enable/disable EasyEffects process
            SettingsSwitch {
                buttonIcon: "power_settings_new"
                text: Translation.tr("Enable EasyEffects")
                checked: EasyEffects.active
                enabled: EasyEffects.available
                onCheckedChanged: {
                    if (checked !== EasyEffects.active) EasyEffects.toggle()
                }
            }
        }
    }

    // ── Plugin Cards Visibility ───────────────────────────────────────────────
    SettingsCardSection {
        expanded: true
        icon: "tune"
        title: Translation.tr("Plugin Cards")

        SettingsGroup {
            SettingsSwitch {
                buttonIcon: "equalizer"
                text: Translation.tr("Show Equalizer card")
                checked: Config.options?.sidebar?.deck?.audioFX?.plugins?.equalizer ?? true
                onCheckedChanged: Config.setNestedValue("sidebar.deck.audioFX.plugins.equalizer", checked)
            }

            SettingsSwitch {
                buttonIcon: "compress"
                text: Translation.tr("Show Compressor card")
                checked: Config.options?.sidebar?.deck?.audioFX?.plugins?.compressor ?? true
                onCheckedChanged: Config.setNestedValue("sidebar.deck.audioFX.plugins.compressor", checked)
            }

            SettingsSwitch {
                buttonIcon: "volume_down"
                text: Translation.tr("Show Limiter card")
                checked: Config.options?.sidebar?.deck?.audioFX?.plugins?.limiter ?? true
                onCheckedChanged: Config.setNestedValue("sidebar.deck.audioFX.plugins.limiter", checked)
            }

            SettingsSwitch {
                buttonIcon: "waves"
                text: Translation.tr("Show Reverb card")
                checked: Config.options?.sidebar?.deck?.audioFX?.plugins?.reverb ?? false
                onCheckedChanged: Config.setNestedValue("sidebar.deck.audioFX.plugins.reverb", checked)
            }

            SettingsSwitch {
                buttonIcon: "diamond"
                text: Translation.tr("Show Crystalizer card")
                checked: Config.options?.sidebar?.deck?.audioFX?.plugins?.crystalizer ?? false
                onCheckedChanged: Config.setNestedValue("sidebar.deck.audioFX.plugins.crystalizer", checked)
            }
        }
    }

    // ── Display Options ───────────────────────────────────────────────────────
    SettingsCardSection {
        expanded: false
        icon: "visibility"
        title: Translation.tr("Display")

        SettingsGroup {
            SettingsSwitch {
                buttonIcon: "sliders"
                text: Translation.tr("Show plugin sliders")
                checked: Config.options?.sidebar?.deck?.audioFX?.showSliders ?? true
                onCheckedChanged: Config.setNestedValue("sidebar.deck.audioFX.showSliders", checked)
            }

            SettingsSwitch {
                buttonIcon: "piano"
                text: Translation.tr("Show EQ editor button")
                checked: Config.options?.sidebar?.deck?.audioFX?.showEqEditor ?? true
                onCheckedChanged: Config.setNestedValue("sidebar.deck.audioFX.showEqEditor", checked)
            }
        }
    }
}
