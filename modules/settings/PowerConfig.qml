import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

ContentPage {
    id: powerPage
    settingsPageIndex: 14
    settingsPageName: Translation.tr("Power")
    settingsPageIcon: "bolt"

    // ── Helper: format seconds as readable time ─────────────────────
    function formatTime(seconds) {
        if (seconds <= 0) return ""
        const h = Math.floor(seconds / 3600)
        const m = Math.floor((seconds % 3600) / 60)
        if (h > 0) return h + "h " + m + "m"
        return m + "m"
    }

    // ── Section 1: Battery ──────────────────────────────────────────
    SettingsCardSection {
        visible: Battery.available
        expanded: true
        icon: "battery_full"
        title: Translation.tr("Battery")

        SettingsGroup {
            // ── Status card ─────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: statusColumn.implicitHeight + 28
                radius: Appearance.rounding.normal
                color: Appearance.colors.colSurfaceContainerLow
                border.width: 1
                border.color: Appearance.colors.colLayer0Border

                ColumnLayout {
                    id: statusColumn
                    anchors {
                        left: parent.left; right: parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: 16; rightMargin: 16
                    }
                    spacing: 8

                    // Top row: icon, percentage, state, wattage
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        MaterialSymbol {
                            text: Battery.percentage > 80 ? "battery_full"
                                : Battery.percentage > 50 ? "battery_5_bar"
                                : Battery.percentage > 20 ? "battery_3_bar"
                                : "battery_1_bar"
                            iconSize: Appearance.font.pixelSize.larger * 1.4
                            color: Battery.isCritical ? Appearance.m3colors.m3error
                                 : Battery.isLow ? Appearance.m3colors.m3tertiary
                                 : Appearance.m3colors.m3primary
                        }

                        StyledText {
                            text: Battery.percentage + "%"
                            font.pixelSize: Appearance.font.pixelSize.larger
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnLayer1
                        }

                        StyledText {
                            text: Battery.isCharging ? Translation.tr("Charging")
                                : Battery.isFull ? Translation.tr("Full")
                                : Translation.tr("Discharging")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colSubtext
                        }

                        Item { Layout.fillWidth: true }

                        StyledText {
                            visible: Battery.energyRate > 0
                            text: Battery.energyRate.toFixed(1) + "W"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colSubtext
                        }
                    }

                    // Battery bar
                    Rectangle {
                        Layout.fillWidth: true
                        height: 8
                        radius: 4
                        color: Appearance.colors.colLayer1

                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(Battery.percentage, 100)) / 100
                            height: parent.height
                            radius: 4
                            color: Battery.percentage <= 10 ? Appearance.m3colors.m3error
                                 : Battery.percentage <= 20 ? ColorUtils.transparentize(Appearance.m3colors.m3error, 0.4)
                                 : Appearance.m3colors.m3tertiary

                            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                        }
                    }

                    // Time remaining
                    StyledText {
                        visible: {
                            if (Battery.isCharging && Battery.timeToFull > 0) return true
                            if (!Battery.isCharging && !Battery.isFull && Battery.timeToEmpty > 0) return true
                            return false
                        }
                        text: Battery.isCharging
                            ? "~" + powerPage.formatTime(Battery.timeToFull) + " " + Translation.tr("to full")
                            : "~" + powerPage.formatTime(Battery.timeToEmpty) + " " + Translation.tr("remaining")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                }
            }

            SettingsDivider {}

            // ── Thresholds ──────────────────────────────────────
            ContentSubsection {
                title: Translation.tr("Thresholds")
                tooltip: Translation.tr("Battery percentage thresholds for notifications and actions")

                ConfigSpinBox {
                    icon: "battery_alert"
                    text: Translation.tr("Low battery warning (%)")
                    value: Config.options?.battery?.low ?? 20
                    from: 5
                    to: 50
                    stepSize: 5
                    onValueChanged: {
                        if (value !== (Config.options?.battery?.low ?? 20))
                            Config.setNestedValue("battery.low", value)
                    }
                }

                ConfigSpinBox {
                    icon: "battery_very_low"
                    text: Translation.tr("Critical battery warning (%)")
                    value: Config.options?.battery?.critical ?? 5
                    from: 1
                    to: 30
                    stepSize: 1
                    onValueChanged: {
                        if (value !== (Config.options?.battery?.critical ?? 5))
                            Config.setNestedValue("battery.critical", value)
                    }
                }

                ConfigSpinBox {
                    icon: "power_settings_new"
                    text: Translation.tr("Auto-suspend threshold (%)")
                    value: Config.options?.battery?.suspend ?? 3
                    from: 1
                    to: 20
                    stepSize: 1
                    onValueChanged: {
                        if (value !== (Config.options?.battery?.suspend ?? 3))
                            Config.setNestedValue("battery.suspend", value)
                    }
                }

                ConfigSpinBox {
                    icon: "battery_charging_full"
                    text: Translation.tr("Full notification threshold (%)") + (value >= 101 ? " — " + Translation.tr("disabled") : "")
                    value: Config.options?.battery?.full ?? 101
                    from: 80
                    to: 101
                    stepSize: 1
                    onValueChanged: {
                        if (value !== (Config.options?.battery?.full ?? 101))
                            Config.setNestedValue("battery.full", value)
                    }
                    StyledToolTip {
                        text: Translation.tr("Set to 101 to disable full battery notifications")
                    }
                }
            }

            SettingsDivider {}

            // ── Toggles ─────────────────────────────────────────
            SettingsSwitch {
                buttonIcon: "power_settings_new"
                text: Translation.tr("Automatic suspend on critical")
                checked: Config.options?.battery?.automaticSuspend ?? true
                onCheckedChanged: {
                    if (checked !== (Config.options?.battery?.automaticSuspend ?? true))
                        Config.setNestedValue("battery.automaticSuspend", checked)
                }
                StyledToolTip {
                    text: Translation.tr("Automatically suspend the system when battery reaches the critical threshold")
                }
            }

            SettingsDivider {}

            SettingsSwitch {
                buttonIcon: "notifications_active"
                text: Translation.tr("Notify when full")
                checked: Config.options?.battery?.notifyFull ?? true
                onCheckedChanged: {
                    if (checked !== (Config.options?.battery?.notifyFull ?? true))
                        Config.setNestedValue("battery.notifyFull", checked)
                }
                StyledToolTip {
                    text: Translation.tr("Show a notification when the battery is fully charged")
                }
            }

            SettingsDivider {}

            SettingsSwitch {
                buttonIcon: "volume_up"
                text: Translation.tr("Battery sounds")
                checked: Config.options?.sounds?.battery ?? true
                onCheckedChanged: {
                    if (checked !== (Config.options?.sounds?.battery ?? true))
                        Config.setNestedValue("sounds.battery", checked)
                }
                StyledToolTip {
                    text: Translation.tr("Play sounds for battery notifications (low, critical, full)")
                }
            }
        }
    }

    // ── Section 2: Power Profile ────────────────────────────────────
    SettingsCardSection {
        expanded: true
        icon: "speed"
        title: Translation.tr("Power Profile")

        SettingsGroup {
            // Profile selector — three toggle buttons
            ContentSubsection {
                title: Translation.tr("Active Profile")
                tooltip: Translation.tr("Select the system power profile")

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    // Power Saver
                    RippleButton {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42

                        readonly property bool isActive: PowerProfiles.profile === PowerProfile.PowerSaver

                        contentItem: RowLayout {
                            spacing: 6
                            Item { Layout.fillWidth: true }
                            MaterialSymbol {
                                text: "energy_savings_leaf"
                                iconSize: Appearance.font.pixelSize.normal
                                color: parent.parent.isActive ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                text: Translation.tr("Saver")
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: parent.parent.isActive ? Font.Bold : Font.Normal
                                color: parent.parent.isActive ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1
                            }
                            Item { Layout.fillWidth: true }
                        }

                        background: Rectangle {
                            radius: Appearance.rounding.small
                            color: parent.isActive ? Appearance.m3colors.m3primary : Appearance.colors.colLayer1
                            border.width: 1
                            border.color: parent.isActive ? Appearance.m3colors.m3primary : Appearance.colors.colLayer0Border
                        }

                        onClicked: {
                            if (!isActive)
                                PowerProfiles.profile = PowerProfile.PowerSaver
                        }
                    }

                    // Balanced
                    RippleButton {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42

                        readonly property bool isActive: PowerProfiles.profile === PowerProfile.Balanced

                        contentItem: RowLayout {
                            spacing: 6
                            Item { Layout.fillWidth: true }
                            MaterialSymbol {
                                text: "airwave"
                                iconSize: Appearance.font.pixelSize.normal
                                color: parent.parent.isActive ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                text: Translation.tr("Balanced")
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: parent.parent.isActive ? Font.Bold : Font.Normal
                                color: parent.parent.isActive ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1
                            }
                            Item { Layout.fillWidth: true }
                        }

                        background: Rectangle {
                            radius: Appearance.rounding.small
                            color: parent.isActive ? Appearance.m3colors.m3primary : Appearance.colors.colLayer1
                            border.width: 1
                            border.color: parent.isActive ? Appearance.m3colors.m3primary : Appearance.colors.colLayer0Border
                        }

                        onClicked: {
                            if (!isActive)
                                PowerProfiles.profile = PowerProfile.Balanced
                        }
                    }

                    // Performance
                    RippleButton {
                        visible: PowerProfiles.hasPerformanceProfile
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42

                        readonly property bool isActive: PowerProfiles.profile === PowerProfile.Performance

                        contentItem: RowLayout {
                            spacing: 6
                            Item { Layout.fillWidth: true }
                            MaterialSymbol {
                                text: "local_fire_department"
                                iconSize: Appearance.font.pixelSize.normal
                                color: parent.parent.isActive ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                text: Translation.tr("Performance")
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: parent.parent.isActive ? Font.Bold : Font.Normal
                                color: parent.parent.isActive ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1
                            }
                            Item { Layout.fillWidth: true }
                        }

                        background: Rectangle {
                            radius: Appearance.rounding.small
                            color: parent.isActive ? Appearance.m3colors.m3primary : Appearance.colors.colLayer1
                            border.width: 1
                            border.color: parent.isActive ? Appearance.m3colors.m3primary : Appearance.colors.colLayer0Border
                        }

                        onClicked: {
                            if (!isActive)
                                PowerProfiles.profile = PowerProfile.Performance
                        }
                    }
                }
            }

            SettingsDivider {}

            // Profile description
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: profileDescRow.implicitHeight + 20
                radius: Appearance.rounding.small
                color: ColorUtils.transparentize(Appearance.m3colors.m3primary, 0.85)
                border.width: 1
                border.color: ColorUtils.transparentize(Appearance.m3colors.m3primary, 0.7)

                RowLayout {
                    id: profileDescRow
                    anchors {
                        left: parent.left; right: parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: 14; rightMargin: 14
                    }
                    spacing: 10

                    MaterialSymbol {
                        text: PowerProfiles.profile === PowerProfile.PowerSaver ? "energy_savings_leaf"
                            : PowerProfiles.profile === PowerProfile.Performance ? "local_fire_department"
                            : "airwave"
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.m3colors.m3primary
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: PowerProfiles.profile === PowerProfile.PowerSaver
                                ? Translation.tr("Reduces performance to save energy")
                            : PowerProfiles.profile === PowerProfile.Performance
                                ? Translation.tr("Maximum performance, higher energy use")
                            : Translation.tr("Default balance between performance and energy")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer1
                        wrapMode: Text.WordWrap
                    }
                }
            }

            SettingsDivider {}

            // Restore on startup
            SettingsSwitch {
                buttonIcon: "restart_alt"
                text: Translation.tr("Restore profile on startup")
                checked: Config.options?.powerProfiles?.restoreOnStart ?? true
                onCheckedChanged: {
                    if (checked !== (Config.options?.powerProfiles?.restoreOnStart ?? true))
                        Config.setNestedValue("powerProfiles.restoreOnStart", checked)
                }
                StyledToolTip {
                    text: Translation.tr("Restore the last used power profile when the shell starts")
                }
            }
        }
    }

    // ── Section 3: Idle & Sleep ─────────────────────────────────────
    SettingsCardSection {
        expanded: true
        icon: "bedtime"
        title: Translation.tr("Idle & Sleep")

        SettingsGroup {
            ConfigSpinBox {
                icon: "monitor"
                text: Translation.tr("Screen off") + ` (${value > 0 ? Math.floor(value/60) + "m " + (value%60) + "s" : Translation.tr("disabled")})`
                value: Config.options?.idle?.screenOffTimeout ?? 300
                from: 0
                to: 3600
                stepSize: 30
                onValueChanged: {
                    if (value !== (Config.options?.idle?.screenOffTimeout ?? 300))
                        Config.setNestedValue("idle.screenOffTimeout", value)
                }
                StyledToolTip {
                    text: Translation.tr("Turn off display after this many seconds of inactivity (0 = never)")
                }
            }

            ConfigSpinBox {
                icon: "lock"
                text: Translation.tr("Lock screen") + ` (${value > 0 ? Math.floor(value/60) + "m" : Translation.tr("disabled")})`
                value: Config.options?.idle?.lockTimeout ?? 600
                from: 0
                to: 3600
                stepSize: 60
                onValueChanged: {
                    if (value !== (Config.options?.idle?.lockTimeout ?? 600))
                        Config.setNestedValue("idle.lockTimeout", value)
                }
                StyledToolTip {
                    text: Translation.tr("Lock screen after this many seconds of inactivity (0 = never)")
                }
            }

            ConfigSpinBox {
                icon: "dark_mode"
                text: Translation.tr("Suspend") + ` (${value > 0 ? Math.floor(value/60) + "m" : Translation.tr("disabled")})`
                value: Config.options?.idle?.suspendTimeout ?? 0
                from: 0
                to: 7200
                stepSize: 60
                onValueChanged: {
                    if (value !== (Config.options?.idle?.suspendTimeout ?? 0))
                        Config.setNestedValue("idle.suspendTimeout", value)
                }
                StyledToolTip {
                    text: Translation.tr("Suspend system after this many seconds of inactivity (0 = never)")
                }
            }

            SettingsSwitch {
                buttonIcon: "lock_clock"
                text: Translation.tr("Lock before sleep")
                checked: Config.options?.idle?.lockBeforeSleep ?? true
                onCheckedChanged: {
                    if (checked !== (Config.options?.idle?.lockBeforeSleep ?? true))
                        Config.setNestedValue("idle.lockBeforeSleep", checked)
                }
                StyledToolTip {
                    text: Translation.tr("Lock the screen before the system goes to sleep")
                }
            }

            SettingsDivider {}

            SettingsSwitch {
                buttonIcon: "coffee"
                text: Translation.tr("Keep awake (caffeine)")
                checked: Idle.inhibit
                onCheckedChanged: {
                    if (checked !== Idle.inhibit) Idle.toggleInhibit()
                }
                StyledToolTip {
                    text: Translation.tr("Temporarily prevent screen from turning off and system from sleeping")
                }
            }
        }
    }
}
