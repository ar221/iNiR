import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

ContentPage {
    id: defaultAppsPage
    settingsPageIndex: 17
    settingsPageName: Translation.tr("Default Apps")
    settingsPageIcon: "apps"

    // ── XDG default properties ──────────────────────────────────────
    property string xdgBrowser: ""
    property string xdgFileManager: ""
    property string xdgTextEditor: ""
    property string xdgImageViewer: ""
    property string xdgVideoPlayer: ""

    Component.onCompleted: refreshXdgDefaults()

    function refreshXdgDefaults() {
        browserQuery.running = false
        fileManagerQuery.running = false
        textEditorQuery.running = false
        imageViewerQuery.running = false
        videoPlayerQuery.running = false
        browserQuery.running = true
        fileManagerQuery.running = true
        textEditorQuery.running = true
        imageViewerQuery.running = true
        videoPlayerQuery.running = true
    }

    function stripDesktop(name) {
        if (!name) return ""
        return name.replace(/\.desktop$/, "")
    }

    // ── XDG query processes ─────────────────────────────────────────
    Process {
        id: browserQuery
        command: ["/usr/bin/xdg-settings", "get", "default-web-browser"]
        stdout: SplitParser {
            onRead: data => defaultAppsPage.xdgBrowser = data.trim()
        }
    }

    Process {
        id: fileManagerQuery
        command: ["/usr/bin/xdg-mime", "query", "default", "inode/directory"]
        stdout: SplitParser {
            onRead: data => defaultAppsPage.xdgFileManager = data.trim()
        }
    }

    Process {
        id: textEditorQuery
        command: ["/usr/bin/xdg-mime", "query", "default", "text/plain"]
        stdout: SplitParser {
            onRead: data => defaultAppsPage.xdgTextEditor = data.trim()
        }
    }

    Process {
        id: imageViewerQuery
        command: ["/usr/bin/xdg-mime", "query", "default", "image/png"]
        stdout: SplitParser {
            onRead: data => defaultAppsPage.xdgImageViewer = data.trim()
        }
    }

    Process {
        id: videoPlayerQuery
        command: ["/usr/bin/xdg-mime", "query", "default", "video/mp4"]
        stdout: SplitParser {
            onRead: data => defaultAppsPage.xdgVideoPlayer = data.trim()
        }
    }

    // ── XDG set processes ───────────────────────────────────────────
    Process {
        id: xdgSetBrowserProc
        onExited: (exitCode) => {
            if (exitCode === 0) {
                browserQuery.running = false
                browserQuery.running = true
            }
        }
    }

    Process {
        id: xdgSetMimeProc
        property string category: ""
        onExited: (exitCode) => {
            if (exitCode === 0) {
                if (xdgSetMimeProc.category === "fileManager") {
                    fileManagerQuery.running = false
                    fileManagerQuery.running = true
                } else if (xdgSetMimeProc.category === "textEditor") {
                    textEditorQuery.running = false
                    textEditorQuery.running = true
                } else if (xdgSetMimeProc.category === "imageViewer") {
                    imageViewerQuery.running = false
                    imageViewerQuery.running = true
                } else if (xdgSetMimeProc.category === "videoPlayer") {
                    videoPlayerQuery.running = false
                    videoPlayerQuery.running = true
                }
            }
        }
    }

    function setXdgBrowser(desktop) {
        const val = desktop.trim()
        if (val.length === 0) return
        xdgSetBrowserProc.command = ["/usr/bin/xdg-settings", "set", "default-web-browser", val]
        xdgSetBrowserProc.running = false
        xdgSetBrowserProc.running = true
    }

    function setXdgMime(category, desktop, mimeTypes) {
        const val = desktop.trim()
        if (val.length === 0) return
        xdgSetMimeProc.category = category
        xdgSetMimeProc.command = ["/usr/bin/xdg-mime", "default", val].concat(mimeTypes)
        xdgSetMimeProc.running = false
        xdgSetMimeProc.running = true
    }

    // ── Shell app debounce timer ────────────────────────────────────
    Timer {
        id: shellAppDebounce
        interval: 500
        repeat: false
        property string pendingKey: ""
        property string pendingValue: ""
        onTriggered: {
            if (pendingKey.length > 0 && pendingValue.length > 0)
                Config.setNestedValue("apps." + pendingKey, pendingValue)
        }
    }

    function setShellApp(key, value) {
        shellAppDebounce.pendingKey = key
        shellAppDebounce.pendingValue = value
        shellAppDebounce.restart()
    }

    // ── Inline component: XDG default entry card ────────────────────
    component XdgDefaultCard: Rectangle {
        id: xdgCard
        property string icon: ""
        property string label: ""
        property string currentValue: ""
        property var applyCallback: null

        Layout.fillWidth: true
        implicitHeight: xdgCardCol.implicitHeight + 24
        radius: Appearance.rounding.normal
        color: Appearance.colors.colSurfaceContainerLow
        border.width: 1
        border.color: Appearance.colors.colLayer0Border

        ColumnLayout {
            id: xdgCardCol
            anchors {
                left: parent.left; right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: 16; rightMargin: 16
            }
            spacing: 8

            // Header row: icon + label
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                MaterialSymbol {
                    text: xdgCard.icon
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.m3colors.m3primary
                }

                StyledText {
                    text: xdgCard.label
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }
            }

            // Current value
            StyledText {
                text: Translation.tr("Current: ") + (xdgCard.currentValue.length > 0 ? defaultAppsPage.stripDesktop(xdgCard.currentValue) : Translation.tr("(not set)"))
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }

            // Input row: text field + Apply button
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                MaterialTextField {
                    id: xdgField
                    Layout.fillWidth: true
                    text: xdgCard.currentValue
                    placeholderText: Translation.tr("e.g. firefox.desktop")
                    onAccepted: {
                        if (xdgCard.applyCallback)
                            xdgCard.applyCallback(text)
                    }
                }

                RippleButton {
                    implicitWidth: applyRow.implicitWidth + 20
                    implicitHeight: 34
                    buttonRadius: Appearance.rounding.small
                    onClicked: {
                        if (xdgCard.applyCallback)
                            xdgCard.applyCallback(xdgField.text)
                    }

                    contentItem: RowLayout {
                        id: applyRow
                        anchors.centerIn: parent
                        spacing: 6

                        MaterialSymbol {
                            text: "check"
                            iconSize: 16
                            color: Appearance.m3colors.m3primary
                        }

                        StyledText {
                            text: Translation.tr("Apply")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            font.weight: Font.Medium
                            color: Appearance.m3colors.m3primary
                        }
                    }
                }
            }
        }
    }

    // ── Inline component: Shell app entry ───────────────────────────
    component ShellAppEntry: RowLayout {
        id: shellEntry
        property string icon: ""
        property string label: ""
        property string configKey: ""
        property string defaultValue: ""
        property string currentValue: ""

        Layout.fillWidth: true
        spacing: 12

        MaterialSymbol {
            text: shellEntry.icon
            iconSize: Appearance.font.pixelSize.larger
            color: Appearance.m3colors.m3primary
        }

        StyledText {
            text: shellEntry.label
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            Layout.preferredWidth: 140
        }

        MaterialTextField {
            id: shellField
            Layout.fillWidth: true
            text: shellEntry.currentValue.length > 0 ? shellEntry.currentValue : shellEntry.defaultValue
            onTextChanged: {
                defaultAppsPage.setShellApp(shellEntry.configKey, text)
            }
        }
    }

    // ═════════════════════════════════════════════════════════════════
    // Section 1: System Defaults
    // ═════════════════════════════════════════════════════════════════
    SettingsCardSection {
        expanded: true
        icon: "open_in_new"
        title: Translation.tr("System Defaults")

        SettingsGroup {
            StyledText {
                text: Translation.tr("System-wide default applications set via XDG. Enter the .desktop filename and press Apply or Enter.")
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colSubtext
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                Layout.bottomMargin: 4
            }

            XdgDefaultCard {
                icon: "language"
                label: Translation.tr("Web Browser")
                currentValue: defaultAppsPage.xdgBrowser
                applyCallback: (val) => defaultAppsPage.setXdgBrowser(val)
            }

            XdgDefaultCard {
                icon: "folder"
                label: Translation.tr("File Manager")
                currentValue: defaultAppsPage.xdgFileManager
                applyCallback: (val) => defaultAppsPage.setXdgMime("fileManager", val, ["inode/directory"])
            }

            XdgDefaultCard {
                icon: "edit_note"
                label: Translation.tr("Text Editor")
                currentValue: defaultAppsPage.xdgTextEditor
                applyCallback: (val) => defaultAppsPage.setXdgMime("textEditor", val, ["text/plain"])
            }

            XdgDefaultCard {
                icon: "image"
                label: Translation.tr("Image Viewer")
                currentValue: defaultAppsPage.xdgImageViewer
                applyCallback: (val) => defaultAppsPage.setXdgMime("imageViewer", val, ["image/png", "image/jpeg", "image/gif", "image/webp", "image/svg+xml"])
            }

            XdgDefaultCard {
                icon: "movie"
                label: Translation.tr("Video Player")
                currentValue: defaultAppsPage.xdgVideoPlayer
                applyCallback: (val) => defaultAppsPage.setXdgMime("videoPlayer", val, ["video/mp4", "video/webm", "video/x-matroska", "video/avi"])
            }
        }
    }

    // ═════════════════════════════════════════════════════════════════
    // Section 2: Shell Apps
    // ═════════════════════════════════════════════════════════════════
    SettingsCardSection {
        expanded: true
        icon: "apps"
        title: Translation.tr("Shell Apps")

        SettingsGroup {
            StyledText {
                text: Translation.tr("Applications used by the shell for quick actions and integrations. Changes apply automatically.")
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colSubtext
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                Layout.bottomMargin: 4
            }

            ShellAppEntry {
                icon: "terminal"
                label: Translation.tr("Terminal")
                configKey: "terminal"
                defaultValue: "kitty"
                currentValue: Config.options?.apps?.terminal ?? ""
            }

            SettingsDivider {}

            ShellAppEntry {
                icon: "monitoring"
                label: Translation.tr("Task Manager")
                configKey: "taskManager"
                defaultValue: "missioncenter"
                currentValue: Config.options?.apps?.taskManager ?? ""
            }

            SettingsDivider {}

            ShellAppEntry {
                icon: "tune"
                label: Translation.tr("Volume Mixer")
                configKey: "volumeMixer"
                defaultValue: "pavucontrol"
                currentValue: Config.options?.apps?.volumeMixer ?? ""
            }

            SettingsDivider {}

            ShellAppEntry {
                icon: "bluetooth"
                label: Translation.tr("Bluetooth Manager")
                configKey: "bluetooth"
                defaultValue: "blueman-manager"
                currentValue: Config.options?.apps?.bluetooth ?? ""
            }

            SettingsDivider {}

            ShellAppEntry {
                icon: "wifi"
                label: Translation.tr("Network Manager")
                configKey: "network"
                defaultValue: "nm-connection-editor"
                currentValue: Config.options?.apps?.network ?? ""
            }

            SettingsDivider {}

            ShellAppEntry {
                icon: "forum"
                label: Translation.tr("Discord Client")
                configKey: "discord"
                defaultValue: "discord"
                currentValue: Config.options?.apps?.discord ?? ""
            }

            SettingsDivider {}

            ShellAppEntry {
                icon: "system_update"
                label: Translation.tr("Update Command")
                configKey: "update"
                defaultValue: "kitty -e arch-update"
                currentValue: Config.options?.apps?.update ?? ""
            }
        }
    }

    // ═════════════════════════════════════════════════════════════════
    // Section 3: Quick Actions
    // ═════════════════════════════════════════════════════════════════
    SettingsCardSection {
        expanded: false
        icon: "bolt"
        title: Translation.tr("Quick Actions")

        SettingsGroup {
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                RippleButton {
                    implicitWidth: detectRow.implicitWidth + 28
                    implicitHeight: 40
                    buttonRadius: Appearance.rounding.small

                    onClicked: defaultAppsPage.refreshXdgDefaults()

                    contentItem: RowLayout {
                        id: detectRow
                        anchors.centerIn: parent
                        spacing: 8

                        MaterialSymbol {
                            text: "refresh"
                            iconSize: 18
                            color: Appearance.m3colors.m3primary
                        }

                        StyledText {
                            text: Translation.tr("Detect defaults")
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Medium
                            color: Appearance.m3colors.m3primary
                        }
                    }
                }

                RippleButton {
                    implicitWidth: resetRow.implicitWidth + 28
                    implicitHeight: 40
                    buttonRadius: Appearance.rounding.small

                    onClicked: {
                        Config.setNestedValue("apps.terminal", "kitty")
                        Config.setNestedValue("apps.taskManager", "missioncenter")
                        Config.setNestedValue("apps.volumeMixer", "pavucontrol")
                        Config.setNestedValue("apps.bluetooth", "blueman-manager")
                        Config.setNestedValue("apps.network", "nm-connection-editor")
                        Config.setNestedValue("apps.networkEthernet", "nm-connection-editor")
                        Config.setNestedValue("apps.discord", "discord")
                        Config.setNestedValue("apps.update", "kitty -e arch-update")
                    }

                    contentItem: RowLayout {
                        id: resetRow
                        anchors.centerIn: parent
                        spacing: 8

                        MaterialSymbol {
                            text: "restart_alt"
                            iconSize: 18
                            color: Appearance.colors.colError
                        }

                        StyledText {
                            text: Translation.tr("Reset shell apps to defaults")
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Medium
                            color: Appearance.colors.colError
                        }
                    }
                }
            }
        }
    }
}
