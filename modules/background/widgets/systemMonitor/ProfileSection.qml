import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

Item {
    id: root

    property var configEntry: ({})

    implicitWidth: profileRow.implicitWidth
    implicitHeight: profileRow.implicitHeight
    Layout.fillWidth: true

    // Centered horizontal: logo left, labels right
    RowLayout {
        id: profileRow
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 14

        // Distro logo
        Image {
            id: distroLogo
            Layout.alignment: Qt.AlignVCenter
            source: "file:///usr/share/icons/hicolor/scalable/apps/org.cachyos.hello.svg"
            sourceSize: Qt.size(52, 52)
            width: 52; height: 52
            fillMode: Image.PreserveAspectFit
            visible: status === Image.Ready
        }

        // Fallback icon
        MaterialSymbol {
            Layout.alignment: Qt.AlignVCenter
            visible: distroLogo.status !== Image.Ready
            text: "deployed_code"
            iconSize: 52
            color: Appearance.colors.colPrimary
        }

        // Labels column
        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 3

            RowLayout {
                spacing: 6
                MaterialSymbol { text: "computer"; iconSize: 14; color: Appearance.colors.colPrimary }
                StyledText {
                    text: "os"
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: osName
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer0
                }
            }

            RowLayout {
                spacing: 6
                MaterialSymbol { text: "desktop_windows"; iconSize: 14; color: Appearance.colors.colPrimary }
                StyledText {
                    text: "wm"
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: wmName
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer0
                }
            }

            RowLayout {
                spacing: 6
                MaterialSymbol { text: "terminal"; iconSize: 14; color: Appearance.colors.colPrimary }
                StyledText {
                    text: "sh"
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: shellName
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer0
                }
            }
        }
    }

    // Dynamic info
    property string osName: "..."
    property string wmName: "..."
    property string shellName: "..."

    Process {
        id: osProc
        command: ["/usr/bin/bash", "-c", "grep -oP '(?<=^NAME=).+' /etc/os-release | tr -d '\"'"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => { root.osName = data.trim() || "Linux" }
        }
    }

    Process {
        id: wmProc
        command: ["/usr/bin/bash", "-c", "echo $XDG_CURRENT_DESKTOP"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => { root.wmName = data.trim() || "niri" }
        }
    }

    Process {
        id: shProc
        command: ["/usr/bin/bash", "-c", "basename $SHELL"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => { root.shellName = data.trim() || "fish" }
        }
    }

    Component.onCompleted: {
        osProc.running = true
        wmProc.running = true
        shProc.running = true
    }
}
