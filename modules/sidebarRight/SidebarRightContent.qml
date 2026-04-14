import qs
import qs.services
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import qs.modules.sidebarRight.quickToggles
import qs.modules.sidebarRight.quickToggles.classicStyle

import qs.modules.sidebarRight.bluetoothDevices
import qs.modules.sidebarRight.events
import qs.modules.sidebarRight.hotspot
import qs.modules.sidebarRight.nightLight
import qs.modules.sidebarRight.volumeMixer
import qs.modules.sidebarRight.wifiNetworks

Item {
    id: root
    property int sidebarWidth: Appearance.sizes.sidebarWidth
    property int sidebarPadding: 12
    property string settingsQmlPath: Quickshell.shellPath("settings.qml")
    property int screenWidth: 1920
    property int screenHeight: 1080
    property var panelScreen: null
    property bool showAudioOutputDialog: false
    property bool showAudioInputDialog: false
    property bool showBluetoothDialog: false
    property bool showEventsDialog: false
    property var eventsDialogEditEvent: null
    property bool showHotspotDialog: false
    property bool showNightLightDialog: false
    property bool showWifiDialog: false
    property bool editMode: false
    
    // Debounce timers to prevent accidental double-clicks
    property bool reloadButtonEnabled: true
    property bool settingsButtonEnabled: true

    function focusActiveItem() {
        if (bottomWidgetGroup && bottomWidgetGroup.focusActiveItem) {
            bottomWidgetGroup.focusActiveItem()
        }
    }

    Connections {
        target: GlobalStates
        function onSidebarRightOpenChanged() {
            if (!GlobalStates.sidebarRightOpen) {
                root.showWifiDialog = false;
                root.showBluetoothDialog = false;
                root.showAudioOutputDialog = false;
                root.showAudioInputDialog = false;
                root.showNightLightDialog = false;
                root.showHotspotDialog = false;
                root.eventsDialogEditEvent = null;
            }
        }
        function onRequestWifiDialogChanged() {
            if (GlobalStates.requestWifiDialog) {
                GlobalStates.requestWifiDialog = false
                if (!GlobalStates.sidebarRightOpen) GlobalStates.sidebarRightOpen = true
                root.showWifiDialog = true
            }
        }
        function onRequestBluetoothDialogChanged() {
            if (GlobalStates.requestBluetoothDialog) {
                GlobalStates.requestBluetoothDialog = false
                if (!GlobalStates.sidebarRightOpen) GlobalStates.sidebarRightOpen = true
                root.showBluetoothDialog = true
            }
        }
    }

    implicitHeight: bg.implicitHeight
    implicitWidth: bg.implicitWidth

    SidebarBackground {
        id: bg
        anchors.fill: parent
        side: "right"
        panelScreen: root.panelScreen
        screenWidth: root.screenWidth
        screenHeight: root.screenHeight
        sidebarWidth: root.sidebarWidth
        sidebarPadding: root.sidebarPadding

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: sidebarPadding
            spacing: 14

            // Staggered entrance — each card fades + slides in 40ms apart from
            // its predecessor when the sidebar opens. Indices preserve the
            // visual order; hidden cards (inactive Loaders) don't consume an
            // index slot visually but keep their place in the sequence so the
            // cadence stays stable as config flips on/off.
            readonly property bool _staggerActive: GlobalStates.sidebarRightOpen
                && (Config.options?.sidebar?.staggeredReveal ?? true)

            StaggeredReveal {
                Layout.fillWidth: true
                Layout.topMargin: 4
                Layout.bottomMargin: 4
                index: 0
                active: parent._staggerActive
                SystemButtonRow {
                    width: parent.width
                }
            }

            StaggeredReveal {
                Layout.fillWidth: true
                index: 1
                active: parent._staggerActive
                visible: slidersLoader.active
                Loader {
                    id: slidersLoader
                    width: parent.width
                    visible: active
                    active: {
                        const configQuickSliders = Config.options?.sidebar?.quickSliders
                        if (!configQuickSliders?.enable) return false
                        if (!configQuickSliders?.showMic && !configQuickSliders?.showVolume && !configQuickSliders?.showBrightness) return false;
                        return true;
                    }
                    sourceComponent: QuickSliders {}
                }
            }

            // ─── Focus Mode chip strip ─────────────────────────────
            StaggeredReveal {
                Layout.fillWidth: true
                index: 2
                active: parent._staggerActive
                visible: focusModeChipsLoader.active
                Loader {
                    id: focusModeChipsLoader
                    width: parent.width
                    visible: active
                    active: Config.options?.sidebar?.focusModeChips?.enable ?? true
                    sourceComponent: ButtonGroup {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    spacing: 4
                    color: "transparent"

                    Repeater {
                        model: FocusMode._modeOrder

                        GroupButton {
                            required property string modelData
                            required property int index

                            readonly property var modeProfile: FocusMode._profiles[modelData] ?? ({})
                            readonly property bool isActive: FocusMode.activeMode === modelData

                            toggled: isActive
                            buttonText: modeProfile.label ?? modelData
                            buttonRadius: Appearance.angelEverywhere ? Appearance.angel.roundingSmall
                                : Appearance.inirEverywhere ? Appearance.inir.roundingSmall
                                : Appearance.rounding.small

                            implicitHeight: 32
                            horizontalPadding: 12
                            verticalPadding: 0
                            bounce: false

                            colBackgroundToggled: {
                                switch (modelData) {
                                    case "focus": return Appearance.m3colors.m3primary
                                    case "gaming": return Appearance.m3colors.m3tertiary
                                    case "zen": return Appearance.m3colors.m3secondary
                                    default: return Appearance.angelEverywhere ? Appearance.angel.colGlassCard
                                        : Appearance.inirEverywhere ? Appearance.inir.colLayer2
                                        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurface
                                        : Appearance.colors.colLayer2
                                }
                            }
                            colBackgroundToggledHover: ColorUtils.transparentize(colBackgroundToggled, 0.15)
                            colBackground: "transparent"
                            colBackgroundHover: Appearance.angelEverywhere ? Appearance.angel.colGlassCardHover
                                : Appearance.inirEverywhere ? Appearance.inir.colLayer2Hover
                                : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurfaceHover
                                : Appearance.colors.colLayer2Hover

                            Layout.fillWidth: true

                            onClicked: FocusMode.setMode(modelData)

                            contentItem: RowLayout {
                                spacing: 4

                                MaterialSymbol {
                                    visible: modeProfile.icon !== ""
                                    text: modeProfile.icon ?? ""
                                    iconSize: 16
                                    color: isActive
                                        ? (Appearance.angelEverywhere ? Appearance.angel.colOnPrimary
                                            : Appearance.inirEverywhere ? Appearance.inir.colOnPrimary
                                            : Appearance.m3colors.m3onPrimary)
                                        : (Appearance.angelEverywhere ? Appearance.angel.colText
                                            : Appearance.inirEverywhere ? Appearance.inir.colText
                                            : Appearance.colors.colOnLayer1)

                                    Behavior on color {
                                        enabled: Appearance.animationsEnabled
                                        animation: ColorAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
                                    }
                                }

                                StyledText {
                                    text: modeProfile.label ?? modelData
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    font.weight: Font.Medium
                                    color: isActive
                                        ? (Appearance.angelEverywhere ? Appearance.angel.colOnPrimary
                                            : Appearance.inirEverywhere ? Appearance.inir.colOnPrimary
                                            : Appearance.m3colors.m3onPrimary)
                                        : (Appearance.angelEverywhere ? Appearance.angel.colText
                                            : Appearance.inirEverywhere ? Appearance.inir.colText
                                            : Appearance.colors.colOnLayer1)

                                    Behavior on color {
                                        enabled: Appearance.animationsEnabled
                                        animation: ColorAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            StaggeredReveal {
                Layout.fillWidth: true
                index: 3
                active: parent._staggerActive
                visible: classicQuickPanel.visible
                LoaderedQuickPanelImplementation {
                    id: classicQuickPanel
                    width: parent.width
                    styleName: "classic"
                    sourceComponent: ClassicQuickPanel {}
                }
            }

            StaggeredReveal {
                Layout.fillWidth: true
                index: 3
                active: parent._staggerActive
                visible: androidQuickPanel.visible
                LoaderedQuickPanelImplementation {
                    id: androidQuickPanel
                    width: parent.width
                    styleName: "android"
                    sourceComponent: AndroidQuickPanel {
                        editMode: root.editMode
                    }
                }
            }

            StaggeredReveal {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillHeight: true
                Layout.fillWidth: true
                index: 4
                active: parent._staggerActive
                CenterWidgetGroup {
                    anchors.fill: parent
                }
            }

            StaggeredReveal {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                index: 5
                active: parent._staggerActive
                BottomWidgetGroup {
                    id: bottomWidgetGroup
                    width: parent.width
                }
            }
        }
    }

    ToggleDialog {
        shownPropertyString: "showAudioOutputDialog"
        dialog: VolumeDialog {
            isSink: true
        }
    }

    ToggleDialog {
        shownPropertyString: "showAudioInputDialog"
        dialog: VolumeDialog {
            isSink: false
        }
    }

    ToggleDialog {
        shownPropertyString: "showBluetoothDialog"
        dialog: BluetoothDialog {}
        onShownChanged: {
            if (!Bluetooth.defaultAdapter) return
            if (!shown) {
                Bluetooth.defaultAdapter.discovering = false;
            } else {
                Bluetooth.defaultAdapter.enabled = true;
                Bluetooth.defaultAdapter.discovering = true;
            }
        }
    }

    ToggleDialog {
        shownPropertyString: "showNightLightDialog"
        dialog: NightLightDialog {}
    }

    ToggleDialog {
        shownPropertyString: "showHotspotDialog"
        dialog: HotspotDialog {}
    }

    ToggleDialog {
        shownPropertyString: "showWifiDialog"
        dialog: WifiDialog {}
        onShownChanged: {
            if (!shown) return;
            Network.enableWifi();
            Network.rescanWifi();
        }
    }

    component ToggleDialog: Loader {
        id: toggleDialogLoader
        required property string shownPropertyString
        property alias dialog: toggleDialogLoader.sourceComponent
        readonly property bool shown: root[shownPropertyString]
        anchors.fill: parent

        active: shown
        
        onItemChanged: {
            if (item) {
                item.show = true;
                item.forceActiveFocus();
            }
        }
        
        Connections {
            target: toggleDialogLoader.item
            function onDismiss() {
                root[toggleDialogLoader.shownPropertyString] = false;
            }
        }
    }

    component LoaderedQuickPanelImplementation: Loader {
        id: quickPanelImplLoader
        required property string styleName
        Layout.alignment: item?.Layout.alignment ?? Qt.AlignHCenter
        Layout.fillWidth: item?.Layout.fillWidth ?? false
        visible: active
        active: (Config.options?.sidebar?.quickToggles?.style ?? "classic") === styleName
        Connections {
            target: quickPanelImplLoader.item
            function onOpenAudioOutputDialog() {
                root.showAudioOutputDialog = true;
            }
            function onOpenAudioInputDialog() {
                root.showAudioInputDialog = true;
            }
            function onOpenBluetoothDialog() {
                root.showBluetoothDialog = true;
            }
            function onOpenNightLightDialog() {
                root.showNightLightDialog = true;
            }
            function onOpenHotspotDialog() {
                root.showHotspotDialog = true;
            }
            function onOpenWifiDialog() {
                root.showWifiDialog = true;
            }
        }
    }

    component SystemButtonRow: Item {
        implicitHeight: Math.max(uptimeContainer.implicitHeight, systemButtonsRow.implicitHeight)

        Rectangle {
            id: uptimeContainer
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
            }
            color: bg.angelEverywhere ? Appearance.angel.colGlassCard
                : bg.auroraEverywhere
                ? Appearance.aurora.colSubSurface
                // M3 tier audit: sidebar cards use surfaceContainerHigh on material fallback
                : Appearance.colors.colLayer3
            radius: bg.angelEverywhere ? Appearance.angel.roundingSmall : height / 2
            border.width: bg.angelEverywhere ? Appearance.angel.cardBorderWidth : 0
            border.color: bg.angelEverywhere ? Appearance.angel.colCardBorder : "transparent"
            implicitWidth: uptimeRow.implicitWidth + 24
            implicitHeight: uptimeRow.implicitHeight + 8
            
            Row {
                id: uptimeRow
                anchors.centerIn: parent
                spacing: 8
                CustomIcon {
                    id: distroIcon
                    anchors.verticalCenter: parent.verticalCenter
                    width: 25
                    height: 25
                    source: SystemInfo.distroIcon
                    colorize: true
                    color: Appearance.angelEverywhere ? Appearance.angel.colText : Appearance.colors.colOnLayer0
                }
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.angelEverywhere ? Appearance.angel.colText : Appearance.colors.colOnLayer0
                    text: Translation.tr("Up %1").arg(DateTime.uptime)
                    textFormat: Text.MarkdownText
                }
            }
        }

        ButtonGroup {
            id: systemButtonsRow
            anchors {
                top: parent.top
                bottom: parent.bottom
                right: parent.right
            }
            color: bg.angelEverywhere ? Appearance.angel.colGlassCard
                : bg.auroraEverywhere
                ? Appearance.aurora.colSubSurface
                // M3 tier audit: sidebar cards use surfaceContainerHigh on material fallback
                : Appearance.colors.colLayer3
            padding: 4
            spacing: 8  // Increased from default 5 to reduce accidental clicks

            QuickToggleButton {
                toggled: root.editMode
                visible: (Config.options?.sidebar?.quickToggles?.style ?? "classic") === "android"
                buttonIcon: "edit"
                onClicked: root.editMode = !root.editMode
                StyledToolTip {
                    text: Translation.tr("Edit quick toggles") + (root.editMode ? Translation.tr("\nLMB to enable/disable\nRMB to toggle size\nScroll to swap position") : "")
                }
            }
            QuickToggleButton {
                readonly property bool _isCompact: (Config.options?.sidebar?.layout ?? "default") === "compact"
                toggled: _isCompact
                buttonIcon: _isCompact ? "expand_content" : "compress"
                onClicked: {
                    Config.setNestedValue("sidebar.layout", _isCompact ? "default" : "compact")
                }
                StyledToolTip {
                    text: Translation.tr("Toggle compact layout")
                }
            }
            QuickToggleButton {
                id: reloadButton
                toggled: false
                enabled: root.reloadButtonEnabled
                opacity: enabled ? 1.0 : 0.5
                buttonIcon: "restart_alt"
                onClicked: {
                    if (!root.reloadButtonEnabled) {
                        console.log("[SidebarRight] Reload button still on cooldown, ignoring click");
                        return;
                    }
                    
                    console.log("[SidebarRight] Reload button clicked");
                    root.reloadButtonEnabled = false;
                    reloadButtonCooldown.restart();
                    
                    if (CompositorService.isHyprland) {
                        Hyprland.dispatch("reload");
                    } else if (CompositorService.isNiri) {
                        Quickshell.execDetached(["/usr/bin/niri", "msg", "action", "load-config-file"]);
                    }
                    Quickshell.execDetached(["/usr/bin/bash", Quickshell.shellPath("scripts/restart-shell.sh")]);
                }
                StyledToolTip {
                    text: Translation.tr("Reload Quickshell")
                }
            }
            
            Timer {
                id: reloadButtonCooldown
                interval: 500
                onTriggered: {
                    root.reloadButtonEnabled = true;
                    console.log("[SidebarRight] Reload button cooldown finished");
                }
            }
            QuickToggleButton {
                id: settingsButton
                toggled: false
                enabled: root.settingsButtonEnabled
                opacity: enabled ? 1.0 : 0.5
                buttonIcon: "settings"
                onClicked: {
                    if (!root.settingsButtonEnabled) {
                        console.log("[SidebarRight] Settings button still on cooldown, ignoring click");
                        return;
                    }
                    
                    console.log("[SidebarRight] Settings button clicked");
                    root.settingsButtonEnabled = false;
                    settingsButtonCooldown.restart();
                    
                    if (CompositorService.isNiri) {
                        const wins = NiriService.windows || []
                        console.log("[SidebarRight] Checking for existing settings window among", wins.length, "windows");
                        for (let i = 0; i < wins.length; i++) {
                            const w = wins[i]
                            if (w.title === "illogical-impulse Settings" && w.app_id === "org.quickshell") {
                                console.log("[SidebarRight] Found existing settings window, focusing it");
                                GlobalStates.sidebarRightOpen = false;
                                Qt.callLater(() => {
                                    NiriService.focusWindow(w.id)
                                })
                                return
                            }
                        }
                        console.log("[SidebarRight] No existing settings window found");
                    }
                    
                    console.log("[SidebarRight] Opening new settings window via IPC");
                    GlobalStates.sidebarRightOpen = false;
                    Qt.callLater(() => {
                        Quickshell.execDetached([Quickshell.shellPath("scripts/inir"), "settings"]);
                    })
                }
                StyledToolTip {
                    text: Translation.tr("Settings")
                }
            }
            
            Timer {
                id: settingsButtonCooldown
                interval: 500
                onTriggered: {
                    root.settingsButtonEnabled = true;
                    console.log("[SidebarRight] Settings button cooldown finished");
                }
            }
            QuickToggleButton {
                toggled: false
                buttonIcon: "power_settings_new"
                onClicked: {
                    GlobalStates.sessionOpen = true;
                }
                StyledToolTip {
                    text: Translation.tr("Session")
                }
            }
        }
    }
}
