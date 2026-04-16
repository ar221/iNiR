pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.dashboard
import qs.services

DashboardCard {
    id: root
    headerText: "Quick Toggles"

    readonly property int columns: Config.options?.dashboard?.quickToggles?.columns ?? 3

    // Toggle definitions — each maps to an existing service action
    readonly property var toggleDefs: [
        {
            id: "dnd",
            label: "DND",
            icon: Notifications.silent ? "notifications_paused" : "notifications_active",
            toggled: Notifications.silent,
            action: () => { Notifications.silent = !Notifications.silent }
        },
        {
            id: "darkMode",
            label: "Dark Mode",
            icon: "contrast",
            toggled: Appearance.m3colors.darkmode,
            action: () => { MaterialThemeLoader.setDarkMode(!Appearance.m3colors.darkmode) }
        },
        {
            id: "wifi",
            label: "WiFi",
            icon: Network.materialSymbol,
            toggled: Network.wifiStatus !== "disabled",
            action: () => { Network.toggleWifi() }
        },
        {
            id: "powerProfile",
            label: "Power",
            icon: (() => {
                switch (PowerProfiles.profile) {
                    case PowerProfile.PowerSaver: return "energy_savings_leaf"
                    case PowerProfile.Performance: return "local_fire_department"
                    default: return "airwave"
                }
            })(),
            toggled: PowerProfiles.profile !== PowerProfile.Balanced,
            action: () => {
                if (PowerProfiles.hasPerformanceProfile) {
                    switch (PowerProfiles.profile) {
                        case PowerProfile.PowerSaver: PowerProfiles.profile = PowerProfile.Balanced; break
                        case PowerProfile.Balanced: PowerProfiles.profile = PowerProfile.Performance; break
                        case PowerProfile.Performance: PowerProfiles.profile = PowerProfile.PowerSaver; break
                    }
                } else {
                    PowerProfiles.profile = PowerProfiles.profile === PowerProfile.Balanced
                        ? PowerProfile.PowerSaver : PowerProfile.Balanced
                }
            }
        },
        {
            id: "bluetooth",
            label: "Bluetooth",
            icon: BluetoothStatus.connected ? "bluetooth_connected" : BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled",
            toggled: BluetoothStatus.enabled,
            action: () => {
                if (Bluetooth.defaultAdapter)
                    Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
            }
        },
        {
            id: "nightLight",
            label: "Night Light",
            icon: Hyprsunset.active ? "nightlight" : "nightlight_off",
            toggled: Hyprsunset.active,
            action: () => { Hyprsunset.toggle() }
        }
    ]

    // Filter toggles based on config
    readonly property var activeToggles: {
        const configured = Config.options?.dashboard?.quickToggles?.toggles ?? ["dnd", "darkMode", "wifi", "powerProfile", "bluetooth", "nightLight"]
        return root.toggleDefs.filter(t => configured.includes(t.id))
    }

    GridLayout {
        Layout.fillWidth: true
        columns: root.columns
        rowSpacing: 8
        columnSpacing: 8

        Repeater {
            model: root.activeToggles

            Rectangle {
                id: toggleBtn
                required property var modelData
                required property int index

                Layout.fillWidth: true
                Layout.preferredHeight: 72
                radius: 12
                color: toggleBtn.modelData.toggled
                    ? ColorUtils.transparentize(Appearance.colors.colPrimary, 0.8)
                    : Qt.rgba(1, 1, 1, 0.03)
                border.width: 1
                border.color: toggleBtn.modelData.toggled
                    ? ColorUtils.transparentize(Appearance.colors.colPrimary, 0.6)
                    : Qt.rgba(1, 1, 1, 0.04)

                Behavior on color {
                    enabled: Appearance.animationsEnabled
                    ColorAnimation { duration: 200 }
                }
                Behavior on border.color {
                    enabled: Appearance.animationsEnabled
                    ColorAnimation { duration: 200 }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        text: toggleBtn.modelData.icon
                        iconSize: 20
                        color: toggleBtn.modelData.toggled
                            ? Appearance.colors.colPrimary
                            : Qt.rgba(1, 1, 1, 0.45)
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: toggleBtn.modelData.label
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        color: toggleBtn.modelData.toggled
                            ? Appearance.colors.colPrimary
                            : Qt.rgba(1, 1, 1, 0.35)
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: toggleBtn.modelData.action()
                }
            }
        }
    }
}
