import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects as GE
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

ColumnLayout {
    id: root

    property var configEntry: ({})

    spacing: 10

    // System info data
    property string distro: ""
    property string kernel: ""
    property string packageCount: ""

    Process {
        id: distroProc
        command: ["/usr/bin/bash", "-c", "grep '^PRETTY_NAME' /etc/os-release | cut -d'\"' -f2"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => root.distro = data.trim()
        }
    }

    Process {
        id: kernelProc
        command: ["/usr/bin/uname", "-r"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => root.kernel = data.trim()
        }
    }

    Process {
        id: pkgProc
        command: ["/usr/bin/bash", "-c", "pacman -Q | wc -l"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => root.packageCount = data.trim()
        }
    }

    Component.onCompleted: {
        distroProc.running = true
        kernelProc.running = true
        pkgProc.running = true
    }

    Timer {
        running: root.visible
        interval: 300000
        repeat: true
        onTriggered: pkgProc.running = true
    }

    // ── Top row: Avatar + Greeting + Uptime ──
    RowLayout {
        Layout.fillWidth: true
        spacing: 14

        // Avatar
        Rectangle {
            id: avatarContainer
            Layout.preferredWidth: 52
            Layout.preferredHeight: 52
            radius: 26
            color: Appearance.colors.colPrimaryContainer
            clip: true

            Image {
                id: avatarImage
                anchors.fill: parent
                source: root.configEntry.avatarPath ?? ""
                fillMode: Image.PreserveAspectCrop
                visible: false
                asynchronous: true
            }

            GE.OpacityMask {
                anchors.fill: parent
                source: avatarImage
                maskSource: Rectangle {
                    width: avatarContainer.width
                    height: avatarContainer.height
                    radius: avatarContainer.radius
                }
                visible: avatarImage.status === Image.Ready
            }

            MaterialSymbol {
                anchors.centerIn: parent
                text: "person"
                iconSize: 28
                color: Appearance.colors.colOnPrimaryContainer
                visible: avatarImage.status !== Image.Ready
            }
        }

        // Greeting + uptime
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                property string greeting: {
                    const h = new Date().getHours()
                    if (h < 6) return "Good night"
                    if (h < 12) return "Good morning"
                    if (h < 18) return "Good afternoon"
                    return "Good evening"
                }
                text: greeting + ", " + (root.configEntry.greetingName ?? "User")
                font.pixelSize: Appearance.font.pixelSize.larger
                font.family: Appearance.font.family.title
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer0
            }

            RowLayout {
                spacing: 6
                MaterialSymbol {
                    text: "schedule"
                    iconSize: 14
                    color: Appearance.colors.colSubtext
                }
                StyledText {
                    text: "Uptime: " + DateTime.uptime
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }
            }
        }
    }

    // ── System info row: distro, kernel, wm, packages ──
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        // CachyOS logo + distro name
        RowLayout {
            spacing: 6
            Image {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                source: "file:///usr/share/icons/hicolor/scalable/apps/org.cachyos.hello.svg"
                sourceSize: Qt.size(20, 20)
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }
            StyledText {
                text: root.distro || "CachyOS"
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer0
            }
        }

        // Separator dot
        Rectangle { width: 3; height: 3; radius: 1.5; color: Appearance.colors.colSubtext }

        // Kernel
        RowLayout {
            spacing: 4
            Image {
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                source: "file:///usr/share/pixmaps/archlinux-logo.svg"
                sourceSize: Qt.size(16, 16)
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }
            StyledText {
                text: root.kernel || ""
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.family: Appearance.font.family.monospace
                color: Appearance.colors.colSubtext
            }
        }
    }

    // ── Second info row: WM + packages ──
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        // WM
        RowLayout {
            spacing: 4
            MaterialSymbol {
                text: "desktop_windows"
                iconSize: 16
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: "niri"
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer0
            }
        }

        Rectangle { width: 3; height: 3; radius: 1.5; color: Appearance.colors.colSubtext }

        // Packages
        RowLayout {
            spacing: 4
            MaterialSymbol {
                text: "inventory_2"
                iconSize: 16
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: (root.packageCount || "—") + " packages"
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer0
            }
        }
    }
}
