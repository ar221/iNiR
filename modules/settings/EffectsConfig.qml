import qs
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.common.functions as CF

ContentPage {
    id: root
    settingsPageIndex: 4
    settingsPageName: Translation.tr("Effects")
    settingsPageIcon: "blur_on"

    property bool isIiActive: Config.options?.panelFamily !== "waffle"

    SettingsCardSection {
        visible: root.isIiActive
        expanded: true
        icon: "wallpaper"
        title: Translation.tr("Wallpaper effects")

        SettingsGroup {
            SettingsSwitch {
                buttonIcon: "blur_on"
                text: Translation.tr("Enable wallpaper blur")
                checked: Config.options?.background?.effects?.enableBlur ?? false
                onCheckedChanged: {
                    Config.setNestedValue("background.effects.enableBlur", checked);
                }
                StyledToolTip {
                    text: Translation.tr("Blur the wallpaper when windows are present")
                }
            }

            ConfigSpinBox {
                visible: Config.options?.background?.effects?.enableBlur ?? false
                icon: "blur_medium"
                text: Translation.tr("Blur radius")
                value: Config.options?.background?.effects?.blurRadius ?? 32
                from: 0
                to: 100
                stepSize: 2
                onValueChanged: {
                    Config.setNestedValue("background.effects.blurRadius", value);
                }
                StyledToolTip {
                    text: Translation.tr("Amount of blur applied to the wallpaper")
                }
            }

            ConfigSpinBox {
                visible: Config.options?.background?.effects?.enableBlur ?? false
                icon: "blur_circular"
                text: Translation.tr("Thumbnail blur strength (%)")
                value: Config.options?.background?.effects?.thumbnailBlurStrength ?? 50
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                    Config.setNestedValue("background.effects.thumbnailBlurStrength", value);
                }
                StyledToolTip {
                    text: Translation.tr("Blur strength for video wallpapers (percentage of full blur radius)")
                }
            }

            ConfigSpinBox {
                icon: "brightness_6"
                text: Translation.tr("Dim overlay (%)")
                value: Config.options?.background?.effects?.dim ?? 0
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                    Config.setNestedValue("background.effects.dim", value);
                }
                StyledToolTip {
                    text: Translation.tr("Adds a dark overlay over the wallpaper. 0 = no dimming, 100 = completely black")
                    // Only show when hovering the spinbox; avoid always-on tooltips
                    extraVisibleCondition: false
                    alternativeVisibleCondition: parent && parent.hovered !== undefined ? parent.hovered : false
                }
            }

            ConfigSpinBox {
                icon: "brightness_low"
                text: Translation.tr("Extra dim when windows (%)")
                value: Config.options?.background?.effects?.dynamicDim ?? 0
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                    Config.setNestedValue("background.effects.dynamicDim", value);
                }
                StyledToolTip {
                    text: Translation.tr("Additional dim applied when there are windows on the current workspace.")
                    extraVisibleCondition: false
                    alternativeVisibleCondition: parent && parent.hovered !== undefined ? parent.hovered : false
                }
            }

            ContentSubsection {
                title: Translation.tr("Fluid Ripple (AOSP Port)")

                SettingsSwitch {
                    buttonIcon: "check_circle"
                    text: Translation.tr("Enable all ripples")
                    checked: Config.options?.background?.effects?.ripple?.enable ?? false
                    onCheckedChanged: {
                        Config.setNestedValue("background.effects.ripple.enable", checked);
                    }
                    StyledToolTip {
                        text: Translation.tr("Authentic Android sparkle-style ripples.\nLicensed under Apache 2.0 (AOSP).")
                    }
                }

                SettingsGroup {
                    visible: Config.options?.background?.effects?.ripple?.enable ?? false

                    SettingsSwitch {
                        buttonIcon: "bolt"
                        text: Translation.tr("On charging")
                        checked: Config.options?.background?.effects?.ripple?.charging ?? true
                        onCheckedChanged: {
                            Config.setNestedValue("background.effects.ripple.charging", checked);
                        }
                    }

                    SettingsSwitch {
                        buttonIcon: "grid_view"
                        text: Translation.tr("On Niri overview open")
                        checked: Config.options?.background?.effects?.ripple?.overview ?? true
                        onCheckedChanged: {
                            Config.setNestedValue("background.effects.ripple.overview", checked);
                        }
                    }

                    SettingsSwitch {
                        buttonIcon: "near_me"
                        text: Translation.tr("On hotcorner activation")
                        checked: Config.options?.background?.effects?.ripple?.hotcorners ?? true
                        onCheckedChanged: {
                            Config.setNestedValue("background.effects.ripple.hotcorners", checked);
                        }
                    }

                    SettingsSwitch {
                        buttonIcon: "refresh"
                        text: Translation.tr("On shell reload")
                        checked: Config.options?.background?.effects?.ripple?.reload ?? true
                        onCheckedChanged: {
                            Config.setNestedValue("background.effects.ripple.reload", checked);
                        }
                    }

                    SettingsSwitch {
                        buttonIcon: "lock"
                        text: Translation.tr("On screen lock")
                        checked: Config.options?.background?.effects?.ripple?.lock ?? true
                        onCheckedChanged: {
                            Config.setNestedValue("background.effects.ripple.lock", checked);
                        }
                    }

                    SettingsSwitch {
                        buttonIcon: "logout"
                        text: Translation.tr("On session screen open")
                        checked: Config.options?.background?.effects?.ripple?.session ?? true
                        onCheckedChanged: {
                            Config.setNestedValue("background.effects.ripple.session", checked);
                        }
                    }

                    SettingsDivider {}

                    ConfigSpinBox {
                        icon: "schedule"
                        text: Translation.tr("Animation duration (ms)")
                        value: Config.options?.background?.effects?.ripple?.rippleDuration ?? 3000
                        from: 500
                        to: 10000
                        stepSize: 250
                        onValueChanged: {
                            Config.setNestedValue("background.effects.ripple.rippleDuration", value);
                        }
                        StyledToolTip {
                            text: Translation.tr("How long the ripple lasts. Higher = slower expansion.")
                        }
                    }

                    SettingsDivider {}

                    StyledText {
                        Layout.fillWidth: true
                        text: Translation.tr("Visual tuning")
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer0
                    }

                    ConfigSpinBox {
                        icon: "auto_awesome"
                        text: Translation.tr("Sparkle intensity")
                        value: Math.round((Config.options?.background?.effects?.ripple?.sparkleIntensity ?? 1.0) * 100)
                        from: 0
                        to: 200
                        stepSize: 10
                        onValueChanged: {
                            Config.setNestedValue("background.effects.ripple.sparkleIntensity", value / 100);
                        }
                        StyledToolTip {
                            text: Translation.tr("Controls the shimmer/sparkle particles. 0 = none, 100 = default, 200 = intense.")
                        }
                    }

                    ConfigSpinBox {
                        icon: "flare"
                        text: Translation.tr("Glow intensity")
                        value: Math.round((Config.options?.background?.effects?.ripple?.glowIntensity ?? 1.0) * 100)
                        from: 0
                        to: 200
                        stepSize: 10
                        onValueChanged: {
                            Config.setNestedValue("background.effects.ripple.glowIntensity", value / 100);
                        }
                        StyledToolTip {
                            text: Translation.tr("Controls the soft glow behind the ring. 0 = none, 100 = default, 200 = strong.")
                        }
                    }

                    ConfigSpinBox {
                        icon: "radio_button_checked"
                        text: Translation.tr("Ring width")
                        value: Math.round((Config.options?.background?.effects?.ripple?.ringWidth ?? 0.15) * 100)
                        from: 5
                        to: 50
                        stepSize: 1
                        onValueChanged: {
                            Config.setNestedValue("background.effects.ripple.ringWidth", value / 100);
                        }
                        StyledToolTip {
                            text: Translation.tr("Thickness of the expanding ring. 5 = thin laser, 15 = default, 50 = wide wash.")
                        }
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Backdrop (overview)")

                SettingsSwitch {
                    buttonIcon: "texture"
                    text: Translation.tr("Enable backdrop layer for overview")
                    checked: Config.options?.background?.backdrop?.enable ?? true
                    onCheckedChanged: {
                        Config.setNestedValue("background.backdrop.enable", checked);
                    }
                    StyledToolTip {
                        text: Translation.tr("Show a separate backdrop layer when overview is open")
                    }
                }

                SettingsSwitch {
                    visible: Config.options?.background?.backdrop?.enable ?? true
                    buttonIcon: "palette"
                    text: Translation.tr("Derive theme colors from backdrop")
                    checked: Config.options?.appearance?.wallpaperTheming?.useBackdropForColors ?? false
                    onCheckedChanged: {
                        Config.setNestedValue("appearance.wallpaperTheming.useBackdropForColors", checked)
                        // Regenerate on both ON and OFF when backdrop has a custom wallpaper
                        if (!(Config.options?.background?.backdrop?.useMainWallpaper ?? true)) {
                            Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--noswitch"])
                        }
                    }
                    StyledToolTip {
                        text: Translation.tr("Generate theme colors from the backdrop wallpaper instead of the main wallpaper.\nRequires a custom backdrop wallpaper (not 'Use main wallpaper').")
                    }
                }

                SettingsSwitch {
                    visible: Config.options?.background?.backdrop?.enable ?? true
                    buttonIcon: "play_circle"
                    text: Translation.tr("Enable animated wallpapers (videos/GIFs)")
                    checked: Config.options?.background?.backdrop?.enableAnimation ?? true
                    onCheckedChanged: {
                        Config.setNestedValue("background.backdrop.enableAnimation", checked);
                    }
                    StyledToolTip {
                        text: Translation.tr("Play videos and GIFs in backdrop (may impact performance)")
                    }
                }

                SettingsSwitch {
                    visible: (Config.options?.background?.backdrop?.enable ?? true) && (Config.options?.background?.backdrop?.enableAnimation ?? true)
                    buttonIcon: "blur_circular"
                    text: Translation.tr("Blur animated wallpapers (videos/GIFs)")
                    checked: Config.options?.background?.backdrop?.enableAnimatedBlur ?? false
                    onCheckedChanged: {
                        Config.setNestedValue("background.backdrop.enableAnimatedBlur", checked);
                    }
                    StyledToolTip {
                        text: Translation.tr("Apply blur effect to animated wallpapers in backdrop. May significantly impact performance.")
                    }
                }

                SettingsSwitch {
                    visible: Config.options?.background?.backdrop?.enable ?? true
                    buttonIcon: "blur_on"
                    text: Translation.tr("Aurora glass effect")
                    checked: Config.options?.background?.backdrop?.useAuroraStyle ?? false
                    onCheckedChanged: {
                        Config.setNestedValue("background.backdrop.useAuroraStyle", checked);
                    }
                    StyledToolTip {
                        text: Translation.tr("Use glass blur effect with adaptive colors from wallpaper (same as sidebars)")
                    }
                }

                ConfigSpinBox {
                    visible: (Config.options?.background?.backdrop?.enable ?? true) && (Config.options?.background?.backdrop?.useAuroraStyle ?? false)
                    icon: "opacity"
                    text: Translation.tr("Aurora overlay opacity (%)")
                    value: Math.round((Config.options?.background?.backdrop?.auroraOverlayOpacity ?? 0.5) * 100)
                    from: 0
                    to: 200
                    stepSize: 5
                    onValueChanged: {
                        Config.setNestedValue("background.backdrop.auroraOverlayOpacity", value / 100.0);
                    }
                    StyledToolTip {
                        text: Translation.tr("Transparency of the color overlay on the blurred wallpaper")
                    }
                }

                SettingsSwitch {
                    visible: Config.options?.background?.backdrop?.enable ?? true
                    buttonIcon: "visibility_off"
                    text: Translation.tr("Hide main wallpaper (show only backdrop)")
                    checked: Config.options?.background?.backdrop?.hideWallpaper ?? false
                    onCheckedChanged: {
                        Config.setNestedValue("background.backdrop.hideWallpaper", checked);
                    }
                    StyledToolTip {
                        text: Translation.tr("Only show the backdrop, hide the main wallpaper entirely")
                    }
                }

                SettingsSwitch {
                    visible: (Config.options?.background?.backdrop?.enable ?? true) && !(Config.options?.background?.backdrop?.hideWallpaper ?? false)
                    buttonIcon: "image"
                    text: Translation.tr("Use main wallpaper")
                    checked: Config.options?.background?.backdrop?.useMainWallpaper ?? true
                    onCheckedChanged: {
                        Config.setNestedValue("background.backdrop.useMainWallpaper", checked);
                        if (checked) {
                            Config.setNestedValue("background.backdrop.wallpaperPath", "");
                        }
                    }
                    StyledToolTip {
                        text: Translation.tr("Use the same wallpaper for backdrop as the main wallpaper")
                    }
                }

                TextEdit {
                    visible: (Config.options?.background?.backdrop?.enable ?? true)
                             && !(Config.options?.background?.backdrop?.useMainWallpaper ?? true)
                    Layout.fillWidth: true
                    text: Config.options?.background?.backdrop?.wallpaperPath ?? ""
                    wrapMode: TextEdit.NoWrap
                    onTextChanged: {
                        Config.setNestedValue("background.backdrop.wallpaperPath", text);
                    }
                }

                RippleButtonWithIcon {
                    visible: !(Config.options?.background?.backdrop?.useMainWallpaper ?? true)
                    Layout.fillWidth: true
                    buttonRadius: Appearance.rounding.small
                    materialIcon: "wallpaper"
                    mainText: Translation.tr("Pick backdrop wallpaper")
                    onClicked: {
                        Config.setNestedValue("wallpaperSelector.selectionTarget", "backdrop")
                        Quickshell.execDetached([Quickshell.shellPath("scripts/inir"), "wallpaperSelector", "toggle"]);
                    }
                }

                ConfigSpinBox {
                    visible: Config.options?.background?.backdrop?.enable ?? true
                    icon: "blur_on"
                    text: Translation.tr("Backdrop blur radius")
                    value: Config.options?.background?.backdrop?.blurRadius ?? 64
                    from: 0
                    to: 100
                    stepSize: 2
                    onValueChanged: {
                        Config.setNestedValue("background.backdrop.blurRadius", value);
                    }
                    StyledToolTip {
                        text: Translation.tr("Amount of blur applied to the backdrop layer")
                    }
                }

                ConfigSpinBox {
                    visible: Config.options?.background?.backdrop?.enable ?? true
                    icon: "brightness_5"
                    text: Translation.tr("Backdrop dim (%)")
                    value: Config.options?.background?.backdrop?.dim ?? 20
                    from: 0
                    to: 100
                    stepSize: 5
                    onValueChanged: {
                        Config.setNestedValue("background.backdrop.dim", value);
                    }
                    StyledToolTip {
                        text: Translation.tr("Darken the backdrop layer")
                    }
                }

                ConfigSpinBox {
                    visible: Config.options?.background?.backdrop?.enable ?? true
                    icon: "palette"
                    text: Translation.tr("Backdrop saturation")
                    value: Math.round((Config.options?.background?.backdrop?.saturation ?? 0) * 100)
                    from: -100
                    to: 100
                    stepSize: 5
                    onValueChanged: {
                        Config.setNestedValue("background.backdrop.saturation", value / 100.0);
                    }
                    StyledToolTip {
                        text: Translation.tr("Increase or decrease color intensity of the backdrop")
                    }
                }

                ConfigSpinBox {
                    visible: Config.options?.background?.backdrop?.enable ?? true
                    icon: "contrast"
                    text: Translation.tr("Backdrop contrast")
                    value: Math.round((Config.options?.background?.backdrop?.contrast ?? 0) * 100)
                    from: -100
                    to: 100
                    stepSize: 5
                    onValueChanged: {
                        Config.setNestedValue("background.backdrop.contrast", value / 100.0);
                    }
                    StyledToolTip {
                        text: Translation.tr("Increase or decrease light/dark difference in the backdrop")
                    }
                }

                ConfigRow {
                    uniform: true
                    visible: Config.options?.background?.backdrop?.enable ?? true
                    SettingsSwitch {
                        buttonIcon: "gradient"
                        text: Translation.tr("Enable vignette")
                        checked: Config.options?.background?.backdrop?.vignetteEnabled ?? false
                        onCheckedChanged: {
                            Config.setNestedValue("background.backdrop.vignetteEnabled", checked);
                        }
                        StyledToolTip {
                            text: Translation.tr("Add a dark gradient around the edges of the backdrop")
                        }
                    }
                }

                ConfigSpinBox {
                    visible: (Config.options?.background?.backdrop?.enable ?? true) && (Config.options?.background?.backdrop?.vignetteEnabled ?? false)
                    icon: "blur_circular"
                    text: Translation.tr("Vignette intensity")
                    value: Math.round((Config.options?.background?.backdrop?.vignetteIntensity ?? 0.5) * 100)
                    from: 0
                    to: 100
                    stepSize: 5
                    onValueChanged: {
                        Config.setNestedValue("background.backdrop.vignetteIntensity", value / 100.0);
                    }
                    StyledToolTip {
                        text: Translation.tr("How dark the vignette effect should be")
                    }
                }

                ConfigSpinBox {
                    visible: (Config.options?.background?.backdrop?.enable ?? true) && (Config.options?.background?.backdrop?.vignetteEnabled ?? false)
                    icon: "trip_origin"
                    text: Translation.tr("Vignette radius")
                    value: Math.round((Config.options?.background?.backdrop?.vignetteRadius ?? 0.7) * 100)
                    from: 10
                    to: 100
                    stepSize: 5
                    onValueChanged: {
                        Config.setNestedValue("background.backdrop.vignetteRadius", value / 100.0);
                    }
                    StyledToolTip {
                        text: Translation.tr("How far the vignette extends from the edges")
                    }
                }
            }
        }
    }
}
