import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.dashboard
import qs.services

DashboardCard {
    id: root
    headerText: ""

    // Config-driven profile data
    readonly property string displayName: {
        const configured = Config.options?.dashboard?.profile?.displayName ?? ""
        return configured !== "" ? configured : root._userName
    }
    readonly property string avatarPath: Config.options?.dashboard?.profile?.avatarPath ?? ""

    // System info for subtitle template
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

    // ── Avatar ──
    Item {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 4
        implicitWidth: 72
        implicitHeight: 72

        // Soft glow behind avatar
        Rectangle {
            anchors.centerIn: avatarBg
            width: avatarBg.width + 16
            height: avatarBg.height + 16
            radius: width / 2
            color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.8)
            z: -1
        }

        // Accent-colored circle (gradient requires OpacityMask — revisit Phase 3)
        Rectangle {
            id: avatarBg
            anchors.fill: parent
            radius: width / 2
            gradient: Gradient {
                GradientStop { position: 0.0; color: Appearance.colors.colPrimary }
                GradientStop { position: 1.0; color: Appearance.colors.colTertiary }
            }

            // Avatar image (overrides gradient when loaded)
            Image {
                id: avatarImage
                anchors.fill: parent
                source: root.avatarPath !== "" ? ("file://" + root.avatarPath) : "file:///home/" + root._userName + "/.face"
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
            }

            // Fallback monogram initials
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
                font.pixelSize: 24
                font.weight: Font.Bold
                color: Qt.rgba(1, 1, 1, 0.9)
            }
        }
    }

    // ── Display name ──
    StyledText {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: root.displayName
        font.pixelSize: 18
        font.weight: Font.DemiBold
        color: Appearance.colors.colOnLayer0
    }

    // ── Subtitle ──
    StyledText {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: root.subtitle
        font.pixelSize: 11
        color: Qt.rgba(1, 1, 1, 0.35)
    }
}
