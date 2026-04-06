import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

ContentPage {
    id: rulesPage
    settingsPageIndex: 17
    settingsPageName: Translation.tr("Notification Rules")
    settingsPageIcon: "notifications_active"

    // Filter text for app search
    property string filterText: ""

    // Mode labels and values
    readonly property var modeLabels: [
        Translation.tr("Allow"),
        Translation.tr("Silent"),
        Translation.tr("Sound Only"),
        Translation.tr("Block")
    ]
    readonly property var modeValues: ["allow", "silent", "soundOnly", "block"]

    function modeToIndex(mode) {
        const idx = modeValues.indexOf(mode)
        return idx >= 0 ? idx : 0
    }

    function indexToMode(idx) {
        return modeValues[idx] ?? "allow"
    }

    // Position labels and values
    readonly property var positionLabels: [
        Translation.tr("Top Right"),
        Translation.tr("Top Left"),
        Translation.tr("Bottom Right"),
        Translation.tr("Bottom Left")
    ]
    readonly property var positionValues: ["topRight", "topLeft", "bottomRight", "bottomLeft"]

    function positionToIndex(pos) {
        const idx = positionValues.indexOf(pos)
        return idx >= 0 ? idx : 0
    }

    // ── Section 1: Per-App Rules ────────────────────────────────────
    SettingsCardSection {
        expanded: true
        icon: "app_registration"
        title: Translation.tr("Per-App Rules")

        SettingsGroup {
            // Filter field
            MaterialTextField {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Filter apps...")
                text: rulesPage.filterText
                onTextChanged: rulesPage.filterText = text
            }

            // App list
            Repeater {
                id: appRepeater
                model: {
                    const apps = Notifications.knownApps ?? []
                    if (!rulesPage.filterText) return apps
                    const q = rulesPage.filterText.toLowerCase()
                    return apps.filter(name => name.toLowerCase().indexOf(q) >= 0)
                }

                delegate: ColumnLayout {
                    id: appDelegate
                    required property int index
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 0

                    property string appName: modelData
                    property var rule: Notifications.getRuleForApp(appName)
                    property bool showDetails: false
                    property bool _updatingMode: false

                    // Card background
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: appCardContent.implicitHeight
                        radius: Appearance.rounding.normal
                        color: Appearance.colors.colSurfaceContainerLow
                        border.width: 1
                        border.color: Appearance.colors.colLayer0Border

                        ColumnLayout {
                            id: appCardContent
                            anchors.left: parent.left
                            anchors.right: parent.right
                            spacing: 0

                            // Main row: icon, name, mode selector, expand
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.margins: 12
                                spacing: 10

                                // App icon
                                Item {
                                    implicitWidth: 32
                                    implicitHeight: 32

                                    Image {
                                        id: appIconImg
                                        anchors.fill: parent
                                        source: Quickshell.iconPath(appDelegate.appName.toLowerCase(), "")
                                        visible: status === Image.Ready
                                        fillMode: Image.PreserveAspectFit
                                        sourceSize: Qt.size(32, 32)
                                    }

                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        visible: appIconImg.status !== Image.Ready
                                        text: "apps"
                                        iconSize: 24
                                        color: Appearance.colors.colSubtext
                                    }
                                }

                                // App name
                                StyledText {
                                    Layout.fillWidth: true
                                    text: appDelegate.appName
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    font.weight: Font.Medium
                                    color: Appearance.colors.colOnLayer1
                                    elide: Text.ElideRight
                                }

                                // Mode combo
                                StyledComboBox {
                                    id: modeCombo
                                    implicitWidth: 130
                                    model: rulesPage.modeLabels
                                    currentIndex: rulesPage.modeToIndex(appDelegate.rule?.mode ?? "allow")

                                    onCurrentIndexChanged: {
                                        if (appDelegate._updatingMode) return
                                        const newMode = rulesPage.indexToMode(currentIndex)
                                        const currentRule = Notifications.getRuleForApp(appDelegate.appName)
                                        if (currentRule.mode !== newMode) {
                                            currentRule.mode = newMode
                                            Notifications.setRuleForApp(appDelegate.appName, currentRule)
                                            appDelegate.rule = Notifications.getRuleForApp(appDelegate.appName)
                                        }
                                    }
                                }

                                // Expand/collapse button
                                RippleButton {
                                    implicitWidth: 32
                                    implicitHeight: 32
                                    buttonRadius: Appearance.rounding.full
                                    colBackground: "transparent"
                                    colBackgroundHover: Appearance.colors.colLayer1Hover
                                    colRipple: Appearance.colors.colLayer1Active
                                    onClicked: appDelegate.showDetails = !appDelegate.showDetails

                                    contentItem: MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: appDelegate.showDetails ? "expand_less" : "expand_more"
                                        iconSize: 20
                                        color: Appearance.colors.colSubtext
                                    }
                                }
                            }

                            // Detail controls (when expanded)
                            ColumnLayout {
                                visible: appDelegate.showDetails
                                Layout.fillWidth: true
                                Layout.leftMargin: 16
                                Layout.rightMargin: 16
                                Layout.bottomMargin: 12
                                spacing: 4

                                // Separator
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 1
                                    color: Appearance.colors.colLayer0Border
                                    Layout.bottomMargin: 4
                                }

                                SettingsSwitch {
                                    buttonIcon: "volume_up"
                                    text: Translation.tr("Sound")
                                    checked: appDelegate.rule?.sound ?? true
                                    onCheckedChanged: {
                                        const currentRule = Notifications.getRuleForApp(appDelegate.appName)
                                        if (currentRule.sound !== checked) {
                                            currentRule.sound = checked
                                            Notifications.setRuleForApp(appDelegate.appName, currentRule)
                                            appDelegate.rule = Notifications.getRuleForApp(appDelegate.appName)
                                        }
                                    }
                                }

                                SettingsSwitch {
                                    buttonIcon: "notifications_active"
                                    text: Translation.tr("Popup")
                                    checked: appDelegate.rule?.popup ?? true
                                    onCheckedChanged: {
                                        const currentRule = Notifications.getRuleForApp(appDelegate.appName)
                                        if (currentRule.popup !== checked) {
                                            currentRule.popup = checked
                                            Notifications.setRuleForApp(appDelegate.appName, currentRule)
                                            appDelegate.rule = Notifications.getRuleForApp(appDelegate.appName)
                                        }
                                    }
                                }

                                ConfigSpinBox {
                                    icon: "timer"
                                    text: Translation.tr("Custom timeout") + ` (${value > 0 ? (value / 1000).toFixed(0) + "s" : Translation.tr("default")})`
                                    value: appDelegate.rule?.timeout ?? 0
                                    from: 0
                                    to: 30000
                                    stepSize: 1000
                                    onValueChanged: {
                                        const currentRule = Notifications.getRuleForApp(appDelegate.appName)
                                        const newTimeout = value === 0 ? null : value
                                        if (currentRule.timeout !== newTimeout) {
                                            currentRule.timeout = newTimeout
                                            Notifications.setRuleForApp(appDelegate.appName, currentRule)
                                            appDelegate.rule = Notifications.getRuleForApp(appDelegate.appName)
                                        }
                                    }
                                    StyledToolTip {
                                        text: Translation.tr("Custom timeout in milliseconds (0 = use default)")
                                    }
                                }

                                // Remove rule button
                                RippleButton {
                                    Layout.alignment: Qt.AlignRight
                                    implicitWidth: removeBtnContent.implicitWidth + 24
                                    implicitHeight: 32
                                    buttonRadius: Appearance.rounding.small
                                    colBackground: "transparent"
                                    colBackgroundHover: ColorUtils.transparentize(Appearance.m3colors.m3error, 0.85)
                                    colRipple: ColorUtils.transparentize(Appearance.m3colors.m3error, 0.7)
                                    onClicked: {
                                        Notifications.removeRuleForApp(appDelegate.appName)
                                        appDelegate.rule = Notifications.getRuleForApp(appDelegate.appName)
                                        appDelegate.showDetails = false
                                    }

                                    contentItem: RowLayout {
                                        id: removeBtnContent
                                        anchors.centerIn: parent
                                        spacing: 4
                                        MaterialSymbol {
                                            text: "delete"
                                            iconSize: 16
                                            color: Appearance.m3colors.m3error
                                        }
                                        StyledText {
                                            text: Translation.tr("Remove Rule")
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            color: Appearance.m3colors.m3error
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Empty state
            StyledText {
                visible: (Notifications.knownApps ?? []).length === 0
                Layout.fillWidth: true
                Layout.topMargin: 8
                text: Translation.tr("No apps have sent notifications yet.")
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colSubtext
                horizontalAlignment: Text.AlignHCenter
            }

            // No results for filter
            StyledText {
                visible: appRepeater.count === 0 && (Notifications.knownApps ?? []).length > 0 && rulesPage.filterText !== ""
                Layout.fillWidth: true
                Layout.topMargin: 8
                text: Translation.tr("No apps match the filter.")
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colSubtext
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    // ── Section 2: Add Custom Rule ──────────────────────────────────
    SettingsCardSection {
        expanded: false
        icon: "add_circle"
        title: Translation.tr("Add Custom Rule")

        SettingsGroup {
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                MaterialTextField {
                    id: customAppNameField
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("App name")
                }

                StyledComboBox {
                    id: customModeCombo
                    implicitWidth: 130
                    model: rulesPage.modeLabels
                    currentIndex: 0
                }

                RippleButton {
                    implicitWidth: addBtnText.implicitWidth + 24
                    implicitHeight: 36
                    buttonRadius: Appearance.rounding.small
                    colBackground: Appearance.m3colors.m3primary
                    colBackgroundHover: Appearance.colors.colPrimaryHover
                    colRipple: Appearance.colors.colPrimaryActive
                    enabled: customAppNameField.text.trim() !== ""
                    opacity: enabled ? 1.0 : 0.5

                    onClicked: {
                        const name = customAppNameField.text.trim()
                        if (!name) return
                        const mode = rulesPage.indexToMode(customModeCombo.currentIndex)
                        Notifications.setRuleForApp(name, {
                            mode: mode,
                            sound: mode !== "silent" && mode !== "block",
                            popup: mode !== "block",
                            timeout: null
                        })
                        customAppNameField.text = ""
                        customModeCombo.currentIndex = 0
                    }

                    contentItem: StyledText {
                        id: addBtnText
                        anchors.centerIn: parent
                        text: Translation.tr("Add")
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.DemiBold
                        color: Appearance.m3colors.m3onPrimary
                    }
                }
            }
        }
    }

    // ── Section 3: Global Settings ──────────────────────────────────
    SettingsCardSection {
        expanded: true
        icon: "tune"
        title: Translation.tr("Global Settings")

        SettingsGroup {
            // Notification position
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                MaterialSymbol {
                    text: "picture_in_picture"
                    iconSize: 20
                    color: Appearance.colors.colSubtext
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Notification position")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer1
                }

                StyledComboBox {
                    id: positionCombo
                    implicitWidth: 160
                    model: rulesPage.positionLabels
                    property bool _updating: false
                    currentIndex: {
                        _updating = true
                        const idx = rulesPage.positionToIndex(Config.options?.notifications?.position ?? "topRight")
                        _updating = false
                        return idx
                    }
                    onCurrentIndexChanged: {
                        if (_updating) return
                        Config.setNestedValue("notifications.position", rulesPage.positionValues[currentIndex])
                    }
                }
            }

            // Default timeout — low urgency
            ConfigSpinBox {
                icon: "low_priority"
                text: Translation.tr("Low urgency timeout") + ` (${(value / 1000).toFixed(0)}s)`
                value: Config.options?.notifications?.timeoutLow ?? 5000
                from: 1000
                to: 30000
                stepSize: 1000
                onValueChanged: {
                    if (value !== (Config.options?.notifications?.timeoutLow ?? 5000))
                        Config.setNestedValue("notifications.timeoutLow", value)
                }
                StyledToolTip {
                    text: Translation.tr("Auto-dismiss timeout for low urgency notifications (ms)")
                }
            }

            // Default timeout — normal urgency
            ConfigSpinBox {
                icon: "notifications"
                text: Translation.tr("Normal urgency timeout") + ` (${(value / 1000).toFixed(0)}s)`
                value: Config.options?.notifications?.timeoutNormal ?? 7000
                from: 1000
                to: 30000
                stepSize: 1000
                onValueChanged: {
                    if (value !== (Config.options?.notifications?.timeoutNormal ?? 7000))
                        Config.setNestedValue("notifications.timeoutNormal", value)
                }
                StyledToolTip {
                    text: Translation.tr("Auto-dismiss timeout for normal urgency notifications (ms)")
                }
            }

            // Default timeout — critical urgency
            ConfigSpinBox {
                icon: "warning"
                text: Translation.tr("Critical urgency timeout") + ` (${value > 0 ? (value / 1000).toFixed(0) + "s" : Translation.tr("never")})`
                value: Config.options?.notifications?.timeoutCritical ?? 0
                from: 0
                to: 30000
                stepSize: 1000
                onValueChanged: {
                    if (value !== (Config.options?.notifications?.timeoutCritical ?? 0))
                        Config.setNestedValue("notifications.timeoutCritical", value)
                }
                StyledToolTip {
                    text: Translation.tr("Auto-dismiss timeout for critical notifications (0 = never auto-dismiss)")
                }
            }

            // Undo on dismiss
            SettingsSwitch {
                buttonIcon: "undo"
                text: Translation.tr("Undo on dismiss")
                checked: Config.options?.notifications?.undoOnDismiss ?? true
                onCheckedChanged: {
                    if (checked !== (Config.options?.notifications?.undoOnDismiss ?? true))
                        Config.setNestedValue("notifications.undoOnDismiss", checked)
                }
                StyledToolTip {
                    text: Translation.tr("Show an undo bar when swiping away notifications")
                }
            }

            // Notification sounds
            SettingsSwitch {
                buttonIcon: "volume_up"
                text: Translation.tr("Notification sounds")
                checked: Config.options?.sounds?.notifications ?? true
                onCheckedChanged: {
                    if (checked !== (Config.options?.sounds?.notifications ?? true))
                        Config.setNestedValue("sounds.notifications", checked)
                }
                StyledToolTip {
                    text: Translation.tr("Play a sound when notifications arrive")
                }
            }
        }
    }
}
