import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root

    property var configEntry: ({})

    implicitHeight: pillFlow.implicitHeight
    implicitWidth: pillFlow.implicitWidth

    // Data properties
    property string distro: ""
    property string kernel: ""
    property string packageCount: ""
    property string wmName: "niri"

    // Fetch system info on load
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

    // Refresh package count periodically (packages change rarely)
    Timer {
        running: root.visible
        interval: 300000
        repeat: true
        onTriggered: pkgProc.running = true
    }

    Flow {
        id: pillFlow
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 6

        InfoPill {
            icon: "deployed_code"
            text: root.distro
            visible: root.distro !== ""
        }

        InfoPill {
            icon: "memory"
            text: root.kernel
            visible: root.kernel !== ""
        }

        InfoPill {
            icon: "desktop_windows"
            text: root.wmName
        }

        InfoPill {
            icon: "inventory_2"
            text: root.packageCount + " pkgs"
            visible: root.packageCount !== ""
        }

        InfoPill {
            icon: "dns"
            text: Qt.resolvedUrl("").length > 0 ? "" : ""
            visible: false // hostname fetched below
        }
    }

    component InfoPill: Rectangle {
        property string icon: ""
        property string text: ""

        width: pillContent.implicitWidth + 14
        height: 26
        radius: 13
        color: ColorUtils.transparentize(Appearance.colors.colSurfaceContainer, 0.4)

        RowLayout {
            id: pillContent
            anchors.centerIn: parent
            spacing: 4

            MaterialSymbol {
                text: parent.parent.icon
                iconSize: 13
                color: Appearance.colors.colPrimary
            }

            StyledText {
                text: parent.parent.text
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colOnLayer0
            }
        }
    }
}
