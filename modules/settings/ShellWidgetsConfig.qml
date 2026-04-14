import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: root
    settingsPageIndex: 9
    settingsPageName: Translation.tr("Shell Widgets")
    settingsPageIcon: "widgets"

    property bool isIiActive: Config.options?.panelFamily !== "waffle"

    SettingsCardSection {
        visible: root.isIiActive
        expanded: false
        icon: "widgets"
        title: Translation.tr("Widgets")

        SettingsGroup {
            ContentSubsection {
                title: Translation.tr("Visibility")
                tooltip: Translation.tr("Toggle which widgets appear in the sidebar")

                SettingsSwitch {
                    buttonIcon: "music_note"
                    text: Translation.tr("Media player")
                    checked: Config.options?.sidebar?.widgets?.media ?? true
                    onCheckedChanged: Config.setNestedValue("sidebar.widgets.media", checked)
                }

                SettingsSwitch {
                    buttonIcon: "calendar_today"
                    text: Translation.tr("Week strip")
                    checked: Config.options?.sidebar?.widgets?.week ?? true
                    onCheckedChanged: Config.setNestedValue("sidebar.widgets.week", checked)
                }

                SettingsSwitch {
                    buttonIcon: "partly_cloudy_day"
                    text: Translation.tr("Context card (Weather/Timer)")
                    checked: Config.options?.sidebar?.widgets?.context ?? true
                    onCheckedChanged: Config.setNestedValue("sidebar.widgets.context", checked)
                }

                SettingsSwitch {
                    buttonIcon: "cloud"
                    text: Translation.tr("Show weather in context card")
                    checked: Config.options?.sidebar?.widgets?.contextShowWeather ?? true
                    onCheckedChanged: Config.setNestedValue("sidebar.widgets.contextShowWeather", checked)
                    enabled: Config.options?.sidebar?.widgets?.context ?? true
                }

                SettingsSwitch {
                    buttonIcon: "edit_note"
                    text: Translation.tr("Quick note")
                    checked: Config.options?.sidebar?.widgets?.note ?? true
                    onCheckedChanged: Config.setNestedValue("sidebar.widgets.note", checked)
                }

                SettingsSwitch {
                    buttonIcon: "apps"
                    text: Translation.tr("Quick launch")
                    checked: Config.options?.sidebar?.widgets?.launch ?? true
                    onCheckedChanged: Config.setNestedValue("sidebar.widgets.launch", checked)
                }

                // Quick launch apps editor
                ColumnLayout {
                    id: quickLaunchEditor
                    Layout.fillWidth: true
                    Layout.leftMargin: 16
                    Layout.topMargin: 2
                    spacing: 2
                    visible: Config.options?.sidebar?.widgets?.launch ?? true

                    property var shortcuts: Config.options?.sidebar?.widgets?.quickLaunch ?? [
                        { icon: "folder", name: "Files", cmd: "/usr/bin/nautilus" },
                        { icon: "terminal", name: "Terminal", cmd: "/usr/bin/kitty" },
                        { icon: "web", name: "Browser", cmd: "/usr/bin/firefox" },
                        { icon: "code", name: "Code", cmd: "/usr/bin/code" }
                    ]

                    property int pendingIndex: -1
                    property string pendingKey: ""
                    property string pendingValue: ""

                    Timer {
                        id: saveTimer
                        interval: 500
                        onTriggered: {
                            const idx = quickLaunchEditor.pendingIndex
                            const key = quickLaunchEditor.pendingKey
                            const val = quickLaunchEditor.pendingValue
                            if (idx >= 0 && idx < quickLaunchEditor.shortcuts.length) {
                                const newShortcuts = JSON.parse(JSON.stringify(quickLaunchEditor.shortcuts))
                                newShortcuts[idx][key] = val
                                Config.setNestedValue("sidebar.widgets.quickLaunch", newShortcuts)
                            }
                        }
                    }

                    function queueUpdate(index, key, value) {
                        pendingIndex = index
                        pendingKey = key
                        pendingValue = value
                        saveTimer.restart()
                    }

                    function removeShortcut(index) {
                        const newShortcuts = shortcuts.filter((_, i) => i !== index)
                        Config.setNestedValue("sidebar.widgets.quickLaunch", newShortcuts)
                    }

                    function addShortcut() {
                        const newShortcuts = [...shortcuts, { icon: "apps", name: "", cmd: "" }]
                        Config.setNestedValue("sidebar.widgets.quickLaunch", newShortcuts)
                    }

                    Repeater {
                        model: quickLaunchEditor.shortcuts.length

                        delegate: Item {
                            id: launchItem
                            required property int index
                            readonly property var itemData: quickLaunchEditor.shortcuts[index] ?? {}
                            Layout.fillWidth: true
                            implicitHeight: itemRow.implicitHeight + 8

                            Rectangle {
                                anchors.fill: parent
                                radius: Appearance.rounding.small
                                color: itemHover.containsMouse ? Appearance.colors.colLayer2Hover : "transparent"
                                Behavior on color {
                                    enabled: Appearance.animationsEnabled
                                    animation: ColorAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
                                }
                            }

                            MouseArea {
                                id: itemHover
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.NoButton
                            }

                            RowLayout {
                                id: itemRow
                                anchors {
                                    left: parent.left; right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: 8; rightMargin: 4
                                }
                                spacing: 8

                                // Icon preview
                                Rectangle {
                                    implicitWidth: 32; implicitHeight: 32
                                    radius: Appearance.rounding.small
                                    color: Appearance.colors.colSecondaryContainer
                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: launchItem.itemData.icon ?? "apps"
                                        iconSize: 18
                                        color: Appearance.colors.colOnSecondaryContainer
                                    }
                                }

                                // Icon name
                                ToolbarTextField {
                                    Layout.preferredWidth: 70
                                    implicitHeight: 30
                                    padding: 6
                                    text: launchItem.itemData.icon ?? ""
                                    placeholderText: Translation.tr("Icon")
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    selectByMouse: true
                                    onTextEdited: quickLaunchEditor.queueUpdate(launchItem.index, "icon", text)
                                }

                                // Display name
                                ToolbarTextField {
                                    Layout.preferredWidth: 100
                                    Layout.fillWidth: true
                                    Layout.maximumWidth: 140
                                    implicitHeight: 30
                                    padding: 6
                                    text: launchItem.itemData.name ?? ""
                                    placeholderText: Translation.tr("Name")
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    font.weight: Font.Medium
                                    selectByMouse: true
                                    onTextEdited: quickLaunchEditor.queueUpdate(launchItem.index, "name", text)
                                }

                                // Command
                                ToolbarTextField {
                                    Layout.fillWidth: true
                                    implicitHeight: 30
                                    padding: 6
                                    text: launchItem.itemData.cmd ?? ""
                                    placeholderText: Translation.tr("Command")
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    font.family: Appearance.font.family.monospace
                                    color: Appearance.colors.colSubtext
                                    selectByMouse: true
                                    onTextEdited: quickLaunchEditor.queueUpdate(launchItem.index, "cmd", text)
                                }

                                // Delete
                                RippleButton {
                                    implicitWidth: 24; implicitHeight: 24
                                    buttonRadius: Appearance.rounding.full
                                    colBackground: "transparent"
                                    colBackgroundHover: Appearance.colors.colErrorContainer
                                    colRipple: Appearance.colors.colError
                                    opacity: itemHover.containsMouse ? 1 : 0.3
                                    onClicked: quickLaunchEditor.removeShortcut(launchItem.index)

                                    Behavior on opacity {
                                        enabled: Appearance.animationsEnabled
                                        NumberAnimation { duration: 150 }
                                    }

                                    contentItem: MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "close"
                                        iconSize: 14
                                        color: Appearance.colors.colError
                                    }

                                    StyledToolTip { text: Translation.tr("Remove") }
                                }
                            }
                        }
                    }

                    // Add button
                    RippleButton {
                        Layout.fillWidth: true
                        implicitHeight: 34
                        buttonRadius: Appearance.rounding.small
                        colBackground: "transparent"
                        colBackgroundHover: Appearance.colors.colLayer2Hover
                        colRipple: Appearance.colors.colPrimaryContainer
                        onClicked: quickLaunchEditor.addShortcut()

                        contentItem: RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            MaterialSymbol {
                                text: "add"
                                iconSize: 18
                                color: Appearance.colors.colPrimary
                            }
                            StyledText {
                                text: Translation.tr("Add shortcut")
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colPrimary
                            }
                        }
                    }
                }

                SettingsSwitch {
                    buttonIcon: "toggle_on"
                    text: Translation.tr("Controls")
                    checked: Config.options?.sidebar?.widgets?.controls ?? true
                    onCheckedChanged: Config.setNestedValue("sidebar.widgets.controls", checked)
                }

                SettingsSwitch {
                    buttonIcon: "monitoring"
                    text: Translation.tr("System status")
                    checked: Config.options?.sidebar?.widgets?.status ?? true
                    onCheckedChanged: Config.setNestedValue("sidebar.widgets.status", checked)
                }

                SettingsSwitch {
                    buttonIcon: "currency_bitcoin"
                    text: Translation.tr("Crypto prices")
                    checked: Config.options?.sidebar?.widgets?.crypto ?? false
                    onCheckedChanged: Config.setNestedValue("sidebar.widgets.crypto", checked)
                }

                SettingsSwitch {
                    buttonIcon: "wallpaper"
                    text: Translation.tr("Wallpaper picker")
                    checked: Config.options?.sidebar?.widgets?.wallpaper ?? false
                    onCheckedChanged: Config.setNestedValue("sidebar.widgets.wallpaper", checked)
                }
            }

            ContentSubsection {
                title: Translation.tr("Layout")

                ConfigSpinBox {
                    icon: "format_line_spacing"
                    text: Translation.tr("Widget spacing")
                    value: Config.options?.sidebar?.widgets?.spacing ?? 8
                    from: 0
                    to: 24
                    stepSize: 2
                    onValueChanged: Config.setNestedValue("sidebar.widgets.spacing", value)
                    StyledToolTip {
                        text: Translation.tr("Space between widgets in pixels")
                    }
                }

                NoticeBox {
                    Layout.fillWidth: true
                    materialIcon: "drag_indicator"
                    text: Translation.tr("Hold click on any widget to reorder")
                }
            }

            ContentSubsection {
                id: cryptoSection
                title: Translation.tr("Crypto Widget")
                tooltip: Translation.tr("Configure cryptocurrencies to track")
                visible: Config.options?.sidebar?.widgets?.crypto ?? false

                readonly property var popularCoins: [
                    "bitcoin", "ethereum", "solana", "cardano", "dogecoin", "ripple",
                    "polkadot", "litecoin", "monero", "toncoin", "avalanche-2", "chainlink",
                    "uniswap", "stellar", "binancecoin", "tron", "shiba-inu", "pepe"
                ]

                function addCoin(coinId) {
                    const id = coinId.toLowerCase().trim()
                    if (!id) return
                    const current = Config.options?.sidebar?.widgets?.crypto_settings?.coins ?? []
                    if (current.includes(id)) return
                    Config.setNestedValue("sidebar.widgets.crypto_settings.coins", [...current, id])
                    coinInput.text = ""
                    coinPopup.close()
                }

                function removeCoin(coinId) {
                    const current = Config.options?.sidebar?.widgets?.crypto_settings?.coins ?? []
                    Config.setNestedValue("sidebar.widgets.crypto_settings.coins", current.filter(c => c !== coinId))
                }

                function filteredCoins() {
                    const q = coinInput.text.toLowerCase().trim()
                    const current = Config.options?.sidebar?.widgets?.crypto_settings?.coins ?? []
                    return popularCoins.filter(c => !current.includes(c) && c.includes(q))
                }

                ConfigSpinBox {
                    icon: "schedule"
                    text: Translation.tr("Refresh interval (seconds)")
                    value: Config.options?.sidebar?.widgets?.crypto_settings?.refreshInterval ?? 60
                    from: 30
                    to: 300
                    stepSize: 30
                    onValueChanged: Config.setNestedValue("sidebar.widgets.crypto_settings.refreshInterval", value)
                }

                // Coin input with autocomplete
                ConfigRow {
                    Layout.fillWidth: true
                    implicitHeight: coinInput.implicitHeight

                    MaterialTextField {
                        id: coinInput
                        width: parent.width
                        placeholderText: Translation.tr("Type to search coins...")
                        text: ""
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.m3colors.m3onSurface
                        placeholderTextColor: Appearance.colors.colSubtext
                        background: Rectangle {
                            color: Appearance.colors.colLayer1
                            radius: Appearance.rounding.small
                            border.width: coinInput.activeFocus ? 2 : 1
                            border.color: coinInput.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border
                        }
                        onTextChanged: {
                            if (text.length > 0) coinPopup.open()
                            else coinPopup.close()
                        }
                        onAccepted: {
                            const filtered = cryptoSection.filteredCoins()
                            if (filtered.length > 0) cryptoSection.addCoin(filtered[0])
                            else if (text.trim()) cryptoSection.addCoin(text)
                        }
                        Keys.onDownPressed: coinList.incrementCurrentIndex()
                        Keys.onUpPressed: coinList.decrementCurrentIndex()
                    }

                    Popup {
                        id: coinPopup
                        y: coinInput.height + 4
                        width: coinInput.width
                        height: Math.min(200, coinList.contentHeight + 16)
                        padding: 8
                        visible: coinInput.text.length > 0 && cryptoSection.filteredCoins().length > 0

                        background: Rectangle {
                            color: Appearance.inirEverywhere ? Appearance.inir.colLayer2
                                 : Appearance.colors.colLayer2Base
                            radius: Appearance.inirEverywhere ? Appearance.inir.roundingSmall : Appearance.rounding.small
                            border.width: 1
                            border.color: Appearance.inirEverywhere ? Appearance.inir.colBorder
                                        : Appearance.colors.colLayer0Border
                        }

                        ListView {
                            id: coinList
                            anchors.fill: parent
                            model: cryptoSection.filteredCoins()
                            clip: true
                            currentIndex: 0

                            delegate: RippleButton {
                                id: coinDelegate
                                required property string modelData
                                required property int index
                                width: coinList.width
                                implicitHeight: 32
                                buttonRadius: Appearance.rounding.small
                                colBackground: coinList.currentIndex === index ? Appearance.colors.colLayer1Hover : "transparent"
                                colBackgroundHover: Appearance.colors.colLayer1Hover
                                onClicked: cryptoSection.addCoin(modelData)

                                contentItem: StyledText {
                                    text: coinDelegate.modelData
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    font.family: Appearance.font.family.monospace
                                    color: Appearance.colors.colOnLayer1
                                    leftPadding: 8
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }
                    }
                }

                // Coin chips
                Flow {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: (Config.options?.sidebar?.widgets?.crypto_settings?.coins ?? []).length > 0

                    Repeater {
                        model: Config.options?.sidebar?.widgets?.crypto_settings?.coins ?? []

                        InputChip {
                            required property string modelData
                            text: modelData
                            monospace: true
                            onRemoved: cryptoSection.removeCoin(modelData)
                        }
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Wallpaper Picker")
                tooltip: Translation.tr("Quick wallpaper selection widget")
                visible: Config.options?.sidebar?.widgets?.wallpaper ?? false

                ConfigSpinBox {
                    icon: "photo_size_select_large"
                    text: Translation.tr("Thumbnail size")
                    value: Config.options?.sidebar?.widgets?.quickWallpaper?.itemSize ?? 56
                    from: 40
                    to: 80
                    stepSize: 4
                    onValueChanged: Config.setNestedValue("sidebar.widgets.quickWallpaper.itemSize", value)
                }

                SettingsSwitch {
                    buttonIcon: "title"
                    text: Translation.tr("Show header")
                    checked: Config.options?.sidebar?.widgets?.quickWallpaper?.showHeader ?? true
                    onCheckedChanged: Config.setNestedValue("sidebar.widgets.quickWallpaper.showHeader", checked)
                }

                NoticeBox {
                    Layout.fillWidth: true
                    materialIcon: "swipe"
                    text: Translation.tr("Scroll horizontally to browse wallpapers")
                }
            }

            ContentSubsection {
                title: Translation.tr("Glance Header")
                tooltip: Translation.tr("Configure the header with time and quick indicators")

                SettingsSwitch {
                    buttonIcon: "volume_up"
                    text: Translation.tr("Volume button")
                    checked: Config.options?.sidebar?.widgets?.glance?.showVolume ?? true
                    onCheckedChanged: Config.setNestedValue("sidebar.widgets.glance.showVolume", checked)
                }

                SettingsSwitch {
                    buttonIcon: "sports_esports"
                    text: Translation.tr("Game mode indicator")
                    checked: Config.options?.sidebar?.widgets?.glance?.showGameMode ?? true
                    onCheckedChanged: Config.setNestedValue("sidebar.widgets.glance.showGameMode", checked)
                }

                SettingsSwitch {
                    buttonIcon: "do_not_disturb_on"
                    text: Translation.tr("Do not disturb indicator")
                    checked: Config.options?.sidebar?.widgets?.glance?.showDnd ?? true
                    onCheckedChanged: Config.setNestedValue("sidebar.widgets.glance.showDnd", checked)
                }
            }

            ContentSubsection {
                title: Translation.tr("Status Rings")
                tooltip: Translation.tr("Configure which system metrics to show")

                SettingsSwitch {
                    buttonIcon: "memory"
                    text: Translation.tr("CPU usage")
                    checked: Config.options?.sidebar?.widgets?.statusRings?.showCpu ?? true
                    onCheckedChanged: Config.setNestedValue("sidebar.widgets.statusRings.showCpu", checked)
                }

                SettingsSwitch {
                    buttonIcon: "memory_alt"
                    text: Translation.tr("RAM usage")
                    checked: Config.options?.sidebar?.widgets?.statusRings?.showRam ?? true
                    onCheckedChanged: Config.setNestedValue("sidebar.widgets.statusRings.showRam", checked)
                }

                SettingsSwitch {
                    buttonIcon: "hard_drive"
                    text: Translation.tr("Disk usage")
                    checked: Config.options?.sidebar?.widgets?.statusRings?.showDisk ?? true
                    onCheckedChanged: Config.setNestedValue("sidebar.widgets.statusRings.showDisk", checked)
                }

                SettingsSwitch {
                    buttonIcon: "thermostat"
                    text: Translation.tr("Temperature")
                    checked: Config.options?.sidebar?.widgets?.statusRings?.showTemp ?? true
                    onCheckedChanged: Config.setNestedValue("sidebar.widgets.statusRings.showTemp", checked)
                }

                SettingsSwitch {
                    buttonIcon: "battery_full"
                    text: Translation.tr("Battery")
                    checked: Config.options?.sidebar?.widgets?.statusRings?.showBattery ?? true
                    onCheckedChanged: Config.setNestedValue("sidebar.widgets.statusRings.showBattery", checked)
                }
            }

            ContentSubsection {
                title: Translation.tr("Controls Card")
                tooltip: Translation.tr("Configure which toggles and actions to show")

                ContentSubsectionLabel { text: Translation.tr("Toggles") }

                SettingsSwitch {
                    buttonIcon: "dark_mode"
                    text: Translation.tr("Dark mode")
                    checked: Config.options?.sidebar?.widgets?.controlsCard?.showDarkMode ?? true
                    onCheckedChanged: Config.setNestedValue("sidebar.widgets.controlsCard.showDarkMode", checked)
                }

                SettingsSwitch {
                    buttonIcon: "do_not_disturb_on"
                    text: Translation.tr("Do not disturb")
                    checked: Config.options?.sidebar?.widgets?.controlsCard?.showDnd ?? true
                    onCheckedChanged: Config.setNestedValue("sidebar.widgets.controlsCard.showDnd", checked)
                }

                SettingsSwitch {
                    buttonIcon: "nightlight"
                    text: Translation.tr("Night light")
                    checked: Config.options?.sidebar?.widgets?.controlsCard?.showNightLight ?? true
                    onCheckedChanged: Config.setNestedValue("sidebar.widgets.controlsCard.showNightLight", checked)
                }

                SettingsSwitch {
                    buttonIcon: "sports_esports"
                    text: Translation.tr("Game mode")
                    checked: Config.options?.sidebar?.widgets?.controlsCard?.showGameMode ?? true
                    onCheckedChanged: Config.setNestedValue("sidebar.widgets.controlsCard.showGameMode", checked)
                }

                ContentSubsectionLabel { text: Translation.tr("Actions") }

                SettingsSwitch {
                    buttonIcon: "wifi"
                    text: Translation.tr("Network")
                    checked: Config.options?.sidebar?.widgets?.controlsCard?.showNetwork ?? true
                    onCheckedChanged: Config.setNestedValue("sidebar.widgets.controlsCard.showNetwork", checked)
                }

                SettingsSwitch {
                    buttonIcon: "bluetooth"
                    text: Translation.tr("Bluetooth")
                    checked: Config.options?.sidebar?.widgets?.controlsCard?.showBluetooth ?? true
                    onCheckedChanged: Config.setNestedValue("sidebar.widgets.controlsCard.showBluetooth", checked)
                }

                SettingsSwitch {
                    buttonIcon: "settings"
                    text: Translation.tr("Settings")
                    checked: Config.options?.sidebar?.widgets?.controlsCard?.showSettings ?? true
                    onCheckedChanged: Config.setNestedValue("sidebar.widgets.controlsCard.showSettings", checked)
                }

                SettingsSwitch {
                    buttonIcon: "lock"
                    text: Translation.tr("Lock")
                    checked: Config.options?.sidebar?.widgets?.controlsCard?.showLock ?? true
                    onCheckedChanged: Config.setNestedValue("sidebar.widgets.controlsCard.showLock", checked)
                }
            }
        }
    }

    SettingsCardSection {
        visible: root.isIiActive
        expanded: false
        icon: "overview_key"
        title: Translation.tr("Overview")

        SettingsGroup {
            SettingsSwitch {
                buttonIcon: "check"
                text: Translation.tr("Enable")
                checked: Config.options?.overview?.enable ?? true
                enabled: !(Config.options?.overview?.dashboard?.enable ?? false)
                onCheckedChanged: Config.setNestedValue("overview.enable", checked)
                StyledToolTip {
                    text: Translation.tr("Enable the app launcher and workspace overview (Super+Space)")
                }
            }
            SettingsSwitch {
                buttonIcon: "dashboard"
                text: Translation.tr("Dashboard panel")
                checked: Config.options?.overview?.dashboard?.enable ?? false
                onCheckedChanged: {
                    Config.setNestedValue("overview.dashboard.enable", checked)
                    if (checked)
                        Config.setNestedValue("overview.enable", false)
                }
                StyledToolTip { text: Translation.tr("Show a control center dashboard below workspace previews") }
            }
            SettingsSwitch {
                buttonIcon: "toggle_on"
                text: Translation.tr("Dashboard: Quick toggles")
                checked: Config.options?.overview?.dashboard?.showToggles ?? true
                onCheckedChanged: Config.setNestedValue("overview.dashboard.showToggles", checked)
                visible: Config.options?.overview?.dashboard?.enable ?? false
            }
            SettingsSwitch {
                buttonIcon: "music_note"
                text: Translation.tr("Dashboard: Media player")
                checked: Config.options?.overview?.dashboard?.showMedia ?? true
                onCheckedChanged: Config.setNestedValue("overview.dashboard.showMedia", checked)
                visible: Config.options?.overview?.dashboard?.enable ?? false
            }
            SettingsSwitch {
                buttonIcon: "volume_up"
                text: Translation.tr("Dashboard: Volume slider")
                checked: Config.options?.overview?.dashboard?.showVolume ?? true
                onCheckedChanged: Config.setNestedValue("overview.dashboard.showVolume", checked)
                visible: Config.options?.overview?.dashboard?.enable ?? false
            }
            SettingsSwitch {
                buttonIcon: "cloud"
                text: Translation.tr("Dashboard: Weather")
                checked: Config.options?.overview?.dashboard?.showWeather ?? true
                onCheckedChanged: Config.setNestedValue("overview.dashboard.showWeather", checked)
                visible: Config.options?.overview?.dashboard?.enable ?? false
            }
            SettingsSwitch {
                buttonIcon: "memory"
                text: Translation.tr("Dashboard: System stats")
                checked: Config.options?.overview?.dashboard?.showSystem ?? true
                onCheckedChanged: Config.setNestedValue("overview.dashboard.showSystem", checked)
                visible: Config.options?.overview?.dashboard?.enable ?? false
            }
            SettingsSwitch {
                buttonIcon: "center_focus_strong"
                text: Translation.tr("Center icons")
                checked: Config.options.overview.centerIcons
                onCheckedChanged: {
                    Config.setNestedValue("overview.centerIcons", checked);
                }
                StyledToolTip {
                    text: Translation.tr("Center app icons in the launcher grid")
                }
            }
            SettingsSwitch {
                buttonIcon: "preview"
                text: Translation.tr("Show window previews")
                checked: Config.options?.overview?.showPreviews !== false
                onCheckedChanged: {
                    Config.setNestedValue("overview.showPreviews", checked);
                }
                StyledToolTip {
                    text: Translation.tr("Display thumbnail previews of windows in the overview")
                }
            }
            SettingsSwitch {
                buttonIcon: "screen_share"
                text: Translation.tr("Active screen only")
                checked: Config.options?.overview?.activeScreenOnly ?? false
                onCheckedChanged: Config.setNestedValue("overview.activeScreenOnly", checked)
                StyledToolTip {
                    text: Translation.tr("Show overview only on the currently focused screen (multi-monitor)")
                }
            }
            ConfigSpinBox {
                icon: "loupe"
                text: Translation.tr("Scale (%)")
                value: Config.options.overview.scale * 100
                from: 1
                to: 100
                stepSize: 1
                onValueChanged: {
                    Config.setNestedValue("overview.scale", value / 100);
                }
                StyledToolTip {
                    text: Translation.tr("Scale of workspace previews in the overview")
                }
            }
            ConfigRow {
                uniform: true
                ConfigSpinBox {
                    icon: "splitscreen_bottom"
                    text: Translation.tr("Rows")
                    value: Config.options.overview.rows
                    from: 1
                    to: 20
                    stepSize: 1
                    onValueChanged: {
                        Config.setNestedValue("overview.rows", value);
                    }
                    StyledToolTip {
                        text: Translation.tr("Number of rows in the app launcher grid")
                    }
                }
                ConfigSpinBox {
                    icon: "splitscreen_right"
                    text: Translation.tr("Columns")
                    value: Config.options.overview.columns
                    from: 1
                    to: 20
                    stepSize: 1
                    onValueChanged: {
                        Config.setNestedValue("overview.columns", value);
                    }
                    StyledToolTip {
                        text: Translation.tr("Number of columns in the app launcher grid")
                    }
                }
            }
            ContentSubsection {
                title: Translation.tr("Wallpaper background")

                SettingsSwitch {
                    buttonIcon: "blur_on"
                    text: Translation.tr("Enable wallpaper blur")
                    checked: !Config.options.overview || Config.options.overview.backgroundBlurEnable !== false
                    onCheckedChanged: {
                        Config.setNestedValue("overview.backgroundBlurEnable", checked);
                    }
                    StyledToolTip {
                        text: Translation.tr("Apply blur effect to the overview background")
                    }
                }

                ConfigSpinBox {
                    icon: "loupe"
                    text: Translation.tr("Wallpaper blur radius")
                    value: Config.options.overview && Config.options.overview.backgroundBlurRadius !== undefined
                           ? Config.options.overview.backgroundBlurRadius
                           : 22
                    from: 0
                    to: 100
                    stepSize: 1
                    enabled: !Config.options.overview || Config.options.overview.backgroundBlurEnable !== false
                    onValueChanged: {
                        Config.setNestedValue("overview.backgroundBlurRadius", value);
                    }
                    StyledToolTip {
                        text: Translation.tr("Intensity of the wallpaper blur")
                    }
                }

                ConfigSpinBox {
                    icon: "opacity"
                    text: Translation.tr("Wallpaper dim (%)")
                    value: Config.options.overview && Config.options.overview.backgroundDim !== undefined
                           ? Config.options.overview.backgroundDim
                           : 35
                    from: 0
                    to: 100
                    stepSize: 5
                    onValueChanged: {
                        Config.setNestedValue("overview.backgroundDim", value);
                    }
                    StyledToolTip {
                        text: Translation.tr("Darkness of the wallpaper behind overview")
                    }
                }

                ConfigSpinBox {
                    icon: "opacity"
                    text: Translation.tr("Overlay scrim dim (%)")
                    value: Config.options.overview && Config.options.overview.scrimDim !== undefined
                           ? Config.options.overview.scrimDim
                           : 35
                    from: 0
                    to: 100
                    stepSize: 5
                    onValueChanged: {
                        Config.setNestedValue("overview.scrimDim", value);
                    }
                    StyledToolTip {
                        text: Translation.tr("Additional darkness for better contrast")
                    }
                }
            }
            ContentSubsection {
                title: Translation.tr("Positioning")

                SettingsSwitch {
                    buttonIcon: "dashboard_customize"
                    text: Translation.tr("Respect bar area (never overlap)")
                    checked: !Config.options.overview || Config.options.overview.respectBar !== false
                    onCheckedChanged: {
                        Config.setNestedValue("overview.respectBar", checked);
                    }
                    StyledToolTip {
                        text: Translation.tr("Prevent overview from covering the system bar area")
                    }
                }

                ConfigRow {
                    uniform: true
                    ConfigSpinBox {
                        icon: "vertical_align_top"
                        text: Translation.tr("Extra top margin (px)")
                        value: Config.options.overview && Config.options.overview.topMargin !== undefined
                               ? Config.options.overview.topMargin
                               : 0
                        from: 0
                        to: 400
                        stepSize: 1
                        onValueChanged: {
                            Config.setNestedValue("overview.topMargin", value);
                        }
                        StyledToolTip {
                            text: Translation.tr("Space reserved at the top of the screen")
                        }
                    }
                    ConfigSpinBox {
                        icon: "vertical_align_bottom"
                        text: Translation.tr("Extra bottom margin (px)")
                        value: Config.options.overview && Config.options.overview.bottomMargin !== undefined
                               ? Config.options.overview.bottomMargin
                               : 0
                        from: 0
                        to: 400
                        stepSize: 1
                        onValueChanged: {
                            Config.setNestedValue("overview.bottomMargin", value);
                        }
                        StyledToolTip {
                            text: Translation.tr("Space reserved at the bottom of the screen")
                        }
                    }
                }
            }
            ContentSubsection {
                title: Translation.tr("Layout & gaps")

                ConfigSpinBox {
                    icon: "open_in_full"
                    text: Translation.tr("Max panel width (%) of screen")
                    value: Config.options.overview && Config.options.overview.maxPanelWidthRatio !== undefined
                           ? Math.round(Config.options.overview.maxPanelWidthRatio * 100)
                           : 100
                    from: 10
                    to: 100
                    stepSize: 5
                    onValueChanged: {
                        Config.setNestedValue("overview.maxPanelWidthRatio", value / 100);
                    }
                    StyledToolTip {
                        text: Translation.tr("Maximum width of the overview panel as screen percentage")
                    }
                }

                ConfigRow {
                    uniform: true
                    ConfigSpinBox {
                        icon: "grid_3x3"
                        text: Translation.tr("Workspace gap (px)")
                        value: Config.options.overview && Config.options.overview.workspaceSpacing !== undefined
                               ? Config.options.overview.workspaceSpacing
                               : 5
                        from: 0
                        to: 80
                        stepSize: 1
                        onValueChanged: {
                            Config.setNestedValue("overview.workspaceSpacing", value);
                        }
                        StyledToolTip {
                            text: Translation.tr("Horizontal gap between workspace previews")
                        }
                    }
                    ConfigSpinBox {
                        icon: "view_comfy_alt"
                        text: Translation.tr("Window tile gap (px)")
                        value: Config.options.overview && Config.options.overview.windowTileMargin !== undefined
                               ? Config.options.overview.windowTileMargin
                               : 6
                        from: 0
                        to: 80
                        stepSize: 1
                        onValueChanged: {
                            Config.setNestedValue("overview.windowTileMargin", value);
                        }
                        StyledToolTip {
                            text: Translation.tr("Gap between windows inside a workspace preview")
                        }
                    }
                }
            }
            ContentSubsection {
                title: Translation.tr("Icons")

                ConfigRow {
                    uniform: true
                    ConfigSpinBox {
                        icon: "format_size"
                        text: Translation.tr("Min icon size (px)")
                        value: Config.options.overview && Config.options.overview.iconMinSize !== undefined
                               ? Config.options.overview.iconMinSize
                               : 0
                        from: 0
                        to: 512
                        stepSize: 2
                        onValueChanged: {
                            Config.setNestedValue("overview.iconMinSize", value);
                        }
                        StyledToolTip {
                            text: Translation.tr("Minimum size for app icons")
                        }
                    }
                    ConfigSpinBox {
                        icon: "format_overline"
                        text: Translation.tr("Max icon size (px)")
                        value: Config.options.overview && Config.options.overview.iconMaxSize !== undefined
                               ? Config.options.overview.iconMaxSize
                               : 0
                        from: 0
                        to: 512
                        stepSize: 2
                        onValueChanged: {
                            Config.setNestedValue("overview.iconMaxSize", value);
                        }
                        StyledToolTip {
                            text: Translation.tr("Maximum size for app icons")
                        }
                    }
                }
            }
            ContentSubsection {
                title: Translation.tr("Behaviour")

                SettingsSwitch {
                    buttonIcon: "workspaces"
                    text: Translation.tr("Switch to dedicated workspace when opening Overview")
                    checked: Config.options.overview && Config.options.overview.switchToWorkspaceOnOpen
                    onCheckedChanged: {
                        Config.setNestedValue("overview.switchToWorkspaceOnOpen", checked);
                    }
                    StyledToolTip {
                        text: Translation.tr("Automatically switch to a specific workspace when overview opens")
                    }
                }

                ConfigSpinBox {
                    icon: "looks_one"
                    text: Translation.tr("Workspace number (1-based)")
                    enabled: Config.options.overview && Config.options.overview.switchToWorkspaceOnOpen
                    value: Config.options.overview && Config.options.overview.switchWorkspaceIndex !== undefined
                           ? Config.options.overview.switchWorkspaceIndex
                           : 1
                    from: 1
                    to: 20
                    stepSize: 1
                    onValueChanged: {
                        Config.setNestedValue("overview.switchWorkspaceIndex", value);
                    }
                    StyledToolTip {
                        text: Translation.tr("Index of the workspace to switch to")
                    }
                }
                ConfigSpinBox {
                    icon: "swap_vert"
                    text: Translation.tr("Wheel steps per workspace (Overview)")
                    value: Config.options.overview && Config.options.overview.scrollWorkspaceSteps !== undefined
                           ? Config.options.overview.scrollWorkspaceSteps
                           : 2
                    from: 1
                    to: 10
                    stepSize: 1
                    onValueChanged: {
                        Config.setNestedValue("overview.scrollWorkspaceSteps", value);
                    }
                    StyledToolTip {
                        text: Translation.tr("How many workspaces to scroll per mouse wheel detent")
                    }
                }
                SettingsSwitch {
                    buttonIcon: "overview_key"
                    text: Translation.tr("Keep Overview open when clicking windows")
                    checked: !Config.options.overview || Config.options.overview.keepOverviewOpenOnWindowClick !== false
                    onCheckedChanged: {
                        Config.setNestedValue("overview.keepOverviewOpenOnWindowClick", checked);
                    }
                    StyledToolTip {
                        text: Translation.tr("Don't close overview when clicking on a window preview")
                    }
                }
                SettingsSwitch {
                    buttonIcon: "close_fullscreen"
                    text: Translation.tr("Close Overview after moving window")
                    checked: !Config.options.overview || Config.options.overview.closeAfterWindowMove !== false
                    onCheckedChanged: {
                        Config.setNestedValue("overview.closeAfterWindowMove", checked);
                    }
                    StyledToolTip {
                        text: Translation.tr("Close overview automatically after dropping a window to a new workspace")
                    }
                }
                SettingsSwitch {
                    buttonIcon: "looks_one"
                    text: Translation.tr("Show workspace numbers")
                    checked: !Config.options.overview || Config.options.overview.showWorkspaceNumbers !== false
                    onCheckedChanged: {
                        Config.setNestedValue("overview.showWorkspaceNumbers", checked);
                    }
                    StyledToolTip {
                        text: Translation.tr("Overlay large numbers on workspace previews")
                    }
                }
            }
            ContentSubsection {
                title: Translation.tr("Animation")

                SettingsSwitch {
                    buttonIcon: "motion_play"
                    text: Translation.tr("Enable focus animation")
                    checked: !Config.options.overview || Config.options.overview.focusAnimationEnable !== false
                    onCheckedChanged: {
                        Config.setNestedValue("overview.focusAnimationEnable", checked);
                    }
                    StyledToolTip {
                        text: Translation.tr("Animate the focus rectangle when navigating with keyboard")
                    }
                }

                ConfigSpinBox {
                    icon: "speed"
                    text: Translation.tr("Focus animation duration (ms)")
                    enabled: !Config.options.overview || Config.options.overview.focusAnimationEnable !== false
                    value: Config.options.overview && Config.options.overview.focusAnimationDurationMs !== undefined
                           ? Config.options.overview.focusAnimationDurationMs
                           : 180
                    from: 0
                    to: 1000
                    stepSize: 10
                    onValueChanged: {
                        Config.setNestedValue("overview.focusAnimationDurationMs", value);
                    }
                    StyledToolTip {
                        text: Translation.tr("Speed of the focus rectangle animation")
                    }
                }
            }
        }
    }

}
