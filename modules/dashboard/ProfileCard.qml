import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.dashboard
import qs.services

// Identity strip — lean operator badge at the top of the left column.
Rectangle {
    id: root

    // Layout contract: fixed height so the strip is always a stable anchor
    Layout.fillWidth: true
    implicitHeight: 72
    radius: Appearance.mission.radiusLarge
    color: Appearance.mission.colPanel
    border.width: Appearance.mission.borderWidth
    border.color: Appearance.mission.colBorderSubtle
    clip: true

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 1
        color: Appearance.mission.colBorderHot
    }

    // Config-driven profile data
    readonly property string displayName: {
        const configured = Config.options?.dashboard?.profile?.displayName ?? ""
        const raw = configured !== "" ? configured : root._userName
        return raw.replace(/\b\w/g, c => c.toUpperCase())
    }
    readonly property string avatarPath: Config.options?.dashboard?.profile?.avatarPath ?? ""

    property string _userName: "user"
    property string _hostName: "host"
    property string _wmName: "niri"
    property string _shellName: "fish"

    readonly property string subtitle: {
        const template = Config.options?.dashboard?.profile?.subtitle ?? "{user}@{hostname} · {wm} · {shell}"
        return template
            .replace("{user}", root._userName)
            .replace("{hostname}", root._hostName)
            .replace("{wm}", root._wmName)
            .replace("{shell}", root._shellName)
    }

    Process {
        id: userProc
        command: ["/usr/bin/whoami"]
        stdout: SplitParser { splitMarker: ""; onRead: data => { root._userName = data.trim() } }
    }
    Process {
        id: hostProc
        command: ["/usr/bin/hostname"]
        stdout: SplitParser { splitMarker: ""; onRead: data => { root._hostName = data.trim() } }
    }
    Process {
        id: wmProc
        command: ["/usr/bin/bash", "-c", "echo $XDG_CURRENT_DESKTOP"]
        stdout: SplitParser { splitMarker: ""; onRead: data => { root._wmName = data.trim() || "niri" } }
    }
    Process {
        id: shellProc
        command: ["/usr/bin/bash", "-c", "basename $SHELL"]
        stdout: SplitParser { splitMarker: ""; onRead: data => { root._shellName = data.trim() || "fish" } }
    }
    Component.onCompleted: {
        userProc.running = true
        hostProc.running = true
        wmProc.running = true
        shellProc.running = true
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // ── Avatar 40×40 ──
        Item {
            implicitWidth: 40
            implicitHeight: 40

            Rectangle {
                id: avatarBg
                anchors.fill: parent
                radius: width / 2
                color: Appearance.mission.colAccentSurface
                border.width: 1
                border.color: Appearance.mission.colBorderHot

                Image {
                    id: avatarImage
                    anchors.fill: parent
                    // Only load explicit configured avatar path; otherwise show monogram fallback.
                    source: root.avatarPath !== "" ? ("file://" + root.avatarPath) : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                    layer.enabled: true
                    layer.effect: null
                }

                // Fallback monogram
                StyledText {
                    anchors.centerIn: parent
                    visible: avatarImage.status !== Image.Ready
                    text: {
                        const name = root.displayName
                        if (name.length === 0) return "?"
                        const parts = name.split(" ")
                        if (parts.length >= 2) return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase()
                        return name.substring(0, 2).toUpperCase()
                    }
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    font.family: Appearance.font.family.monospace
                    color: Appearance.mission.colAccent
                }
            }
        }

        // ── Name + subtitle stack ──
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                Layout.fillWidth: true
                text: root.displayName
                font.pixelSize: 18
                font.weight: Font.DemiBold
                color: Appearance.mission.colText
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: root.subtitle
                font.pixelSize: 11
                font.family: Appearance.font.family.monospace
                color: Appearance.mission.colTextMuted
                elide: Text.ElideRight
            }
        }

        Rectangle {
            Layout.preferredWidth: 46
            Layout.preferredHeight: 22
            Layout.alignment: Qt.AlignVCenter
            radius: Appearance.mission.radiusSmall
            color: Appearance.mission.colSurfaceRaised
            border.width: 1
            border.color: Appearance.mission.colBorderSubtle

            StyledText {
                anchors.centerIn: parent
                text: "OPS"
                font.pixelSize: 9
                font.weight: Font.Bold
                font.family: Appearance.font.family.monospace
                font.letterSpacing: 1.1
                color: Appearance.mission.colAccentMuted
            }
        }
    }
}
