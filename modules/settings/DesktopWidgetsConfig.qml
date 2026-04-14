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
    settingsPageIndex: 5
    settingsPageName: Translation.tr("Desktop Widgets")
    settingsPageIcon: "widgets"

    property bool isIiActive: Config.options?.panelFamily !== "waffle"

    SettingsCardSection {
        visible: root.isIiActive
        expanded: false
        icon: "schedule"
        title: Translation.tr("Widget: Clock")

        SettingsGroup {
            ConfigRow {
                Layout.fillWidth: true

                SettingsSwitch {
                    Layout.fillWidth: false
                    buttonIcon: "check"
                    text: Translation.tr("Enable")
                    checked: Config.options.background.widgets.clock.enable
                    onCheckedChanged: {
                        Config.setNestedValue("background.widgets.clock.enable", checked);
                    }
                    StyledToolTip {
                        text: Translation.tr("Show the desktop clock widget")
                    }
                }
                Item {
                    Layout.fillWidth: true
                }
                ConfigSelectionArray {
                    Layout.fillWidth: false
                    currentValue: Config.options.background.widgets.clock.placementStrategy
                    onSelected: newValue => {
                        Config.setNestedValue("background.widgets.clock.placementStrategy", newValue);
                    }
                    options: [
                        {
                            displayName: Translation.tr("Draggable"),
                            icon: "drag_pan",
                            value: "free"
                        },
                        {
                            displayName: Translation.tr("Least busy"),
                            icon: "category",
                            value: "leastBusy"
                        },
                        {
                            displayName: Translation.tr("Most busy"),
                            icon: "shapes",
                            value: "mostBusy"
                        },
                    ]
                }
            }

            ContentSubsection {
                title: Translation.tr("Clock style")
                ConfigSelectionArray {
                    currentValue: Config.options.background.widgets.clock.style
                    onSelected: newValue => {
                        Config.setNestedValue("background.widgets.clock.style", newValue);
                    }
                    options: [
                        {
                            displayName: Translation.tr("Digital"),
                            icon: "timer",
                            value: "digital"
                        },
                        {
                            displayName: Translation.tr("Cookie"),
                            icon: "cookie",
                            value: "cookie"
                        }
                    ]
                }
            }

            ContentSubsection {
                visible: Config.options.background.widgets.clock.style === "digital"
                title: Translation.tr("Digital clock settings")

                SettingsSwitch {
                    buttonIcon: "animation"
                    text: Translation.tr("Animate time change")
                    checked: Config.options.background.widgets.clock.digital.animateChange
                    onCheckedChanged: {
                        Config.setNestedValue("background.widgets.clock.digital.animateChange", checked);
                    }
                    StyledToolTip {
                        text: Translation.tr("Smoothly animate digits when time changes")
                    }
                }

                ContentSubsection {
                    title: Translation.tr("Time format")
                    ConfigSelectionArray {
                        currentValue: Config.options?.background?.widgets?.clock?.timeFormat ?? "system"
                        onSelected: newValue => {
                            Config.setNestedValue("background.widgets.clock.timeFormat", newValue);
                        }
                        options: [
                            {
                                displayName: Translation.tr("System"),
                                icon: "settings",
                                value: "system"
                            },
                            {
                                displayName: Translation.tr("24h"),
                                icon: "schedule",
                                value: "24h"
                            },
                            {
                                displayName: Translation.tr("12h"),
                                icon: "nest_clock_farsight_analog",
                                value: "12h"
                            }
                        ]
                    }
                }

                SettingsSwitch {
                    buttonIcon: "timer"
                    text: Translation.tr("Show seconds")
                    checked: Config.options?.background?.widgets?.clock?.showSeconds ?? false
                    onCheckedChanged: {
                        Config.setNestedValue("background.widgets.clock.showSeconds", checked);
                    }
                    StyledToolTip {
                        text: Translation.tr("Display seconds in the time string")
                    }
                }

                SettingsSwitch {
                    buttonIcon: "calendar_today"
                    text: Translation.tr("Show date")
                    checked: Config.options?.background?.widgets?.clock?.showDate ?? true
                    onCheckedChanged: {
                        Config.setNestedValue("background.widgets.clock.showDate", checked);
                    }
                    StyledToolTip {
                        text: Translation.tr("Show a date line below the time")
                    }
                }

                ContentSubsection {
                    visible: Config.options?.background?.widgets?.clock?.showDate ?? true
                    title: Translation.tr("Date style")
                    ConfigSelectionArray {
                        currentValue: Config.options?.background?.widgets?.clock?.dateStyle ?? "long"
                        onSelected: newValue => {
                            Config.setNestedValue("background.widgets.clock.dateStyle", newValue);
                        }
                        options: [
                            {
                                displayName: Translation.tr("Long"),
                                icon: "calendar_month",
                                value: "long"
                            },
                            {
                                displayName: Translation.tr("Minimal"),
                                icon: "event_note",
                                value: "minimal"
                            },
                            {
                                displayName: Translation.tr("Weekday"),
                                icon: "today",
                                value: "weekday"
                            },
                            {
                                displayName: Translation.tr("Numeric"),
                                icon: "123",
                                value: "numeric"
                            }
                        ]
                    }
                }

                ConfigSpinBox {
                    icon: "format_size"
                    text: Translation.tr("Time scale (%)")
                    value: Config.options?.background?.widgets?.clock?.timeScale ?? 100
                    from: 50
                    to: 200
                    stepSize: 5
                    onValueChanged: {
                        Config.setNestedValue("background.widgets.clock.timeScale", value);
                    }
                    StyledToolTip {
                        text: Translation.tr("Scale the time text size")
                    }
                }

                ConfigSpinBox {
                    icon: "format_size"
                    text: Translation.tr("Date scale (%)")
                    value: Config.options?.background?.widgets?.clock?.dateScale ?? 100
                    from: 50
                    to: 200
                    stepSize: 5
                    onValueChanged: {
                        Config.setNestedValue("background.widgets.clock.dateScale", value);
                    }
                    StyledToolTip {
                        text: Translation.tr("Scale the date text size")
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Clock effects")

                ConfigSpinBox {
                    icon: "brightness_6"
                    text: Translation.tr("Clock dim (%)")
                    value: Config.options.background.widgets.clock.dim
                    from: 0
                    to: 100
                    stepSize: 5
                    onValueChanged: {
                        Config.setNestedValue("background.widgets.clock.dim", value);
                    }
                    StyledToolTip {
                        text: Translation.tr("Only affects the clock widget text, independent from the global wallpaper dim.")
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Clock appearance")

                FontSelector {
                    id: clockFontSelector
                    label: Translation.tr("Clock font")
                    icon: "font_download"
                    selectedFont: Config.options?.background?.widgets?.clock?.fontFamily ?? "Space Grotesk"
                    onSelectedFontChanged: {
                        if (Config.options?.background?.widgets?.clock)
                            Config.setNestedValue("background.widgets.clock.fontFamily", selectedFont);
                    }
                    Connections {
                        target: Config.options?.background?.widgets?.clock ?? null
                        function onFontFamilyChanged() { clockFontSelector.selectedFont = Config.options.background.widgets.clock.fontFamily }
                    }
                }

                SettingsSwitch {
                    buttonIcon: "shadow"
                    text: Translation.tr("Show text shadow")
                    checked: Config.options?.background?.widgets?.clock?.showShadow ?? true
                    onCheckedChanged: {
                        Config.setNestedValue("background.widgets.clock.showShadow", checked);
                    }
                    StyledToolTip {
                        text: Translation.tr("Draw a subtle shadow behind clock text for better readability")
                    }
                }
            }

            ContentSubsection {
                visible: Config.options.background.widgets.clock.style === "cookie"
                title: Translation.tr("Cookie clock settings")

                SettingsSwitch {
                    buttonIcon: "wand_stars"
                    text: Translation.tr("Auto styling with Gemini")
                    checked: Config.options.background.widgets.clock.cookie.aiStyling
                    onCheckedChanged: {
                        Config.setNestedValue("background.widgets.clock.cookie.aiStyling", checked);
                    }
                    StyledToolTip {
                        text: Translation.tr("Uses Gemini to categorize the wallpaper then picks a preset based on it.\nYou'll need to set Gemini API key on the left sidebar first.\nImages are downscaled for performance, but just to be safe,\ndo not select wallpapers with sensitive information.")
                    }
                }

                SettingsSwitch {
                    buttonIcon: "airwave"
                    text: Translation.tr("Use old sine wave cookie implementation")
                    checked: Config.options.background.widgets.clock.cookie.useSineCookie
                    onCheckedChanged: {
                        Config.setNestedValue("background.widgets.clock.cookie.useSineCookie", checked);
                    }
                    StyledToolTip {
                        text: "Looks a bit softer and more consistent with different number of sides,\nbut has less impressive morphing"
                    }
                }

                ConfigSpinBox {
                    icon: "add_triangle"
                    text: Translation.tr("Sides")
                    value: Config.options.background.widgets.clock.cookie.sides
                    from: 0
                    to: 40
                    stepSize: 1
                    onValueChanged: {
                        Config.setNestedValue("background.widgets.clock.cookie.sides", value);
                    }
                    StyledToolTip {
                        text: Translation.tr("Number of sides for the polygon shape")
                    }
                }

                SettingsSwitch {
                    buttonIcon: "autoplay"
                    text: Translation.tr("Constantly rotate")
                    checked: Config.options.background.widgets.clock.cookie.constantlyRotate
                    onCheckedChanged: {
                        Config.setNestedValue("background.widgets.clock.cookie.constantlyRotate", checked);
                    }
                    StyledToolTip {
                        text: "Makes the clock always rotate. This is extremely expensive\n(expect 50% usage on Intel UHD Graphics) and thus impractical."
                    }
                }

                ConfigRow {

                    SettingsSwitch {
                        enabled: Config.options.background.widgets.clock.style === "cookie" && Config.options.background.widgets.clock.cookie.dialNumberStyle === "dots" || Config.options.background.widgets.clock.cookie.dialNumberStyle === "full"
                        buttonIcon: "brightness_7"
                        text: Translation.tr("Hour marks")
                        checked: Config.options.background.widgets.clock.cookie.hourMarks
                        onEnabledChanged: {
                            checked = Config.options.background.widgets.clock.cookie.hourMarks;
                        }
                        onCheckedChanged: {
                            Config.setNestedValue("background.widgets.clock.cookie.hourMarks", checked);
                        }
                        StyledToolTip {
                            text: "Can only be turned on using the 'Dots' or 'Full' dial style for aesthetic reasons"
                        }
                    }

                    SettingsSwitch {
                        enabled: Config.options.background.widgets.clock.style === "cookie" && Config.options.background.widgets.clock.cookie.dialNumberStyle !== "numbers"
                        buttonIcon: "123"
                        text: Translation.tr("Digits in the middle")
                        checked: Config.options.background.widgets.clock.cookie.timeIndicators
                        onEnabledChanged: {
                            checked = Config.options.background.widgets.clock.cookie.timeIndicators;
                        }
                        onCheckedChanged: {
                            Config.setNestedValue("background.widgets.clock.cookie.timeIndicators", checked);
                        }
                        StyledToolTip {
                            text: "Can't be turned on when using 'Numbers' dial style for aesthetic reasons"
                        }
                    }
                }
            }

            ContentSubsection {
                visible: Config.options.background.widgets.clock.style === "cookie"
                title: Translation.tr("Dial style")
                ConfigSelectionArray {
                    currentValue: Config.options.background.widgets.clock.cookie.dialNumberStyle
                    onSelected: newValue => {
                        Config.setNestedValue("background.widgets.clock.cookie.dialNumberStyle", newValue);
                        if (newValue !== "dots" && newValue !== "full") {
                            Config.setNestedValue("background.widgets.clock.cookie.hourMarks", false);
                        }
                        if (newValue === "numbers") {
                            Config.setNestedValue("background.widgets.clock.cookie.timeIndicators", false);
                        }
                    }
                    options: [
                        {
                            displayName: "",
                            icon: "block",
                            value: "none"
                        },
                        {
                            displayName: Translation.tr("Dots"),
                            icon: "graph_6",
                            value: "dots"
                        },
                        {
                            displayName: Translation.tr("Full"),
                            icon: "history_toggle_off",
                            value: "full"
                        },
                        {
                            displayName: Translation.tr("Numbers"),
                            icon: "counter_1",
                            value: "numbers"
                        }
                    ]
                }
            }

            ContentSubsection {
                visible: Config.options.background.widgets.clock.style === "cookie"
                title: Translation.tr("Hour hand")
                ConfigSelectionArray {
                    currentValue: Config.options.background.widgets.clock.cookie.hourHandStyle
                    onSelected: newValue => {
                        Config.setNestedValue("background.widgets.clock.cookie.hourHandStyle", newValue);
                    }
                    options: [
                        {
                            displayName: "",
                            icon: "block",
                            value: "hide"
                        },
                        {
                            displayName: Translation.tr("Classic"),
                            icon: "radio",
                            value: "classic"
                        },
                        {
                            displayName: Translation.tr("Hollow"),
                            icon: "circle",
                            value: "hollow"
                        },
                        {
                            displayName: Translation.tr("Fill"),
                            icon: "eraser_size_5",
                            value: "fill"
                        },
                    ]
                }
            }

            ContentSubsection {
                visible: Config.options.background.widgets.clock.style === "cookie"
                title: Translation.tr("Minute hand")

                ConfigSelectionArray {
                    currentValue: Config.options.background.widgets.clock.cookie.minuteHandStyle
                    onSelected: newValue => {
                        Config.setNestedValue("background.widgets.clock.cookie.minuteHandStyle", newValue);
                    }
                    options: [
                        {
                            displayName: "",
                            icon: "block",
                            value: "hide"
                        },
                        {
                            displayName: Translation.tr("Classic"),
                            icon: "radio",
                            value: "classic"
                        },
                        {
                            displayName: Translation.tr("Thin"),
                            icon: "line_end",
                            value: "thin"
                        },
                        {
                            displayName: Translation.tr("Medium"),
                            icon: "eraser_size_2",
                            value: "medium"
                        },
                        {
                            displayName: Translation.tr("Bold"),
                            icon: "eraser_size_4",
                            value: "bold"
                        },
                    ]
                }
            }

            ContentSubsection {
                visible: Config.options.background.widgets.clock.style === "cookie"
                title: Translation.tr("Second hand")

                ConfigSelectionArray {
                    currentValue: Config.options.background.widgets.clock.cookie.secondHandStyle
                    onSelected: newValue => {
                        Config.setNestedValue("background.widgets.clock.cookie.secondHandStyle", newValue);
                    }
                    options: [
                        {
                            displayName: "",
                            icon: "block",
                            value: "hide"
                        },
                        {
                            displayName: Translation.tr("Classic"),
                            icon: "radio",
                            value: "classic"
                        },
                        {
                            displayName: Translation.tr("Line"),
                            icon: "line_end",
                            value: "line"
                        },
                        {
                            displayName: Translation.tr("Dot"),
                            icon: "adjust",
                            value: "dot"
                        },
                    ]
                }
            }

            ContentSubsection {
                visible: Config.options.background.widgets.clock.style === "cookie"
                title: Translation.tr("Date style")

                ConfigSelectionArray {
                    currentValue: Config.options.background.widgets.clock.cookie.dateStyle
                    onSelected: newValue => {
                        Config.setNestedValue("background.widgets.clock.cookie.dateStyle", newValue);
                    }
                    options: [
                        {
                            displayName: "",
                            icon: "block",
                            value: "hide"
                        },
                        {
                            displayName: Translation.tr("Bubble"),
                            icon: "bubble_chart",
                            value: "bubble"
                        },
                        {
                            displayName: Translation.tr("Border"),
                            icon: "rotate_right",
                            value: "border"
                        },
                        {
                            displayName: Translation.tr("Rect"),
                            icon: "rectangle",
                            value: "rect"
                        }
                    ]
                }
            }

            ContentSubsection {
                title: Translation.tr("Quote")

                SettingsSwitch {
                    buttonIcon: "check"
                    text: Translation.tr("Enable")
                    checked: Config.options.background.widgets.clock.quote.enable
                    onCheckedChanged: {
                        Config.setNestedValue("background.widgets.clock.quote.enable", checked);
                    }
                    StyledToolTip {
                        text: Translation.tr("Show a quote text widget below the clock")
                    }
                }
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Quote")
                    text: Config.options.background.widgets.clock.quote.text
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.setNestedValue("background.widgets.clock.quote.text", text);
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Reset")

                RippleButton {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    buttonRadius: Appearance.rounding.small
                    colBackground: Appearance.colors.colLayer2
                    colBackgroundHover: Appearance.colors.colLayer2Hover
                    onClicked: {
                        Config.setNestedValue("background.widgets.clock.fontFamily", "Space Grotesk");
                        Config.setNestedValue("background.widgets.clock.timeFormat", "system");
                        Config.setNestedValue("background.widgets.clock.showSeconds", false);
                        Config.setNestedValue("background.widgets.clock.showDate", true);
                        Config.setNestedValue("background.widgets.clock.dateStyle", "long");
                        Config.setNestedValue("background.widgets.clock.timeScale", 100);
                        Config.setNestedValue("background.widgets.clock.dateScale", 100);
                        Config.setNestedValue("background.widgets.clock.showShadow", true);
                        Config.setNestedValue("background.widgets.clock.dim", 70);
                        Config.setNestedValue("background.widgets.clock.digital.animateChange", true);
                    }
                    contentItem: RowLayout {
                        spacing: 6
                        Item { Layout.fillWidth: true }
                        MaterialSymbol {
                            text: "restart_alt"
                            iconSize: 15
                            color: Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            text: Translation.tr("Reset clock settings to defaults")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnLayer1
                        }
                        Item { Layout.fillWidth: true }
                    }
                }
            }
        }
    }

    SettingsCardSection {
        visible: root.isIiActive
        expanded: true
        icon: "cloud"
        title: Translation.tr("Widget: Weather")

        SettingsGroup {
            StyledText {
                Layout.fillWidth: true
                visible: !(Config.options?.bar?.weather?.enable ?? false)
                text: Translation.tr("Enable weather service first in Services → Weather")
                color: Appearance.colors.colTertiary
                font.pixelSize: Appearance.font.pixelSize.small
                wrapMode: Text.WordWrap
            }

            ConfigRow {
                Layout.fillWidth: true
                enabled: Config.options?.bar?.weather?.enable ?? false

                SettingsSwitch {
                    Layout.fillWidth: false
                    buttonIcon: "check"
                    text: Translation.tr("Enable")
                    checked: Config.options.background.widgets.weather.enable
                    onCheckedChanged: {
                        Config.setNestedValue("background.widgets.weather.enable", checked);
                    }
                    StyledToolTip {
                        text: Translation.tr("Show the desktop weather widget")
                    }
                }
                Item {
                    Layout.fillWidth: true
                }
                ConfigSelectionArray {
                    Layout.fillWidth: false
                    currentValue: Config.options.background.widgets.weather.placementStrategy
                    onSelected: newValue => {
                        Config.setNestedValue("background.widgets.weather.placementStrategy", newValue);
                    }
                    options: [
                        {
                            displayName: Translation.tr("Draggable"),
                            icon: "drag_pan",
                            value: "free"
                        },
                        {
                            displayName: Translation.tr("Least busy"),
                            icon: "category",
                            value: "leastBusy"
                        },
                        {
                            displayName: Translation.tr("Most busy"),
                            icon: "shapes",
                            value: "mostBusy"
                        },
                    ]
                }
            }
        }
    }

    SettingsCardSection {
        visible: root.isIiActive
        expanded: true
        icon: "album"
        title: Translation.tr("Widget: Media Controls")

        SettingsGroup {
            ConfigRow {
                Layout.fillWidth: true

                SettingsSwitch {
                    Layout.fillWidth: false
                    buttonIcon: "check"
                    text: Translation.tr("Enable")
                    checked: Config.options.background.widgets.mediaControls.enable
                    onCheckedChanged: {
                        Config.setNestedValue("background.widgets.mediaControls.enable", checked);
                    }
                }
                Item {
                    Layout.fillWidth: true
                }
                ConfigSelectionArray {
                    Layout.fillWidth: false
                    currentValue: Config.options.background.widgets.mediaControls.placementStrategy
                    onSelected: newValue => {
                        Config.setNestedValue("background.widgets.mediaControls.placementStrategy", newValue);
                    }
                    options: [
                        {
                            displayName: Translation.tr("Draggable"),
                            icon: "drag_pan",
                            value: "free"
                        },
                        {
                            displayName: Translation.tr("Least busy"),
                            icon: "category",
                            value: "leastBusy"
                        },
                        {
                            displayName: Translation.tr("Most busy"),
                            icon: "shapes",
                            value: "mostBusy"
                        },
                    ]
                }
            }
            
            ContentSubsectionLabel {
                text: Translation.tr("Player Style")
            }
            
            ConfigRow {
                Layout.fillWidth: true
                
                ConfigSelectionArray {
                    Layout.fillWidth: true
                    currentValue: Config.options.background.widgets.mediaControls.playerPreset
                    onSelected: newValue => {
                        Config.setNestedValue("background.widgets.mediaControls.playerPreset", newValue);
                    }
                    options: [
                        {
                            displayName: Translation.tr("Full"),
                            icon: "featured_video",
                            value: "full"
                        },
                        {
                            displayName: Translation.tr("Compact"),
                            icon: "view_compact",
                            value: "compact"
                        },
                        {
                            displayName: Translation.tr("Album Art"),
                            icon: "image",
                            value: "albumart"
                        },
                        {
                            displayName: Translation.tr("Classic"),
                            icon: "radio",
                            value: "classic"
                        }
                    ]
                }
            }
        }
    }

    SettingsCardSection {
        visible: root.isIiActive
        expanded: true
        icon: "monitor_heart"
        title: Translation.tr("Widget: System Monitor")

        SettingsGroup {
            // Enable + Placement
            ConfigRow {
                Layout.fillWidth: true

                SettingsSwitch {
                    Layout.fillWidth: false
                    buttonIcon: "check"
                    text: Translation.tr("Enable")
                    checked: Config.options.background.widgets.systemMonitor.enable
                    onCheckedChanged: {
                        Config.options.background.widgets.systemMonitor.enable = checked;
                    }
                }
                Item {
                    Layout.fillWidth: true
                }
                ConfigSelectionArray {
                    Layout.fillWidth: false
                    currentValue: Config.options.background.widgets.systemMonitor.placementStrategy
                    onSelected: newValue => {
                        Config.options.background.widgets.systemMonitor.placementStrategy = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Draggable"),
                            icon: "drag_pan",
                            value: "free"
                        },
                        {
                            displayName: Translation.tr("Least busy"),
                            icon: "category",
                            value: "leastBusy"
                        },
                        {
                            displayName: Translation.tr("Most busy"),
                            icon: "shapes",
                            value: "mostBusy"
                        },
                    ]
                }
            }

            // Appearance
            ContentSubsection {
                title: Translation.tr("Appearance")

                ConfigSpinBox {
                    icon: "opacity"
                    text: Translation.tr("Card opacity (%)")
                    value: Math.round((Config.options.background.widgets.systemMonitor.cardOpacity ?? 0.85) * 100)
                    from: 20
                    to: 100
                    stepSize: 5
                    onValueChanged: {
                        Config.options.background.widgets.systemMonitor.cardOpacity = value / 100;
                    }
                    StyledToolTip {
                        text: Translation.tr("Transparency of the card background")
                    }
                }

                ConfigSpinBox {
                    icon: "width"
                    text: Translation.tr("Card width (px)")
                    value: Config.options.background.widgets.systemMonitor.cardWidth ?? 380
                    from: 300
                    to: 600
                    stepSize: 10
                    onValueChanged: {
                        Config.options.background.widgets.systemMonitor.cardWidth = value;
                    }
                    StyledToolTip {
                        text: Translation.tr("Width of the widget card. Can also be resized by dragging the bottom-right corner")
                    }
                }
            }

            // Sections visibility
            ContentSubsection {
                title: Translation.tr("Sections")

                SettingsSwitch {
                    buttonIcon: "person"
                    text: Translation.tr("Profile")
                    checked: Config.options.background.widgets.systemMonitor.showProfile ?? true
                    onCheckedChanged: {
                        Config.options.background.widgets.systemMonitor.showProfile = checked;
                    }
                    StyledToolTip {
                        text: Translation.tr("Avatar, greeting, uptime, distro info, kernel, WM, and package count")
                    }
                }

                SettingsSwitch {
                    buttonIcon: "calendar_month"
                    text: Translation.tr("Calendar & Clock")
                    checked: Config.options.background.widgets.systemMonitor.showCalendar ?? true
                    onCheckedChanged: {
                        Config.options.background.widgets.systemMonitor.showCalendar = checked;
                    }
                    StyledToolTip {
                        text: Translation.tr("Digital clock, day name, date, month grid with highlighted today")
                    }
                }

                SettingsSwitch {
                    buttonIcon: "event"
                    text: Translation.tr("Calendar Events")
                    checked: Config.options.background.widgets.systemMonitor.showEvents ?? true
                    onCheckedChanged: {
                        Config.options.background.widgets.systemMonitor.showEvents = checked;
                    }
                    StyledToolTip {
                        text: Translation.tr("Today's events from Google Calendar (requires gcalcli)")
                    }
                }

                SettingsSwitch {
                    buttonIcon: "cloud"
                    text: Translation.tr("Weather")
                    checked: Config.options.background.widgets.systemMonitor.showWeather ?? true
                    onCheckedChanged: {
                        Config.options.background.widgets.systemMonitor.showWeather = checked;
                    }
                    StyledToolTip {
                        text: Translation.tr("Temperature, conditions, and weather details")
                    }
                }

                SettingsSwitch {
                    buttonIcon: "speed"
                    text: Translation.tr("System Rings")
                    checked: Config.options.background.widgets.systemMonitor.showSystem ?? true
                    onCheckedChanged: {
                        Config.options.background.widgets.systemMonitor.showSystem = checked;
                    }
                    StyledToolTip {
                        text: Translation.tr("CPU, RAM, and GPU usage rings")
                    }
                }

                SettingsSwitch {
                    buttonIcon: "storage"
                    text: Translation.tr("Storage")
                    checked: Config.options.background.widgets.systemMonitor.showStorage ?? true
                    onCheckedChanged: {
                        Config.options.background.widgets.systemMonitor.showStorage = checked;
                    }
                    StyledToolTip {
                        text: Translation.tr("Disk usage bars for NVMe and HDD")
                    }
                }

                SettingsSwitch {
                    buttonIcon: "memory"
                    text: Translation.tr("GPU Ring")
                    checked: Config.options.background.widgets.systemMonitor.showGpu ?? true
                    enabled: Config.options.background.widgets.systemMonitor.showSystem ?? true
                    onCheckedChanged: {
                        Config.options.background.widgets.systemMonitor.showGpu = checked;
                    }
                    StyledToolTip {
                        text: Translation.tr("Show GPU usage ring alongside CPU and RAM")
                    }
                }

                SettingsSwitch {
                    buttonIcon: "music_note"
                    text: Translation.tr("Media Player")
                    checked: Config.options.background.widgets.systemMonitor.showMedia ?? true
                    onCheckedChanged: {
                        Config.options.background.widgets.systemMonitor.showMedia = checked;
                    }
                    StyledToolTip {
                        text: Translation.tr("Album art with cava visualizer, playback controls, and MPRIS player switcher")
                    }
                }

                SettingsSwitch {
                    buttonIcon: "rocket_launch"
                    text: Translation.tr("Quick Launch")
                    checked: Config.options.background.widgets.systemMonitor.showQuickLaunch ?? true
                    onCheckedChanged: {
                        Config.options.background.widgets.systemMonitor.showQuickLaunch = checked;
                    }
                    StyledToolTip {
                        text: Translation.tr("Quick application launcher icons")
                    }
                }

                SettingsSwitch {
                    buttonIcon: "lan"
                    text: Translation.tr("Network")
                    checked: Config.options.background.widgets.systemMonitor.showNetwork ?? true
                    onCheckedChanged: {
                        Config.options.background.widgets.systemMonitor.showNetwork = checked;
                    }
                    StyledToolTip {
                        text: Translation.tr("Connection type, name, IP address, and real-time upload/download speed")
                    }
                }
            }
        }
    }

    SettingsCardSection {
        visible: root.isIiActive
        expanded: true
        icon: "graphic_eq"
        title: Translation.tr("Widget: Audio Visualizer")

        SettingsGroup {
            // Enable
            SettingsSwitch {
                buttonIcon: "check"
                text: Translation.tr("Enable")
                checked: Config.options.background.widgets.audioVisualizer.enable
                onCheckedChanged: {
                    Config.options.background.widgets.audioVisualizer.enable = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Full-screen audio visualizer on the desktop background (requires cava)")
                }
            }

            // Style
            ConfigSelectionArray {
                currentValue: Config.options.background.widgets.audioVisualizer.style ?? "bars"
                onSelected: newValue => {
                    Config.options.background.widgets.audioVisualizer.style = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("Bars"),
                        icon: "bar_chart",
                        value: "bars"
                    },
                    {
                        displayName: Translation.tr("Wave"),
                        icon: "waves",
                        value: "wave"
                    },
                ]
            }

            // Appearance
            ContentSubsection {
                title: Translation.tr("Appearance")

                ConfigSpinBox {
                    icon: "opacity"
                    text: Translation.tr("Opacity (%)")
                    value: Math.round((Config.options.background.widgets.audioVisualizer.opacity ?? 0.45) * 100)
                    from: 10
                    to: 100
                    stepSize: 5
                    onValueChanged: {
                        Config.options.background.widgets.audioVisualizer.opacity = value / 100;
                    }
                }

                ConfigSpinBox {
                    icon: "height"
                    text: Translation.tr("Height (px)")
                    value: Config.options.background.widgets.audioVisualizer.height ?? 200
                    from: 50
                    to: 600
                    stepSize: 25
                    onValueChanged: {
                        Config.options.background.widgets.audioVisualizer.height = value;
                    }
                }

                ConfigSpinBox {
                    icon: "view_column"
                    text: Translation.tr("Bar count")
                    value: Config.options.background.widgets.audioVisualizer.barCount ?? 80
                    from: 20
                    to: 200
                    stepSize: 10
                    onValueChanged: {
                        Config.options.background.widgets.audioVisualizer.barCount = value;
                    }
                    StyledToolTip {
                        text: Translation.tr("Number of bars (bars style only)")
                    }
                }

                ConfigSpinBox {
                    icon: "space_bar"
                    text: Translation.tr("Bar spacing (px)")
                    value: Config.options.background.widgets.audioVisualizer.barSpacing ?? 3
                    from: 0
                    to: 10
                    stepSize: 1
                    onValueChanged: {
                        Config.options.background.widgets.audioVisualizer.barSpacing = value;
                    }
                    StyledToolTip {
                        text: Translation.tr("Gap between bars (bars style only)")
                    }
                }

                ConfigSpinBox {
                    icon: "rounded_corner"
                    text: Translation.tr("Bar radius (px)")
                    value: Config.options.background.widgets.audioVisualizer.barRadius ?? 2
                    from: 0
                    to: 10
                    stepSize: 1
                    onValueChanged: {
                        Config.options.background.widgets.audioVisualizer.barRadius = value;
                    }
                    StyledToolTip {
                        text: Translation.tr("Corner radius of bars (bars style only)")
                    }
                }
            }

            // Color
            ContentSubsection {
                title: Translation.tr("Color")

                ConfigSelectionArray {
                    currentValue: Config.options.background.widgets.audioVisualizer.colorSource ?? "primary"
                    onSelected: newValue => {
                        Config.options.background.widgets.audioVisualizer.colorSource = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Primary"),
                            icon: "palette",
                            value: "primary"
                        },
                        {
                            displayName: Translation.tr("Secondary"),
                            icon: "palette",
                            value: "secondary"
                        },
                        {
                            displayName: Translation.tr("Tertiary"),
                            icon: "palette",
                            value: "tertiary"
                        },
                        {
                            displayName: Translation.tr("Container"),
                            icon: "palette",
                            value: "primaryContainer"
                        },
                    ]
                }
            }

            // Behavior
            SettingsSwitch {
                buttonIcon: "visibility_off"
                text: Translation.tr("Auto-hide when silent")
                checked: Config.options.background.widgets.audioVisualizer.autoHide ?? true
                onCheckedChanged: {
                    Config.options.background.widgets.audioVisualizer.autoHide = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Hide the visualizer when no audio is playing")
                }
            }
        }
    }

    SettingsCardSection {
        expanded: true
        icon: "notifications"
        title: Translation.tr("Notifications")

        SettingsGroup {
            SettingsSwitch {
                buttonIcon: "hide_image"
                text: Translation.tr("Hide wallpaper upscale notification")
                checked: Config.options?.background?.hideUpscaleNotification ?? false
                onCheckedChanged: Config.setNestedValue("background.hideUpscaleNotification", checked)
                StyledToolTip {
                    text: Translation.tr("Suppress the notification that appears when a wallpaper has lower resolution than your monitor")
                }
            }
        }
    }
}
