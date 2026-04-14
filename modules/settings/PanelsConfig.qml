import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: root
    settingsPageIndex: 7
    settingsPageName: Translation.tr("Panels")
    settingsPageIcon: "bottom_app_bar"

    property bool isIiActive: Config.options?.panelFamily !== "waffle"

    SettingsCardSection {
        expanded: false
        icon: "point_scan"
        title: Translation.tr("Crosshair overlay")

        SettingsGroup {
            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Crosshair code (in Valorant's format)")
                text: Config.options?.crosshair?.code ?? ""
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    Config.options.crosshair.code = text;
                }
            }

            RowLayout {
                StyledText {
                    Layout.leftMargin: 10
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.smallie
                    text: Translation.tr("Press Super+G to toggle appearance")
                }
                Item {
                    Layout.fillWidth: true
                }
                RippleButtonWithIcon {
                    id: editorButton
                    buttonRadius: Appearance.rounding.full
                    materialIcon: "open_in_new"
                    mainText: Translation.tr("Open editor")
                    onClicked: {
                        Qt.openUrlExternally(`https://www.vcrdb.net/builder?c=${Config.options?.crosshair?.code ?? ""}`);
                    }
                    StyledToolTip {
                        text: "www.vcrdb.net"
                    }
                }
            }
        }
    }

    SettingsCardSection {
        expanded: false
        icon: "layers"
        title: Translation.tr("Overlay widgets")

        SettingsGroup {
            ContentSubsection {
                title: Translation.tr("Background & dim")

                SettingsSwitch {
                    buttonIcon: "water"
                    text: Translation.tr("Darken screen behind overlay")
                    checked: Config.options.overlay.darkenScreen
                    onCheckedChanged: {
                        Config.options.overlay.darkenScreen = checked;
                    }
                    StyledToolTip {
                        text: Translation.tr("Add a dark scrim behind overlay panels for better visibility")
                    }
                }

                ConfigSpinBox {
                    icon: "opacity"
                    text: Translation.tr("Overlay scrim dim (%)")
                    value: Config.options.overlay.scrimDim
                    from: 0
                    to: 100
                    stepSize: 5
                    enabled: Config.options.overlay.darkenScreen
                    onValueChanged: {
                        Config.options.overlay.scrimDim = value;
                    }
                    StyledToolTip {
                        text: Translation.tr("How dark the background scrim should be")
                    }
                }

                ConfigSpinBox {
                    icon: "opacity"
                    text: Translation.tr("Overlay background opacity (%)")
                    value: Math.round((Config.options.overlay.backgroundOpacity ?? 0.9) * 100)
                    from: 20
                    to: 100
                    stepSize: 5
                    onValueChanged: {
                        Config.options.overlay.backgroundOpacity = value / 100;
                    }
                    StyledToolTip {
                        text: Translation.tr("Opacity of the overlay panel background")
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Animations")

                SettingsSwitch {
                    buttonIcon: "movie"
                    text: Translation.tr("Enable opening zoom animation")
                    checked: Config.options.overlay.openingZoomAnimation
                    onCheckedChanged: {
                        Config.options.overlay.openingZoomAnimation = checked;
                    }
                    StyledToolTip {
                        text: Translation.tr("Animate overlay panels with a zoom effect when opening")
                    }
                }

                ConfigSpinBox {
                    icon: "speed"
                    text: Translation.tr("Overlay animation duration (ms)")
                    value: Config.options.overlay.animationDurationMs ?? 180
                    from: 0
                    to: 1000
                    stepSize: 20
                    onValueChanged: {
                        Config.options.overlay.animationDurationMs = value;
                    }
                    StyledToolTip {
                        text: Translation.tr("Duration of overlay open/close animations")
                    }
                }

                ConfigSpinBox {
                    icon: "speed"
                    text: Translation.tr("Background dim animation (ms)")
                    value: Config.options.overlay.scrimAnimationDurationMs ?? 140
                    from: 0
                    to: 1000
                    stepSize: 20
                    onValueChanged: {
                        Config.options.overlay.scrimAnimationDurationMs = value;
                    }
                    StyledToolTip {
                        text: Translation.tr("Duration of the background scrim fade animation")
                    }
                }
            }
        }
    }

    SettingsCardSection {
        expanded: false
        icon: "forum"
        title: Translation.tr("Overlay: Discord")

        SettingsGroup {
            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Discord launch command (e.g., discord, vesktop, webcord)")
                text: Config.options.apps.discord
                wrapMode: TextEdit.NoWrap
                onTextChanged: {
                    Config.options.apps.discord = text;
                }
            }
        }
    }

    SettingsCardSection {
        visible: root.isIiActive
        expanded: false
        icon: "keyboard_tab"
        title: Translation.tr("Alt-Tab switcher (Material ii)")

        SettingsGroup {
            SettingsSwitch {
                enabled: (Config.options?.altSwitcher?.preset ?? "default") !== "skew"
                buttonIcon: "visibility_off"
                text: Translation.tr("No visual UI (cycle windows only)")
                checked: (Config.options?.altSwitcher?.preset ?? "default") === "skew"
                    ? false
                    : (Config.options?.altSwitcher?.noVisualUi ?? false)
                onCheckedChanged: Config.setNestedValue("altSwitcher.noVisualUi", checked)
                StyledToolTip {
                    text: Translation.tr("Use Alt+Tab to switch windows without showing the switcher overlay")
                }
            }

            SettingsSwitch {
                buttonIcon: "colors"
                text: Translation.tr("Tint app icons")
                checked: Config.options?.altSwitcher?.monochromeIcons ?? false
                onCheckedChanged: Config.setNestedValue("altSwitcher.monochromeIcons", checked)
                StyledToolTip {
                    text: Translation.tr("Apply accent color tint to app icons in the switcher")
                }
            }

            SettingsSwitch {
                buttonIcon: "movie"
                text: Translation.tr("Enable slide animation")
                checked: Config.options?.altSwitcher?.enableAnimation ?? true
                onCheckedChanged: Config.setNestedValue("altSwitcher.enableAnimation", checked)
                StyledToolTip {
                    text: Translation.tr("Animate window selection with a slide effect")
                }
            }

            ConfigSpinBox {
                icon: "speed"
                text: Translation.tr("Animation duration (ms)")
                value: Config.options?.altSwitcher?.animationDurationMs ?? 200
                from: 0
                to: 1000
                stepSize: 25
                onValueChanged: Config.setNestedValue("altSwitcher.animationDurationMs", value)
                StyledToolTip {
                    text: Translation.tr("Duration of the slide animation between windows")
                }
            }

            SettingsSwitch {
                buttonIcon: "history"
                text: Translation.tr("Most recently used first")
                checked: Config.options?.altSwitcher?.useMostRecentFirst ?? true
                onCheckedChanged: Config.setNestedValue("altSwitcher.useMostRecentFirst", checked)
                StyledToolTip {
                    text: Translation.tr("Order windows by most recently focused instead of position")
                }
            }

            ConfigSpinBox {
                icon: "opacity"
                text: Translation.tr("Background opacity (%)")
                value: Math.round((Config.options?.altSwitcher?.backgroundOpacity ?? 0.9) * 100)
                from: 10
                to: 100
                stepSize: 5
                onValueChanged: Config.setNestedValue("altSwitcher.backgroundOpacity", value / 100)
                StyledToolTip {
                    text: Translation.tr("Opacity of the switcher panel background")
                }
            }

            ConfigSpinBox {
                icon: "blur_on"
                text: Translation.tr("Blur amount (%)")
                value: Math.round((Config.options?.altSwitcher?.blurAmount ?? 0.4) * 100)
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: Config.setNestedValue("altSwitcher.blurAmount", value / 100)
                StyledToolTip {
                    text: Translation.tr("Amount of blur applied to the switcher background")
                }
            }

            ConfigSpinBox {
                icon: "opacity"
                text: Translation.tr("Scrim dim (%)")
                value: Config.options?.altSwitcher?.scrimDim ?? 35
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: Config.setNestedValue("altSwitcher.scrimDim", value)
                StyledToolTip {
                    text: Translation.tr("How dark the screen behind the switcher should be")
                }
            }

            ConfigSpinBox {
                icon: "hourglass_top"
                text: Translation.tr("Auto-hide delay after selection (ms)")
                value: Config.options?.altSwitcher?.autoHideDelayMs ?? 500
                from: 50
                to: 2000
                stepSize: 50
                onValueChanged: Config.setNestedValue("altSwitcher.autoHideDelayMs", value)
                StyledToolTip {
                    text: Translation.tr("How long to wait before hiding the switcher after releasing Alt")
                }
            }

            SettingsSwitch {
                buttonIcon: "overview_key"
                text: Translation.tr("Show Niri overview while switching")
                checked: Config.options?.altSwitcher?.showOverviewWhileSwitching ?? false
                onCheckedChanged: Config.setNestedValue("altSwitcher.showOverviewWhileSwitching", checked)
                StyledToolTip {
                    text: Translation.tr("Open Niri's native overview alongside the window switcher")
                }
            }

            ConfigSelectionArray {
                options: [
                    { displayName: Translation.tr("Default (sidebar)"), icon: "side_navigation", value: "default" },
                    { displayName: Translation.tr("List (centered)"), icon: "list", value: "list" },
                    { displayName: Translation.tr("Skew previews"), icon: "view_in_ar", value: "skew" }
                ]
                currentValue: Config.options?.altSwitcher?.preset ?? "default"
                onSelected: (newValue) => {
                    Config.setNestedValue("altSwitcher.preset", newValue)
                    Config.setNestedValue("altSwitcher.noVisualUi", false)
                }
            }

            ContentSubsection {
                title: Translation.tr("Layout & alignment")

                SettingsSwitch {
                    enabled: (Config.options?.altSwitcher?.preset ?? "default") !== "list"
                        && (Config.options?.altSwitcher?.preset ?? "default") !== "skew"
                    buttonIcon: "view_compact"
                    text: Translation.tr("Compact horizontal style (icons only)")
                    checked: Config.options?.altSwitcher?.compactStyle ?? false
                    onCheckedChanged: Config.setNestedValue("altSwitcher.compactStyle", checked)
                    StyledToolTip {
                        text: Translation.tr("Show only app icons in a horizontal row, similar to macOS Spotlight")
                    }
                }

                ConfigSelectionArray {
                    enabled: !(Config.options?.altSwitcher?.compactStyle ?? false)
                        && (Config.options?.altSwitcher?.preset ?? "default") !== "list"
                        && (Config.options?.altSwitcher?.preset ?? "default") !== "skew"
                    currentValue: Config.options?.altSwitcher?.panelAlignment ?? "right"
                    onSelected: newValue => Config.setNestedValue("altSwitcher.panelAlignment", newValue)
                    options: [
                        { displayName: Translation.tr("Align to right edge"), icon: "align_horizontal_right", value: "right" },
                        { displayName: Translation.tr("Center on screen"), icon: "align_horizontal_center", value: "center" }
                    ]
                }

                SettingsSwitch {
                    enabled: !(Config.options?.altSwitcher?.compactStyle ?? false)
                        && (Config.options?.altSwitcher?.preset ?? "default") !== "list"
                        && (Config.options?.altSwitcher?.preset ?? "default") !== "skew"
                    buttonIcon: "styler"
                    text: Translation.tr("Use Material 3 card layout")
                    checked: Config.options?.altSwitcher?.useM3Layout ?? false
                    onCheckedChanged: Config.setNestedValue("altSwitcher.useM3Layout", checked)
                    StyledToolTip {
                        text: Translation.tr("Use Material Design 3 style for the switching panel")
                    }
                }
            }
        }
    }

    SettingsCardSection {
        visible: root.isIiActive
        expanded: false
        icon: "call_to_action"
        title: Translation.tr("Dock")

        SettingsGroup {
            SettingsSwitch {
                buttonIcon: "check"
                text: Translation.tr("Enable")
                checked: Config.options.dock.enable
                onCheckedChanged: {
                    Config.setNestedValue("dock.enable", checked);
                }
                StyledToolTip {
                    text: Translation.tr("Show the macOS-style dock at the bottom of the screen")
                }
            }

            ContentSubsection {
                title: Translation.tr("Dock style")
                tooltip: Translation.tr("Panel: classic unified background. Pill: each icon floats in its own capsule. macOS: frosted glass shelf with magnify effect.")

                ConfigSelectionArray {
                    currentValue: Config.options?.dock?.style ?? "panel"
                    onSelected: newValue => {
                        Config.setNestedValue("dock.style", newValue)
                    }
                    options: [
                        { displayName: Translation.tr("Panel"), icon: "dock_to_bottom", value: "panel" },
                        { displayName: Translation.tr("Pill"),  icon: "interests",       value: "pill"  },
                        { displayName: Translation.tr("macOS"), icon: "desktop_mac",     value: "macos" }
                    ]
                }
            }

            ConfigRow {
                uniform: true
                ContentSubsection {
                    title: Translation.tr("Dock position")

                    ConfigSelectionArray {
                        currentValue: Config.options?.dock?.position ?? "bottom"
                        onSelected: newValue => {
                            Config.setNestedValue('dock.position', newValue);
                        }
                        options: [
                            { displayName: Translation.tr("Top"), icon: "arrow_upward", value: "top" },
                            { displayName: Translation.tr("Left"), icon: "arrow_back", value: "left" },
                            { displayName: Translation.tr("Bottom"), icon: "arrow_downward", value: "bottom" },
                            { displayName: Translation.tr("Right"), icon: "arrow_forward", value: "right" }
                        ]
                    }
                }
                ContentSubsection {
                    title: Translation.tr("Reveal behavior")

                    ConfigSelectionArray {
                        currentValue: Config.options?.dock?.hoverToReveal ?? true
                        onSelected: newValue => {
                            Config.setNestedValue('dock.hoverToReveal', newValue);
                        }
                        options: [
                            { displayName: Translation.tr("Hover"), icon: "highlight_mouse_cursor", value: true },
                            { displayName: Translation.tr("Empty workspace"), icon: "desktop_windows", value: false }
                        ]
                    }
                    SettingsSwitch {
                        buttonIcon: "desktop_windows"
                        text: Translation.tr("Show on desktop")
                        checked: Config.options?.dock?.showOnDesktop ?? true
                        onCheckedChanged: Config.setNestedValue('dock.showOnDesktop', checked)
                        StyledToolTip {
                            text: Translation.tr("Show dock when no window is focused")
                        }
                    }
                }
            }

            ConfigRow {
                uniform: true
                SettingsSwitch {
                    buttonIcon: "keep"
                    text: Translation.tr("Pinned on startup")
                    checked: Config.options.dock.pinnedOnStartup
                    onCheckedChanged: {
                        Config.setNestedValue("dock.pinnedOnStartup", checked);
                    }
                    StyledToolTip {
                        text: Translation.tr("Keep dock visible when the shell starts")
                    }
                }
                SettingsSwitch {
                    buttonIcon: "colors"
                    text: Translation.tr("Tint app icons")
                    checked: Config.options.dock.monochromeIcons
                    onCheckedChanged: {
                        Config.setNestedValue("dock.monochromeIcons", checked);
                    }
                    StyledToolTip {
                        text: Translation.tr("Apply accent color tint to dock app icons")
                    }
                }
            }
            SettingsSwitch {
                buttonIcon: "widgets"
                text: Translation.tr("Show dock background")
                checked: Config.options.dock.showBackground
                onCheckedChanged: Config.setNestedValue("dock.showBackground", checked)
                StyledToolTip {
                    text: Translation.tr("Show a background behind the dock")
                }
            }

            SettingsSwitch {
                buttonIcon: "splitscreen"
                text: Translation.tr("Separate pinned from running")
                checked: Config.options?.dock?.separatePinnedFromRunning ?? true
                onCheckedChanged: Config.setNestedValue('dock.separatePinnedFromRunning', checked)
                StyledToolTip {
                    text: Translation.tr("Show pinned-only apps on the left, running apps on the right with a separator")
                }
            }

            SettingsSwitch {
                buttonIcon: "drag_indicator"
                text: Translation.tr("Drag to reorder")
                checked: Config.options?.dock?.enableDragReorder ?? true
                onCheckedChanged: Config.setNestedValue('dock.enableDragReorder', checked)
                StyledToolTip {
                    text: Translation.tr("Long-press and drag dock icons to reorder pinned apps")
                }
            }

            ContentSubsection {
                title: Translation.tr("Appearance")

                SettingsSwitch {
                    buttonIcon: "branding_watermark"
                    text: Translation.tr("Use Card style")
                    checked: Config.options.dock?.cardStyle ?? false
                    onCheckedChanged: {
                        Config.setNestedValue("dock.cardStyle", checked);
                    }
                    StyledToolTip {
                        text: Translation.tr("Use the new Card style (lighter background, specific rounding) generic to settings")
                    }
                }

                ConfigSpinBox {
                    icon: "height"
                    text: Translation.tr("Dock height (px)")
                    value: Config.options.dock.height ?? 60
                    from: 40
                    to: 100
                    stepSize: 5
                    onValueChanged: {
                        Config.setNestedValue("dock.height", value);
                    }
                    StyledToolTip {
                        text: Translation.tr("Height of the dock container")
                    }
                }

                ConfigSpinBox {
                    icon: "aspect_ratio"
                    text: Translation.tr("Icon size (px)")
                    value: Config.options.dock.iconSize ?? 35
                    from: 20
                    to: 60
                    stepSize: 5
                    onValueChanged: {
                        Config.setNestedValue("dock.iconSize", value);
                    }
                    StyledToolTip {
                        text: Translation.tr("Size of application icons in the dock")
                    }
                }

                ConfigSpinBox {
                    icon: {
                        const pos = Config.options?.dock?.position ?? "bottom"
                        switch (pos) {
                            case "top": return "vertical_align_top"
                            case "left": return "align_horizontal_left"
                            case "right": return "align_horizontal_right"
                            default: return "vertical_align_bottom"
                        }
                    }
                    text: Translation.tr("Hover reveal region size (px)")
                    value: Config.options.dock.hoverRegionHeight ?? 2
                    from: 1
                    to: 20
                    stepSize: 1
                    enabled: Config.options.dock.hoverToReveal
                    onValueChanged: {
                        Config.setNestedValue("dock.hoverRegionHeight", value);
                    }
                    StyledToolTip {
                        text: Translation.tr("Size of the invisible area at screen edge that triggers dock reveal")
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Window indicators")

                SettingsSwitch {
                    buttonIcon: "my_location"
                    text: Translation.tr("Smart indicator (highlight focused window)")
                    checked: Config.options.dock.smartIndicator !== false
                    onCheckedChanged: {
                        Config.setNestedValue("dock.smartIndicator", checked);
                    }
                    StyledToolTip {
                        text: Translation.tr("When multiple windows of the same app are open, highlight which one is focused")
                    }
                }

                SettingsSwitch {
                    buttonIcon: "more_horiz"
                    text: Translation.tr("Show dots for inactive apps")
                    checked: Config.options.dock.showAllWindowDots !== false
                    onCheckedChanged: {
                        Config.setNestedValue("dock.showAllWindowDots", checked);
                    }
                    StyledToolTip {
                        text: Translation.tr("Show a dot per window even for apps that aren't currently focused")
                    }
                }

                ConfigSpinBox {
                    icon: "filter_5"
                    text: Translation.tr("Maximum indicator dots")
                    value: Config.options.dock.maxIndicatorDots ?? 5
                    from: 1
                    to: 10
                    stepSize: 1
                    onValueChanged: {
                        Config.setNestedValue("dock.maxIndicatorDots", value);
                    }
                    StyledToolTip {
                        text: Translation.tr("Limit the number of open window dots shown below an app icon")
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Window preview")

                SettingsSwitch {
                    buttonIcon: "preview"
                    text: Translation.tr("Show preview on hover")
                    checked: Config.options.dock.hoverPreview !== false
                    onCheckedChanged: {
                        Config.setNestedValue("dock.hoverPreview", checked);
                    }
                    StyledToolTip {
                        text: Translation.tr("Display a live preview of windows when hovering over dock icons")
                    }
                }

                ConfigSpinBox {
                    icon: "timer"
                    text: Translation.tr("Hover delay (ms)")
                    value: Config.options.dock.hoverPreviewDelay ?? 400
                    from: 0
                    to: 1000
                    stepSize: 50
                    enabled: Config.options.dock.hoverPreview !== false
                    onValueChanged: {
                        Config.setNestedValue("dock.hoverPreviewDelay", value);
                    }
                    StyledToolTip {
                        text: Translation.tr("Time to wait before showing window preview")
                    }
                }

                SettingsSwitch {
                    buttonIcon: "keep"
                    text: Translation.tr("Keep preview on click")
                    enabled: Config.options.dock.hoverPreview !== false
                    checked: Config.options?.dock?.keepPreviewOnClick ?? false
                    onCheckedChanged: {
                        Config.setNestedValue("dock.keepPreviewOnClick", checked)
                    }
                    StyledToolTip {
                        text: Translation.tr("Don't close the preview popup when clicking a window thumbnail, so you can navigate between windows")
                    }
                }
            }
        }
    }

    SettingsCardSection {
        visible: root.isIiActive
        expanded: false
        icon: "notifications"
        title: Translation.tr("Notifications")

        SettingsGroup {
            ConfigSpinBox {
                icon: "av_timer"
                text: Translation.tr("Timeout (ms)")
                value: Config.options?.notifications?.timeoutNormal ?? 7000
                from: 1000
                to: 30000
                stepSize: 500
                onValueChanged: {
                    Config.setNestedValue("notifications.timeoutNormal", value)
                }
                StyledToolTip {
                    text: Translation.tr("Duration in milliseconds before a notification automatically closes")
                }
            }

            ConfigSwitch {
                buttonIcon: "pinch"
                text: Translation.tr("Scale on hover")
                checked: Config.options?.notifications?.scaleOnHover ?? false
                onCheckedChanged: {
                    Config.setNestedValue("notifications.scaleOnHover", checked)
                }
                StyledToolTip {
                    text: Translation.tr("Slightly enlarge notifications when the mouse hovers over them")
                }
            }
            ConfigSpinBox {
                icon: "vertical_align_top"
                text: Translation.tr("Margin (px)")
                value: Config.options?.notifications?.edgeMargin ?? 4
                from: 0
                to: 100
                stepSize: 1
                onValueChanged: {
                    Config.setNestedValue("notifications.edgeMargin", value)
                }
                StyledToolTip {
                    text: Translation.tr("Spacing between notifications and the screen edge/anchor")
                }
            }

            ConfigSwitch {
                buttonIcon: "sync"
                text: Translation.tr("Auto-sync badge with popup list")
                checked: !(Config.options?.notifications?.useLegacyCounter ?? true)
                onCheckedChanged: {
                    Config.setNestedValue("notifications.useLegacyCounter", !checked)
                }
                StyledToolTip {
                    text: Translation.tr("Automatically sync notification badge with actual popup count.\nFixes issue where externally cleared notifications (e.g., Discord) don't update the badge.\nDisable to use the classic manual counter behavior.")
                }
            }

            ContentSubsection {
                title: Translation.tr("Anchor")

                ConfigSelectionArray {
                    currentValue: Config.options?.notifications?.position ?? "topRight"
                    onSelected: newValue => {
                        Config.setNestedValue("notifications.position", newValue)
                    }
                    options: [
                        { displayName: Translation.tr("Top Right"), icon: "north_east", value: "topRight" },
                        { displayName: Translation.tr("Top Left"), icon: "north_west", value: "topLeft" },
                        { displayName: Translation.tr("Bottom Right"), icon: "south_east", value: "bottomRight" },
                        { displayName: Translation.tr("Bottom Left"), icon: "south_west", value: "bottomLeft" }
                    ]
                }
            }
        }
    }

    SettingsCardSection {
        visible: root.isIiActive
        expanded: false
        icon: "tune"
        title: Translation.tr("Control panel")

        SettingsGroup {
            SettingsSwitch {
                buttonIcon: "density_medium"
                text: Translation.tr("Compact cards")
                checked: Config.options?.controlPanel?.compactMode ?? true
                onCheckedChanged: Config.setNestedValue("controlPanel.compactMode", checked)
                StyledToolTip {
                    text: Translation.tr("Use tighter spacing and shorter cards in the quick settings panel")
                }
            }

            SettingsSwitch {
                buttonIcon: "wallpaper"
                text: Translation.tr("Show wallpaper card")
                checked: Config.options?.controlPanel?.showWallpaperSection ?? true
                onCheckedChanged: Config.setNestedValue("controlPanel.showWallpaperSection", checked)
                StyledToolTip {
                    text: Translation.tr("Show the wallpaper preview card in the quick settings panel")
                }
            }

            SettingsSwitch {
                buttonIcon: "palette"
                text: Translation.tr("Show wallpaper scheme buttons")
                enabled: Config.options?.controlPanel?.showWallpaperSection ?? true
                checked: Config.options?.controlPanel?.showWallpaperSchemeChips ?? false
                onCheckedChanged: Config.setNestedValue("controlPanel.showWallpaperSchemeChips", checked)
                StyledToolTip {
                    text: Translation.tr("Show the scheme variant buttons under the wallpaper preview")
                }
            }

            ContentSubsection {
                title: Translation.tr("Visible sections")

                SettingsSwitch {
                    buttonIcon: "music_note"
                    text: Translation.tr("Media")
                    checked: Config.options?.controlPanel?.showMediaSection ?? true
                    onCheckedChanged: Config.setNestedValue("controlPanel.showMediaSection", checked)
                }

                SettingsSwitch {
                    buttonIcon: "partly_cloudy_day"
                    text: Translation.tr("Weather")
                    checked: Config.options?.controlPanel?.showWeatherSection ?? true
                    onCheckedChanged: Config.setNestedValue("controlPanel.showWeatherSection", checked)
                }

                SettingsSwitch {
                    buttonIcon: "monitoring"
                    text: Translation.tr("System status")
                    checked: Config.options?.controlPanel?.showSystemSection ?? true
                    onCheckedChanged: Config.setNestedValue("controlPanel.showSystemSection", checked)
                }

                SettingsSwitch {
                    buttonIcon: "tune"
                    text: Translation.tr("Sliders")
                    checked: Config.options?.controlPanel?.showSlidersSection ?? true
                    onCheckedChanged: Config.setNestedValue("controlPanel.showSlidersSection", checked)
                }

                SettingsSwitch {
                    buttonIcon: "apps"
                    text: Translation.tr("Quick actions")
                    checked: Config.options?.controlPanel?.showQuickActionsSection ?? true
                    onCheckedChanged: Config.setNestedValue("controlPanel.showQuickActionsSection", checked)
                }
            }

            SettingsSwitch {
                buttonIcon: "memory"
                text: Translation.tr("Keep control panel loaded")
                checked: Config.options?.controlPanel?.keepLoaded ?? false
                onCheckedChanged: Config.setNestedValue("controlPanel.keepLoaded", checked)
                StyledToolTip {
                    text: Translation.tr("Keep the quick settings panel in memory to reduce opening delay")
                }
            }
        }
    }

    SettingsCardSection {
        expanded: false
        icon: "screenshot_frame_2"
        title: Translation.tr("Region selector (screen snipping/Google Lens)")

        SettingsGroup {
            ContentSubsection {
                title: Translation.tr("Hint target regions")
                ConfigRow {
                    uniform: true
                    SettingsSwitch {
                        buttonIcon: "select_window"
                        text: Translation.tr('Windows')
                        checked: Config.options.regionSelector.targetRegions.windows
                        onCheckedChanged: {
                            Config.options.regionSelector.targetRegions.windows = checked;
                        }
                        StyledToolTip {
                            text: Translation.tr("Highlight open windows as selectable regions")
                        }
                    }
                    SettingsSwitch {
                        buttonIcon: "right_panel_open"
                        text: Translation.tr('Layers')
                        checked: Config.options.regionSelector.targetRegions.layers
                        onCheckedChanged: {
                            Config.options.regionSelector.targetRegions.layers = checked;
                        }
                        StyledToolTip {
                            text: Translation.tr("Highlight UI layers as selectable regions")
                        }
                    }
                    SettingsSwitch {
                        buttonIcon: "nearby"
                        text: Translation.tr('Content')
                        checked: Config.options.regionSelector.targetRegions.content
                        onCheckedChanged: {
                            Config.options.regionSelector.targetRegions.content = checked;
                        }
                        StyledToolTip {
                            text: Translation.tr("Could be images or parts of the screen that have some containment.\nMight not always be accurate.\nThis is done with an image processing algorithm run locally and no AI is used.")
                        }
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Google Lens")

                ConfigSelectionArray {
                    currentValue: Config.options.search.imageSearch.useCircleSelection ? "circle" : "rectangles"
                    onSelected: newValue => {
                        Config.options.search.imageSearch.useCircleSelection = (newValue === "circle");
                    }
                    options: [
                        { icon: "activity_zone", value: "rectangles", displayName: Translation.tr("Rectangular selection") },
                        { icon: "gesture", value: "circle", displayName: Translation.tr("Circle to Search") }
                    ]
                }
            }

            ContentSubsection {
                title: Translation.tr("Element appearance")

                ConfigSpinBox {
                    icon: "border_style"
                    text: Translation.tr("Border size (px)")
                    value: Config.options.regionSelector.borderSize
                    from: 1
                    to: 10
                    stepSize: 1
                    onValueChanged: {
                        Config.setNestedValue("regionSelector.borderSize", value);
                    }
                    StyledToolTip {
                        text: Translation.tr("Thickness of the selection region border")
                    }
                }
                ConfigSpinBox {
                    icon: "format_size"
                    text: Translation.tr("Numbers size (px)")
                    value: Config.options.regionSelector.numSize
                    from: 10
                    to: 100
                    stepSize: 2
                    onValueChanged: {
                        Config.setNestedValue("regionSelector.numSize", value);
                    }
                    StyledToolTip {
                        text: Translation.tr("Font size of the region index numbers")
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Rectangular selection")

                SettingsSwitch {
                    buttonIcon: "point_scan"
                    text: Translation.tr("Show aim lines")
                    checked: Config.options.regionSelector.rect.showAimLines
                    onCheckedChanged: {
                        Config.options.regionSelector.rect.showAimLines = checked;
                    }
                    StyledToolTip {
                        text: Translation.tr("Show crosshair lines when selecting a region")
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Circle selection")

                ConfigSpinBox {
                    icon: "eraser_size_3"
                    text: Translation.tr("Stroke width")
                    value: Config.options.regionSelector.circle.strokeWidth
                    from: 1
                    to: 20
                    stepSize: 1
                    onValueChanged: {
                        Config.options.regionSelector.circle.strokeWidth = value;
                    }
                    StyledToolTip {
                        text: Translation.tr("Thickness of the circle selection stroke")
                    }
                }

                ConfigSpinBox {
                    icon: "screenshot_frame_2"
                    text: Translation.tr("Padding")
                    value: Config.options.regionSelector.circle.padding
                    from: 0
                    to: 100
                    stepSize: 5
                    onValueChanged: {
                        Config.options.regionSelector.circle.padding = value;
                    }
                    StyledToolTip {
                        text: Translation.tr("Padding around the selected circle region")
                    }
                }
            }
        }
    }

}
