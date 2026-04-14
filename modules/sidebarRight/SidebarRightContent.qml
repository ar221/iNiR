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

            SystemButtonRow {
                Layout.fillHeight: false
                Layout.fillWidth: true
                // Layout.margins: 10
                Layout.topMargin: 4
                Layout.bottomMargin: 4
            }

            Loader {
                id: slidersLoader
                Layout.fillWidth: true
                visible: active
                active: {
                    const configQuickSliders = Config.options?.sidebar?.quickSliders
                    if (!configQuickSliders?.enable) return false
                    if (!configQuickSliders?.showMic && !configQuickSliders?.showVolume && !configQuickSliders?.showBrightness) return false;
                    return true;
                }
                sourceComponent: QuickSliders {}
            }

            LoaderedQuickPanelImplementation {
                styleName: "classic"
                sourceComponent: ClassicQuickPanel {}
            }

            LoaderedQuickPanelImplementation {
                styleName: "android"
                sourceComponent: AndroidQuickPanel {
                    editMode: root.editMode
                }
            }

            CenterWidgetGroup {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillHeight: true
                Layout.fillWidth: true
            }

            BottomWidgetGroup {
                id: bottomWidgetGroup
                Layout.alignment: Qt.AlignHCenter
                Layout.fillHeight: false
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
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
                : Appearance.colors.colLayer1
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
                : Appearance.colors.colLayer1
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
