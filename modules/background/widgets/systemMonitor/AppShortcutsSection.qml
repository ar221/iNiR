pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

ColumnLayout {
    id: root

    property var configEntry: ({})
    property bool editMode: false

    // Default app list
    readonly property var defaultApps: [
        { icon: "org.kde.dolphin", exec: "dolphin", name: "Dolphin" },
        { icon: "firefox", exec: "firefox", name: "Firefox" },
        { icon: "kitty", exec: "kitty", name: "Kitty" },
        { icon: "codium", exec: "codium", name: "VSCodium" },
        { icon: "vesktop", exec: "vesktop", name: "Vesktop" },
        { icon: "steam", exec: "steam", name: "Steam" },
        { icon: "com.obsproject.Studio", exec: "obs", name: "OBS" },
        { icon: "org.kde.kate", exec: "kate", name: "Kate" },
        { icon: "gimp", exec: "gimp", name: "GIMP" },
        { icon: "vlc", exec: "vlc", name: "VLC" },
        { icon: "thunderbird", exec: "thunderbird", name: "Thunderbird" },
        { icon: "spotify-client", exec: "spotify-launcher", name: "Spotify" }
    ]

    property var apps: configEntry.appShortcuts ?? defaultApps

    // App search
    property bool showSearch: false
    property string searchQuery: ""
    property var searchResults: []

    spacing: 6

    // ── Header row: edit button ──
    RowLayout {
        Layout.fillWidth: true
        spacing: 4

        Item { Layout.fillWidth: true }

        RippleButton {
            implicitWidth: 28; implicitHeight: 28
            buttonRadius: 14
            colBackground: root.editMode
                ? ColorUtils.transparentize(Appearance.colors.colPrimary, 0.8)
                : "transparent"
            colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.85)
            onClicked: {
                root.editMode = !root.editMode
                if (!root.editMode) root.showSearch = false
            }
            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                text: root.editMode ? "done" : "edit"
                iconSize: 16
                color: root.editMode
                    ? Appearance.colors.colPrimary
                    : Appearance.colors.colSubtext
            }
        }
    }

    // ── App grid ──
    GridLayout {
        Layout.alignment: Qt.AlignHCenter
        columns: 6
        rowSpacing: 10
        columnSpacing: 10

        Repeater {
            model: root.apps

            Item {
                id: appItem
                required property var modelData
                required property int index

                implicitWidth: 42
                implicitHeight: 42

                // Wiggle animation in edit mode
                SequentialAnimation on rotation {
                    running: root.editMode
                    loops: Animation.Infinite
                    NumberAnimation { from: -1.5; to: 1.5; duration: 200; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 1.5; to: -1.5; duration: 200; easing.type: Easing.InOutSine }
                }
                rotation: root.editMode ? 0 : 0

                // Icon background
                Rectangle {
                    anchors.fill: parent
                    radius: Appearance.rounding.small
                    color: appMouse.containsMouse
                        ? ColorUtils.transparentize(Appearance.colors.colSurfaceContainer, 0.3)
                        : ColorUtils.transparentize(Appearance.colors.colSurfaceContainer, 0.5)
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                // Themed icon
                Image {
                    id: iconImg
                    anchors.centerIn: parent
                    width: 26; height: 26
                    sourceSize: Qt.size(26, 26)
                    source: Quickshell.iconPath(appItem.modelData.icon ?? "", "")
                    visible: status === Image.Ready
                    fillMode: Image.PreserveAspectFit
                }

                // Fallback
                MaterialSymbol {
                    anchors.centerIn: parent
                    visible: iconImg.status !== Image.Ready
                    text: "apps"
                    iconSize: 22
                    color: Appearance.colors.colOnLayer0
                }

                MouseArea {
                    id: appMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.editMode) return
                        launchProc.command = ["/usr/bin/bash", "-c",
                            "nohup " + (appItem.modelData.exec ?? "") + " >/dev/null 2>&1 &"
                        ]
                        launchProc.running = true
                    }
                }

                Process { id: launchProc }

                StyledToolTip {
                    visible: appMouse.containsMouse && !root.editMode
                    text: appItem.modelData.name ?? appItem.modelData.icon ?? ""
                }

                // Remove badge (edit mode)
                Rectangle {
                    visible: root.editMode
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: -4
                    width: 18; height: 18; radius: 9
                    color: Appearance.colors.colError
                    z: 10

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "close"
                        iconSize: 12
                        color: Appearance.colors.colOnError ?? "#fff"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.removeApp(appItem.index)
                    }
                }
            }
        }

        // Add button (edit mode only)
        Item {
            visible: root.editMode
            implicitWidth: 42
            implicitHeight: 42

            Rectangle {
                anchors.fill: parent
                radius: Appearance.rounding.small
                color: addMouse.containsMouse
                    ? ColorUtils.transparentize(Appearance.colors.colPrimary, 0.7)
                    : "transparent"
                border.width: 2
                border.color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.5)
                border.pixelAligned: true

                Behavior on color { ColorAnimation { duration: 150 } }
            }

            MaterialSymbol {
                anchors.centerIn: parent
                text: "add"
                iconSize: 22
                color: Appearance.colors.colPrimary
            }

            MouseArea {
                id: addMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.showSearch = !root.showSearch
                    if (root.showSearch) {
                        root.searchQuery = ""
                        root.searchResults = []
                        searchInput.forceActiveFocus()
                    }
                }
            }
        }
    }

    // ── Search panel (edit mode) ──
    ColumnLayout {
        visible: root.showSearch && root.editMode
        Layout.fillWidth: true
        spacing: 6

        // Search input
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            radius: Appearance.rounding.small
            color: ColorUtils.transparentize(Appearance.colors.colSurfaceContainer, 0.3)
            border.width: 1
            border.color: searchInput.activeFocus
                ? Appearance.colors.colPrimary
                : ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.85)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 6

                MaterialSymbol {
                    text: "search"
                    iconSize: 16
                    color: Appearance.colors.colSubtext
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.family: Appearance.font.family.main
                    color: Appearance.colors.colOnLayer0
                    clip: true
                    onTextChanged: {
                        root.searchQuery = text
                        if (text.length >= 2) searchTimer.restart()
                        else root.searchResults = []
                    }
                }

                // Placeholder
                StyledText {
                    visible: searchInput.text === ""
                    text: "Search apps..."
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                    anchors.left: parent.children[1].left
                }
            }
        }

        // Search timer (debounce)
        Timer {
            id: searchTimer
            interval: 300
            onTriggered: searchProc.running = true
        }

        // Search for .desktop files
        Process {
            id: searchProc
            command: ["/usr/bin/bash", "-c",
                "grep -rlm 20 -i '" + root.searchQuery.replace(/'/g, "") + "' /usr/share/applications/ ~/.local/share/applications/ 2>/dev/null | head -20 | while read f; do " +
                "name=$(grep -m1 '^Name=' \"$f\" | cut -d= -f2); " +
                "icon=$(grep -m1 '^Icon=' \"$f\" | cut -d= -f2); " +
                "exec=$(grep -m1 '^Exec=' \"$f\" | cut -d= -f2 | sed 's/ %[fFuUdDnNickvm]//g'); " +
                "nodisplay=$(grep -m1 '^NoDisplay=' \"$f\" | cut -d= -f2); " +
                "[ \"$nodisplay\" = \"true\" ] && continue; " +
                "[ -n \"$name\" ] && echo \"$icon||$exec||$name\"; " +
                "done | sort -t'|' -k5 -u | head -12"
            ]
            stdout: SplitParser {
                splitMarker: ""
                onRead: data => {
                    const results = []
                    for (const line of data.trim().split("\n")) {
                        if (!line) continue
                        const parts = line.split("||")
                        if (parts.length >= 3) {
                            results.push({
                                icon: parts[0].trim(),
                                exec: parts[1].trim(),
                                name: parts[2].trim()
                            })
                        }
                    }
                    root.searchResults = results
                }
            }
        }

        // Results list
        ColumnLayout {
            visible: root.searchResults.length > 0
            Layout.fillWidth: true
            spacing: 2

            Repeater {
                model: root.searchResults

                Rectangle {
                    id: resultItem
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    radius: Appearance.rounding.small
                    color: resultMouse.containsMouse
                        ? ColorUtils.transparentize(Appearance.colors.colSurfaceContainer, 0.3)
                        : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        Image {
                            id: resultIcon
                            width: 22; height: 22
                            sourceSize: Qt.size(22, 22)
                            source: Quickshell.iconPath(resultItem.modelData.icon ?? "", "")
                            visible: status === Image.Ready
                            fillMode: Image.PreserveAspectFit
                        }
                        MaterialSymbol {
                            visible: resultIcon.status !== Image.Ready
                            text: "apps"
                            iconSize: 20
                            color: Appearance.colors.colSubtext
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: resultItem.modelData.name ?? ""
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnLayer0
                            elide: Text.ElideRight
                        }

                        StyledText {
                            text: resultItem.modelData.exec ?? ""
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            font.family: Appearance.font.family.monospace
                            color: Appearance.colors.colSubtext
                            elide: Text.ElideRight
                            Layout.maximumWidth: 100
                        }

                        MaterialSymbol {
                            text: "add_circle"
                            iconSize: 18
                            color: Appearance.colors.colPrimary
                        }
                    }

                    MouseArea {
                        id: resultMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.addApp(resultItem.modelData)
                            root.showSearch = false
                            searchInput.text = ""
                        }
                    }
                }
            }
        }

        // No results
        StyledText {
            visible: root.searchQuery.length >= 2 && root.searchResults.length === 0 && !searchProc.running
            Layout.alignment: Qt.AlignHCenter
            text: "No apps found"
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colSubtext
        }
    }

    // ── Persistence helpers ──
    function removeApp(index) {
        const list = JSON.parse(JSON.stringify(root.apps))
        list.splice(index, 1)
        root.configEntry.appShortcuts = list
    }

    function addApp(appData) {
        // Avoid duplicates
        for (const existing of root.apps) {
            if (existing.exec === appData.exec) return
        }
        const list = JSON.parse(JSON.stringify(root.apps))
        list.push({
            icon: appData.icon ?? "",
            exec: appData.exec ?? "",
            name: appData.name ?? ""
        })
        root.configEntry.appShortcuts = list
    }
}
