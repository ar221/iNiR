import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.functions as CF
import qs.modules.common.widgets

ContentPage {
    id: autostartPage
    settingsPageIndex: 8
    settingsPageName: Translation.tr("Autostart & Services")
    settingsPageIcon: "rocket_launch"

    // Refresh data when page loads
    Component.onCompleted: {
        Autostart.refreshAllUserServices()
        Autostart.refreshSystemServices()
        Autostart.refreshSystemdUnits()
        Autostart.refreshUserScripts()
    }

    // ── Helpers ────────────────────────────────────────────────────────
    // Status color helper used across sections
    function statusAccentColor(activeState, subState) {
        if (activeState === "failed" || subState === "failed")
            return Appearance.colors.colError
        if (activeState === "active" && subState === "running")
            return Appearance.m3colors.m3tertiary
        if (activeState === "active")
            return Appearance.m3colors.m3tertiary
        return Appearance.colors.colSubtext
    }

    // Sort: running first, then failed, then inactive/dead
    function sortedServices(list) {
        const copy = Array.from(list)
        copy.sort((a, b) => {
            const order = s => {
                if (s.activeState === "active" && s.subState === "running") return 0
                if (s.activeState === "active") return 1
                if (s.activeState === "failed" || s.subState === "failed") return 2
                return 3
            }
            return order(a) - order(b)
        })
        return copy
    }

    // ── Section 1: Shell Autostart ─────────────────────────────────
    SettingsCardSection {
        expanded: true
        icon: "play_circle"
        title: Translation.tr("Shell Autostart")

        SettingsGroup {
            SettingsSwitch {
                buttonIcon: "play_circle"
                text: Translation.tr("Enable autostart")
                checked: Autostart.globalEnabled
                onCheckedChanged: {
                    if (checked !== Autostart.globalEnabled)
                        Autostart.setGlobalEnabled(checked)
                }
                StyledToolTip {
                    text: Translation.tr("Launch configured entries when the shell starts")
                }
            }

            SettingsDivider {}

            // Autostart entries list
            Repeater {
                model: Autostart.entries

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    implicitHeight: entryRow.implicitHeight + 24
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colSurfaceContainerLow
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border
                    Layout.topMargin: index === 0 ? 0 : 4

                    RowLayout {
                        id: entryRow
                        anchors {
                            left: parent.left; right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: 14; rightMargin: 14
                        }
                        spacing: 10

                        MaterialSymbol {
                            text: modelData.type === "desktop" ? "apps" : "terminal"
                            iconSize: Appearance.font.pixelSize.larger
                            color: Appearance.colors.colPrimary
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            StyledText {
                                text: modelData.type === "desktop"
                                    ? (modelData.desktopId ?? Translation.tr("Unknown"))
                                    : (modelData.command ?? Translation.tr("Unknown"))
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.DemiBold
                                color: Appearance.colors.colOnLayer1
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            StyledText {
                                text: modelData.type === "desktop"
                                    ? Translation.tr("Desktop application")
                                    : Translation.tr("Shell command")
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                            }
                        }

                        Switch {
                            checked: modelData.enabled ?? false
                            onCheckedChanged: {
                                if (checked !== (modelData.enabled ?? false))
                                    Autostart.toggleConfigEntry(index, checked)
                            }
                        }

                        RippleButton {
                            implicitWidth: 32
                            implicitHeight: 32
                            buttonRadius: Appearance.rounding.small
                            colBackground: "transparent"
                            colBackgroundHover: Appearance.colors.colLayer1Hover
                            colRipple: Appearance.colors.colLayer1Active
                            onClicked: Autostart.removeConfigEntry(index)

                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                text: "delete_outline"
                                iconSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colError
                            }

                            StyledToolTip {
                                text: Translation.tr("Remove entry")
                            }
                        }
                    }
                }
            }

            // Empty state
            ColumnLayout {
                visible: Autostart.entries.length === 0
                Layout.fillWidth: true
                spacing: 8
                Layout.topMargin: 16
                Layout.bottomMargin: 16

                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    text: "playlist_add"
                    iconSize: 48
                    color: Appearance.colors.colSubtext
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Translation.tr("No autostart entries configured")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colSubtext
                }
            }

            SettingsDivider {}

            // Add entry form
            ColumnLayout {
                id: addEntryForm
                Layout.fillWidth: true
                spacing: 8
                property bool showForm: false

                // FAB-style add button
                RippleButton {
                    visible: !addEntryForm.showForm
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: fabRow.implicitWidth + 32
                    implicitHeight: 40
                    buttonRadius: 20
                    colBackground: Appearance.m3colors.m3primary
                    colBackgroundHover: Appearance.colors.colPrimaryHover
                    colRipple: Appearance.colors.colPrimaryActive
                    onClicked: addEntryForm.showForm = true

                    contentItem: RowLayout {
                        id: fabRow
                        anchors.centerIn: parent
                        spacing: 8
                        MaterialSymbol {
                            text: "add"
                            iconSize: Appearance.font.pixelSize.larger
                            color: Appearance.m3colors.m3onPrimary
                        }
                        StyledText {
                            text: Translation.tr("Add Entry")
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.DemiBold
                            color: Appearance.m3colors.m3onPrimary
                        }
                    }
                }

                // Inline form
                Rectangle {
                    visible: addEntryForm.showForm
                    Layout.fillWidth: true
                    implicitHeight: addFormCol.implicitHeight + 24
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colSurfaceContainerLow
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border

                    ColumnLayout {
                        id: addFormCol
                        anchors {
                            left: parent.left; right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: 14; rightMargin: 14
                        }
                        spacing: 10

                        // Type selector — two tab-like buttons
                        RowLayout {
                            id: entryTypeRow
                            Layout.fillWidth: true
                            spacing: 0

                            property int selectedType: 0 // 0 = command, 1 = desktop

                            RippleButton {
                                Layout.fillWidth: true
                                implicitHeight: 36
                                buttonRadius: 0
                                colBackground: entryTypeRow.selectedType === 0
                                    ? Appearance.m3colors.m3primary
                                    : Appearance.colors.colLayer1
                                colBackgroundHover: entryTypeRow.selectedType === 0
                                    ? Appearance.colors.colPrimaryHover
                                    : Appearance.colors.colLayer1Hover
                                colRipple: entryTypeRow.selectedType === 0
                                    ? Appearance.colors.colPrimaryActive
                                    : Appearance.colors.colLayer1Active
                                onClicked: entryTypeRow.selectedType = 0

                                contentItem: RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    MaterialSymbol {
                                        text: "terminal"
                                        iconSize: Appearance.font.pixelSize.small
                                        color: entryTypeRow.selectedType === 0
                                            ? Appearance.m3colors.m3onPrimary
                                            : Appearance.colors.colOnSurface
                                    }
                                    StyledText {
                                        text: Translation.tr("Command")
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: entryTypeRow.selectedType === 0
                                            ? Appearance.m3colors.m3onPrimary
                                            : Appearance.colors.colOnSurface
                                    }
                                }
                            }

                            RippleButton {
                                Layout.fillWidth: true
                                implicitHeight: 36
                                buttonRadius: 0
                                colBackground: entryTypeRow.selectedType === 1
                                    ? Appearance.m3colors.m3primary
                                    : Appearance.colors.colLayer1
                                colBackgroundHover: entryTypeRow.selectedType === 1
                                    ? Appearance.colors.colPrimaryHover
                                    : Appearance.colors.colLayer1Hover
                                colRipple: entryTypeRow.selectedType === 1
                                    ? Appearance.colors.colPrimaryActive
                                    : Appearance.colors.colLayer1Active
                                onClicked: entryTypeRow.selectedType = 1

                                contentItem: RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    MaterialSymbol {
                                        text: "apps"
                                        iconSize: Appearance.font.pixelSize.small
                                        color: entryTypeRow.selectedType === 1
                                            ? Appearance.m3colors.m3onPrimary
                                            : Appearance.colors.colOnSurface
                                    }
                                    StyledText {
                                        text: Translation.tr("Desktop App")
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: entryTypeRow.selectedType === 1
                                            ? Appearance.m3colors.m3onPrimary
                                            : Appearance.colors.colOnSurface
                                    }
                                }
                            }
                        }

                        MaterialTextField {
                            id: entryValueInput
                            Layout.fillWidth: true
                            placeholderText: entryTypeRow.selectedType === 0
                                ? Translation.tr("e.g. /usr/bin/nm-applet")
                                : Translation.tr("e.g. firefox.desktop")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.m3colors.m3onSurface
                            placeholderTextColor: Appearance.colors.colSubtext
                            background: Rectangle {
                                color: Appearance.colors.colLayer1
                                radius: Appearance.rounding.small
                                border.width: entryValueInput.activeFocus ? 2 : 1
                                border.color: entryValueInput.activeFocus ? Appearance.m3colors.m3primary : Appearance.colors.colLayer0Border
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            RippleButton {
                                Layout.fillWidth: true
                                implicitHeight: 36
                                buttonRadius: Appearance.rounding.small
                                colBackground: Appearance.m3colors.m3primary
                                colBackgroundHover: Appearance.colors.colPrimaryHover
                                colRipple: Appearance.colors.colPrimaryActive
                                enabled: entryValueInput.text.trim().length > 0
                                opacity: enabled ? 1.0 : 0.5
                                onClicked: {
                                    const type = entryTypeRow.selectedType === 0 ? "command" : "desktop"
                                    Autostart.addConfigEntry(type, entryValueInput.text.trim(), true)
                                    entryValueInput.text = ""
                                    addEntryForm.showForm = false
                                }

                                contentItem: RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    MaterialSymbol {
                                        text: "add"
                                        iconSize: Appearance.font.pixelSize.normal
                                        color: Appearance.m3colors.m3onPrimary
                                    }
                                    StyledText {
                                        text: Translation.tr("Add")
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: Appearance.m3colors.m3onPrimary
                                    }
                                }
                            }

                            RippleButton {
                                implicitWidth: 36
                                implicitHeight: 36
                                buttonRadius: Appearance.rounding.small
                                colBackground: Appearance.colors.colSurfaceContainerLow
                                colBackgroundHover: Appearance.colors.colLayer1Hover
                                colRipple: Appearance.colors.colLayer1Active
                                onClicked: {
                                    entryValueInput.text = ""
                                    addEntryForm.showForm = false
                                }

                                contentItem: MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "close"
                                    iconSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colSubtext
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Section 2: User Services ────────────────────────────────────
    SettingsCardSection {
        expanded: true
        icon: "account_tree"
        title: Translation.tr("User Services")

        SettingsGroup {
            // Filter field + refresh
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                MaterialTextField {
                    id: userServiceFilter
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Filter services...")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.m3colors.m3onSurface
                    placeholderTextColor: Appearance.colors.colSubtext
                    background: Rectangle {
                        color: Appearance.colors.colLayer1
                        radius: Appearance.rounding.small
                        border.width: userServiceFilter.activeFocus ? 2 : 1
                        border.color: userServiceFilter.activeFocus ? Appearance.m3colors.m3primary : Appearance.colors.colLayer0Border
                    }
                }

                RippleButton {
                    implicitWidth: 36
                    implicitHeight: 36
                    buttonRadius: Appearance.rounding.small
                    colBackground: Appearance.colors.colSurfaceContainerLow
                    colBackgroundHover: Appearance.colors.colLayer1Hover
                    colRipple: Appearance.colors.colLayer1Active
                    onClicked: {
                        Autostart.refreshAllUserServices()
                        Autostart.refreshSystemdUnits()
                    }

                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "refresh"
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnSurface
                    }

                    StyledToolTip {
                        text: Translation.tr("Refresh service list")
                    }
                }
            }

            // Summary bar with colored counts
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                property int totalCount: filteredUserServices.length
                property int runningCount: filteredUserServices.filter(s => s.activeState === "active" && s.subState === "running").length
                property int failedCount: filteredUserServices.filter(s => s.activeState === "failed" || s.subState === "failed").length
                property int inactiveCount: totalCount - runningCount - failedCount

                StyledText {
                    text: parent.totalCount + " " + Translation.tr("services")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                }

                // Running dot + count
                Rectangle {
                    visible: parent.runningCount > 0
                    width: 6; height: 6; radius: 3
                    color: Appearance.m3colors.m3tertiary
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 4
                }
                StyledText {
                    visible: parent.parent.children[2].visible
                    text: parent.runningCount + " " + Translation.tr("running")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.m3colors.m3tertiary
                }

                // Failed dot + count
                Rectangle {
                    visible: parent.failedCount > 0
                    width: 6; height: 6; radius: 3
                    color: Appearance.colors.colError
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 4
                }
                StyledText {
                    visible: parent.failedCount > 0
                    text: parent.failedCount + " " + Translation.tr("failed")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colError
                }

                // Inactive dot + count
                Rectangle {
                    visible: parent.inactiveCount > 0
                    width: 6; height: 6; radius: 3
                    color: Appearance.colors.colSubtext
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 4
                }
                StyledText {
                    visible: parent.inactiveCount > 0
                    text: parent.inactiveCount + " " + Translation.tr("inactive")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                }
            }

            // Filtered + sorted model
            property var filteredUserServices: {
                const filter = userServiceFilter.text.toLowerCase().trim()
                const all = Autostart.allUserServices ?? []
                let filtered = all
                if (filter.length > 0) {
                    filtered = all.filter(s => {
                        return s.name.toLowerCase().includes(filter) ||
                               (s.description ?? "").toLowerCase().includes(filter)
                    })
                }
                return autostartPage.sortedServices(filtered)
            }

            Repeater {
                model: parent.filteredUserServices

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    implicitHeight: svcCardContent.implicitHeight + 24
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colSurfaceContainerLow
                    border.width: 1
                    border.color: modelData.activeState === "failed"
                        ? CF.ColorUtils.transparentize(Appearance.colors.colError, 0.6)
                        : Appearance.colors.colLayer0Border
                    Layout.topMargin: index === 0 ? 0 : 4
                    clip: true

                    // Left accent strip
                    Rectangle {
                        id: accentStrip
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                        width: 4
                        radius: Appearance.rounding.normal
                        color: autostartPage.statusAccentColor(modelData.activeState, modelData.subState)

                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    ColumnLayout {
                        id: svcCardContent
                        anchors {
                            left: accentStrip.right; right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: 12; rightMargin: 12
                        }
                        spacing: 6

                        // Top row: name + status badge
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                StyledText {
                                    text: modelData.name.replace(/\.service$/, "")
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    font.weight: Font.Bold
                                    color: Appearance.colors.colOnLayer1
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                StyledText {
                                    visible: (modelData.description ?? "").length > 0
                                    text: modelData.description ?? ""
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colSubtext
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                    Layout.fillWidth: true
                                }
                            }

                            // Status pill badge
                            Rectangle {
                                implicitWidth: svcBadgeRow.implicitWidth + 14
                                implicitHeight: svcBadgeRow.implicitHeight + 6
                                radius: height / 2
                                color: {
                                    if (modelData.subState === "running") return CF.ColorUtils.transparentize(Appearance.m3colors.m3tertiary, 0.85)
                                    if (modelData.activeState === "failed" || modelData.subState === "failed") return CF.ColorUtils.transparentize(Appearance.colors.colError, 0.85)
                                    return CF.ColorUtils.transparentize(Appearance.colors.colSubtext, 0.88)
                                }

                                RowLayout {
                                    id: svcBadgeRow
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Rectangle {
                                        width: 6; height: 6; radius: 3
                                        color: {
                                            if (modelData.subState === "running") return Appearance.m3colors.m3tertiary
                                            if (modelData.activeState === "failed" || modelData.subState === "failed") return Appearance.colors.colError
                                            return Appearance.colors.colSubtext
                                        }
                                    }

                                    StyledText {
                                        text: modelData.subState ?? "unknown"
                                        font.pixelSize: Appearance.font.pixelSize.smallest
                                        font.weight: Font.Medium
                                        color: {
                                            if (modelData.subState === "running") return Appearance.m3colors.m3tertiary
                                            if (modelData.activeState === "failed" || modelData.subState === "failed") return Appearance.colors.colError
                                            return Appearance.colors.colSubtext
                                        }
                                    }
                                }
                            }
                        }

                        // Bottom row: enable toggle + action buttons
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            // Enable on login toggle (compact)
                            RowLayout {
                                spacing: 4

                                StyledText {
                                    text: Translation.tr("Enable")
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                    color: Appearance.colors.colSubtext
                                }

                                Switch {
                                    scale: 0.7
                                    transformOrigin: Item.Left
                                    checked: {
                                        const unit = (Autostart.systemdUnits ?? []).find(u => u.name === modelData.name)
                                        return unit ? unit.enabled : false
                                    }
                                    onCheckedChanged: {
                                        const unit = (Autostart.systemdUnits ?? []).find(u => u.name === modelData.name)
                                        const wasEnabled = unit ? unit.enabled : false
                                        if (checked !== wasEnabled)
                                            Autostart.setServiceEnabled(modelData.name, checked)
                                    }

                                    StyledToolTip {
                                        text: Translation.tr("Enable on login")
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }

                            // Action button group
                            RowLayout {
                                spacing: 2

                                // Start/Stop
                                RippleButton {
                                    implicitWidth: 30
                                    implicitHeight: 30
                                    buttonRadius: Appearance.rounding.small
                                    colBackground: modelData.activeState === "active"
                                        ? Appearance.colors.colSurfaceContainerLow
                                        : CF.ColorUtils.transparentize(Appearance.m3colors.m3tertiary, 0.85)
                                    colBackgroundHover: modelData.activeState === "active"
                                        ? Appearance.colors.colLayer1Hover
                                        : CF.ColorUtils.transparentize(Appearance.m3colors.m3tertiary, 0.7)
                                    colRipple: Appearance.colors.colLayer1Active
                                    onClicked: {
                                        if (modelData.activeState === "active")
                                            Autostart.stopService(modelData.name)
                                        else
                                            Autostart.startService(modelData.name)
                                    }

                                    contentItem: MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: modelData.activeState === "active" ? "stop" : "play_arrow"
                                        iconSize: Appearance.font.pixelSize.small
                                        color: modelData.activeState === "active"
                                            ? Appearance.colors.colOnSurface
                                            : Appearance.m3colors.m3tertiary
                                    }

                                    StyledToolTip {
                                        text: modelData.activeState === "active"
                                            ? Translation.tr("Stop service")
                                            : Translation.tr("Start service")
                                    }
                                }

                                // Restart
                                RippleButton {
                                    implicitWidth: 30
                                    implicitHeight: 30
                                    buttonRadius: Appearance.rounding.small
                                    colBackground: "transparent"
                                    colBackgroundHover: Appearance.colors.colLayer1Hover
                                    colRipple: Appearance.colors.colLayer1Active
                                    visible: modelData.activeState === "active"
                                    onClicked: Autostart.restartService(modelData.name)

                                    contentItem: MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "refresh"
                                        iconSize: Appearance.font.pixelSize.small
                                        color: Appearance.colors.colOnSurface
                                    }

                                    StyledToolTip {
                                        text: Translation.tr("Restart service")
                                    }
                                }

                                // Delete (ii-managed only)
                                RippleButton {
                                    implicitWidth: 30
                                    implicitHeight: 30
                                    visible: {
                                        const unit = (Autostart.systemdUnits ?? []).find(u => u.name === modelData.name)
                                        return unit ? unit.iiManaged : false
                                    }
                                    buttonRadius: Appearance.rounding.small
                                    colBackground: "transparent"
                                    colBackgroundHover: CF.ColorUtils.transparentize(Appearance.colors.colError, 0.85)
                                    colRipple: CF.ColorUtils.transparentize(Appearance.colors.colError, 0.7)
                                    onClicked: Autostart.deleteUserService(modelData.name)

                                    contentItem: MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "delete_outline"
                                        iconSize: Appearance.font.pixelSize.small
                                        color: Appearance.colors.colError
                                    }

                                    StyledToolTip {
                                        text: Translation.tr("Delete service (ii-managed only)")
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Empty state
            ColumnLayout {
                visible: (Autostart.allUserServices ?? []).length === 0
                Layout.fillWidth: true
                spacing: 8
                Layout.topMargin: 16
                Layout.bottomMargin: 16

                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    text: "account_tree"
                    iconSize: 48
                    color: Appearance.colors.colSubtext
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Translation.tr("No user services found")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colSubtext
                }
            }

            SettingsDivider {}

            // Create service form
            ColumnLayout {
                id: createServiceForm
                Layout.fillWidth: true
                spacing: 8
                property bool showForm: false

                // FAB-style create button
                RippleButton {
                    visible: !createServiceForm.showForm
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: createFabRow.implicitWidth + 32
                    implicitHeight: 40
                    buttonRadius: 20
                    colBackground: Appearance.m3colors.m3primary
                    colBackgroundHover: Appearance.colors.colPrimaryHover
                    colRipple: Appearance.colors.colPrimaryActive
                    onClicked: createServiceForm.showForm = true

                    contentItem: RowLayout {
                        id: createFabRow
                        anchors.centerIn: parent
                        spacing: 8
                        MaterialSymbol {
                            text: "add"
                            iconSize: Appearance.font.pixelSize.larger
                            color: Appearance.m3colors.m3onPrimary
                        }
                        StyledText {
                            text: Translation.tr("Create Service")
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.DemiBold
                            color: Appearance.m3colors.m3onPrimary
                        }
                    }
                }

                Rectangle {
                    visible: createServiceForm.showForm
                    Layout.fillWidth: true
                    implicitHeight: createFormCol.implicitHeight + 24
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colSurfaceContainerLow
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border

                    ColumnLayout {
                        id: createFormCol
                        anchors {
                            left: parent.left; right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: 14; rightMargin: 14
                        }
                        spacing: 10

                        MaterialTextField {
                            id: newServiceName
                            Layout.fillWidth: true
                            placeholderText: Translation.tr("Service name (e.g. my-daemon)")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.m3colors.m3onSurface
                            placeholderTextColor: Appearance.colors.colSubtext
                            background: Rectangle {
                                color: Appearance.colors.colLayer1
                                radius: Appearance.rounding.small
                                border.width: newServiceName.activeFocus ? 2 : 1
                                border.color: newServiceName.activeFocus ? Appearance.m3colors.m3primary : Appearance.colors.colLayer0Border
                            }
                        }

                        MaterialTextField {
                            id: newServiceDesc
                            Layout.fillWidth: true
                            placeholderText: Translation.tr("Description (optional)")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.m3colors.m3onSurface
                            placeholderTextColor: Appearance.colors.colSubtext
                            background: Rectangle {
                                color: Appearance.colors.colLayer1
                                radius: Appearance.rounding.small
                                border.width: newServiceDesc.activeFocus ? 2 : 1
                                border.color: newServiceDesc.activeFocus ? Appearance.m3colors.m3primary : Appearance.colors.colLayer0Border
                            }
                        }

                        MaterialTextField {
                            id: newServiceCommand
                            Layout.fillWidth: true
                            placeholderText: Translation.tr("Command (e.g. /usr/bin/my-daemon --flag)")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.m3colors.m3onSurface
                            placeholderTextColor: Appearance.colors.colSubtext
                            background: Rectangle {
                                color: Appearance.colors.colLayer1
                                radius: Appearance.rounding.small
                                border.width: newServiceCommand.activeFocus ? 2 : 1
                                border.color: newServiceCommand.activeFocus ? Appearance.m3colors.m3primary : Appearance.colors.colLayer0Border
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            StyledText {
                                text: Translation.tr("Kind:")
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnSurfaceVariant
                            }

                            StyledComboBox {
                                id: newServiceKind
                                Layout.fillWidth: true
                                model: [Translation.tr("Session"), Translation.tr("Tray")]
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            RippleButton {
                                Layout.fillWidth: true
                                implicitHeight: 36
                                buttonRadius: Appearance.rounding.small
                                colBackground: Appearance.m3colors.m3primary
                                colBackgroundHover: Appearance.colors.colPrimaryHover
                                colRipple: Appearance.colors.colPrimaryActive
                                enabled: newServiceName.text.trim().length > 0 && newServiceCommand.text.trim().length > 0
                                opacity: enabled ? 1.0 : 0.5
                                onClicked: {
                                    const kind = newServiceKind.currentIndex === 0 ? "session" : "tray"
                                    Autostart.createUserService(
                                        newServiceName.text.trim(),
                                        newServiceDesc.text.trim(),
                                        newServiceCommand.text.trim(),
                                        kind
                                    )
                                    newServiceName.text = ""
                                    newServiceDesc.text = ""
                                    newServiceCommand.text = ""
                                    createServiceForm.showForm = false
                                }

                                contentItem: RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    MaterialSymbol {
                                        text: "add"
                                        iconSize: Appearance.font.pixelSize.normal
                                        color: Appearance.m3colors.m3onPrimary
                                    }
                                    StyledText {
                                        text: Translation.tr("Create")
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: Appearance.m3colors.m3onPrimary
                                    }
                                }
                            }

                            RippleButton {
                                implicitWidth: 36
                                implicitHeight: 36
                                buttonRadius: Appearance.rounding.small
                                colBackground: Appearance.colors.colSurfaceContainerLow
                                colBackgroundHover: Appearance.colors.colLayer1Hover
                                colRipple: Appearance.colors.colLayer1Active
                                onClicked: {
                                    newServiceName.text = ""
                                    newServiceDesc.text = ""
                                    newServiceCommand.text = ""
                                    createServiceForm.showForm = false
                                }

                                contentItem: MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "close"
                                    iconSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colSubtext
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Section 3: System Services ──────────────────────────────────
    SettingsCardSection {
        expanded: true
        icon: "shield"
        title: Translation.tr("System Services")

        SettingsGroup {
            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("System services require administrator privileges to control. Only running services are shown.")
                color: Appearance.colors.colOnSurfaceVariant
                font.pixelSize: Appearance.font.pixelSize.small
                wrapMode: Text.WordWrap
            }

            // Filter + refresh
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                MaterialTextField {
                    id: systemServiceFilter
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Filter services...")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.m3colors.m3onSurface
                    placeholderTextColor: Appearance.colors.colSubtext
                    background: Rectangle {
                        color: Appearance.colors.colLayer1
                        radius: Appearance.rounding.small
                        border.width: systemServiceFilter.activeFocus ? 2 : 1
                        border.color: systemServiceFilter.activeFocus ? Appearance.m3colors.m3primary : Appearance.colors.colLayer0Border
                    }
                }

                RippleButton {
                    implicitWidth: 36
                    implicitHeight: 36
                    buttonRadius: Appearance.rounding.small
                    colBackground: Appearance.colors.colSurfaceContainerLow
                    colBackgroundHover: Appearance.colors.colLayer1Hover
                    colRipple: Appearance.colors.colLayer1Active
                    onClicked: Autostart.refreshSystemServices()

                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "refresh"
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnSurface
                    }

                    StyledToolTip {
                        text: Translation.tr("Refresh service list")
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("%1 running system services").arg(filteredSystemServices.length)
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }

            property var filteredSystemServices: {
                const filter = systemServiceFilter.text.toLowerCase().trim()
                const all = Autostart.systemServices ?? []
                if (filter.length === 0) return all
                return all.filter(s => {
                    return s.name.toLowerCase().includes(filter) ||
                           (s.description ?? "").toLowerCase().includes(filter)
                })
            }

            Repeater {
                model: parent.filteredSystemServices

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    implicitHeight: sysCardContent.implicitHeight + 24
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colSurfaceContainerLow
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border
                    Layout.topMargin: index === 0 ? 0 : 4
                    clip: true

                    // Left accent strip (always green — only running services shown)
                    Rectangle {
                        id: sysAccentStrip
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                        width: 4
                        radius: Appearance.rounding.normal
                        color: Appearance.m3colors.m3tertiary
                    }

                    // Lock badge — corner indicator for privileged control
                    MaterialSymbol {
                        anchors { top: parent.top; right: parent.right; topMargin: 6; rightMargin: 8 }
                        text: "admin_panel_settings"
                        iconSize: Appearance.font.pixelSize.smallest
                        color: Appearance.colors.colSubtext
                        opacity: 0.5
                    }

                    ColumnLayout {
                        id: sysCardContent
                        anchors {
                            left: sysAccentStrip.right; right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: 12; rightMargin: 12
                        }
                        spacing: 6

                        // Top row: name + description
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                StyledText {
                                    text: modelData.name.replace(/\.service$/, "")
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    font.weight: Font.Bold
                                    color: Appearance.colors.colOnLayer1
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                StyledText {
                                    visible: (modelData.description ?? "").length > 0
                                    text: modelData.description ?? ""
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colSubtext
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                    Layout.fillWidth: true
                                }
                            }

                            // Status pill
                            Rectangle {
                                implicitWidth: sysBadgeRow.implicitWidth + 14
                                implicitHeight: sysBadgeRow.implicitHeight + 6
                                radius: height / 2
                                color: CF.ColorUtils.transparentize(Appearance.m3colors.m3tertiary, 0.85)

                                RowLayout {
                                    id: sysBadgeRow
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Rectangle {
                                        width: 6; height: 6; radius: 3
                                        color: Appearance.m3colors.m3tertiary
                                    }

                                    StyledText {
                                        text: modelData.subState ?? "running"
                                        font.pixelSize: Appearance.font.pixelSize.smallest
                                        font.weight: Font.Medium
                                        color: Appearance.m3colors.m3tertiary
                                    }
                                }
                            }
                        }

                        // Bottom row: action buttons (right-aligned)
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Item { Layout.fillWidth: true }

                            // Stop button with lock
                            RippleButton {
                                implicitWidth: sysStopContent.implicitWidth + 16
                                implicitHeight: 30
                                buttonRadius: Appearance.rounding.small
                                colBackground: Appearance.colors.colLayer1
                                colBackgroundHover: Appearance.colors.colLayer1Hover
                                colRipple: Appearance.colors.colLayer1Active
                                onClicked: Autostart.stopSystemService(modelData.name)

                                contentItem: RowLayout {
                                    id: sysStopContent
                                    anchors.centerIn: parent
                                    spacing: 4
                                    MaterialSymbol {
                                        text: "lock"
                                        iconSize: Appearance.font.pixelSize.smallest
                                        color: Appearance.colors.colSubtext
                                    }
                                    StyledText {
                                        text: Translation.tr("Stop")
                                        font.pixelSize: Appearance.font.pixelSize.smallest
                                        color: Appearance.colors.colOnSurface
                                    }
                                }

                                StyledToolTip {
                                    text: Translation.tr("Requires authentication (pkexec)")
                                }
                            }

                            // Restart button with lock
                            RippleButton {
                                implicitWidth: sysRestartContent.implicitWidth + 16
                                implicitHeight: 30
                                buttonRadius: Appearance.rounding.small
                                colBackground: Appearance.colors.colLayer1
                                colBackgroundHover: Appearance.colors.colLayer1Hover
                                colRipple: Appearance.colors.colLayer1Active
                                onClicked: Autostart.restartSystemService(modelData.name)

                                contentItem: RowLayout {
                                    id: sysRestartContent
                                    anchors.centerIn: parent
                                    spacing: 4
                                    MaterialSymbol {
                                        text: "lock"
                                        iconSize: Appearance.font.pixelSize.smallest
                                        color: Appearance.colors.colSubtext
                                    }
                                    MaterialSymbol {
                                        text: "refresh"
                                        iconSize: Appearance.font.pixelSize.small
                                        color: Appearance.colors.colOnSurface
                                    }
                                }

                                StyledToolTip {
                                    text: Translation.tr("Restart (requires authentication)")
                                }
                            }
                        }
                    }
                }
            }

            // Empty state
            ColumnLayout {
                visible: (Autostart.systemServices ?? []).length === 0
                Layout.fillWidth: true
                spacing: 8
                Layout.topMargin: 16
                Layout.bottomMargin: 16

                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    text: "shield"
                    iconSize: 48
                    color: Appearance.colors.colSubtext
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Translation.tr("No system services loaded")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colSubtext
                }
            }
        }
    }

    // ── Section 4: User Scripts ──────────────────────────────────────
    SettingsCardSection {
        expanded: true
        icon: "code"
        title: Translation.tr("User Scripts")

        SettingsGroup {
            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Executable scripts in ~/.local/bin/")
                color: Appearance.colors.colOnSurfaceVariant
                font.pixelSize: Appearance.font.pixelSize.small
                wrapMode: Text.WordWrap
            }

            // Filter + refresh
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                MaterialTextField {
                    id: scriptFilter
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Filter scripts...")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.m3colors.m3onSurface
                    placeholderTextColor: Appearance.colors.colSubtext
                    background: Rectangle {
                        color: Appearance.colors.colLayer1
                        radius: Appearance.rounding.small
                        border.width: scriptFilter.activeFocus ? 2 : 1
                        border.color: scriptFilter.activeFocus ? Appearance.m3colors.m3primary : Appearance.colors.colLayer0Border
                    }
                }

                RippleButton {
                    implicitWidth: 36
                    implicitHeight: 36
                    buttonRadius: Appearance.rounding.small
                    colBackground: Appearance.colors.colSurfaceContainerLow
                    colBackgroundHover: Appearance.colors.colLayer1Hover
                    colRipple: Appearance.colors.colLayer1Active
                    onClicked: Autostart.refreshUserScripts()

                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "refresh"
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnSurface
                    }

                    StyledToolTip {
                        text: Translation.tr("Refresh script list")
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("%1 scripts").arg(filteredScripts.length)
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }

            property var filteredScripts: {
                const filter = scriptFilter.text.toLowerCase().trim()
                const all = Autostart.userScripts ?? []
                if (filter.length === 0) return all
                return all.filter(s => s.toLowerCase().includes(filter))
            }

            Repeater {
                model: parent.filteredScripts

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    implicitHeight: scriptCardContent.implicitHeight + 20
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colSurfaceContainerLow
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border
                    Layout.topMargin: index === 0 ? 0 : 4

                    RowLayout {
                        id: scriptCardContent
                        anchors {
                            left: parent.left; right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: 14; rightMargin: 10
                        }
                        spacing: 10

                        MaterialSymbol {
                            text: "description"
                            iconSize: Appearance.font.pixelSize.larger
                            color: Appearance.colors.colPrimary
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: modelData
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.family: Appearance.font.family.monospace
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnLayer1
                            elide: Text.ElideRight
                        }

                        // Compact button group
                        RowLayout {
                            spacing: 2

                            // Run button (prominent)
                            RippleButton {
                                implicitWidth: scriptRunContent.implicitWidth + 16
                                implicitHeight: 30
                                buttonRadius: Appearance.rounding.small
                                colBackground: Appearance.m3colors.m3primary
                                colBackgroundHover: Appearance.colors.colPrimaryHover
                                colRipple: Appearance.colors.colPrimaryActive
                                onClicked: {
                                    Quickshell.execDetached(["bash", "-lc", modelData])
                                }

                                contentItem: RowLayout {
                                    id: scriptRunContent
                                    anchors.centerIn: parent
                                    spacing: 4
                                    MaterialSymbol {
                                        text: "play_arrow"
                                        iconSize: Appearance.font.pixelSize.small
                                        color: Appearance.m3colors.m3onPrimary
                                    }
                                    StyledText {
                                        text: Translation.tr("Run")
                                        font.pixelSize: Appearance.font.pixelSize.smallest
                                        font.weight: Font.DemiBold
                                        color: Appearance.m3colors.m3onPrimary
                                    }
                                }
                            }

                            // Add to autostart (subtle icon)
                            RippleButton {
                                implicitWidth: 30
                                implicitHeight: 30
                                buttonRadius: Appearance.rounding.small
                                colBackground: "transparent"
                                colBackgroundHover: Appearance.colors.colLayer1Hover
                                colRipple: Appearance.colors.colLayer1Active
                                onClicked: Autostart.addConfigEntry("command", "$HOME/.local/bin/" + modelData, true)

                                contentItem: MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "add_circle_outline"
                                    iconSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colPrimary
                                }

                                StyledToolTip {
                                    text: Translation.tr("Add to shell autostart")
                                }
                            }

                            // Edit (subtle icon)
                            RippleButton {
                                implicitWidth: 30
                                implicitHeight: 30
                                buttonRadius: Appearance.rounding.small
                                colBackground: "transparent"
                                colBackgroundHover: Appearance.colors.colLayer1Hover
                                colRipple: Appearance.colors.colLayer1Active
                                onClicked: {
                                    const home = Quickshell.env("HOME")
                                    const editor = Quickshell.env("EDITOR") || "nvim"
                                    const terminal = Config.options?.apps?.terminal ?? "kitty"
                                    Quickshell.execDetached([terminal, "-e", editor, home + "/.local/bin/" + modelData])
                                }

                                contentItem: MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "edit"
                                    iconSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colOnSurface
                                }

                                StyledToolTip {
                                    text: Translation.tr("Open in editor")
                                }
                            }
                        }
                    }
                }
            }

            // Empty state
            ColumnLayout {
                visible: (Autostart.userScripts ?? []).length === 0
                Layout.fillWidth: true
                spacing: 8
                Layout.topMargin: 16
                Layout.bottomMargin: 16

                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    text: "code"
                    iconSize: 48
                    color: Appearance.colors.colSubtext
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Translation.tr("No scripts found in ~/.local/bin/")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colSubtext
                }
            }
        }
    }
}
