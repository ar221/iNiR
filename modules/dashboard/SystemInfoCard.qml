pragma ComponentBehavior: Bound
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
    headerText: "System"

    property string _osName: "..."
    property string _kernelVersion: "..."
    property string _packageCount: "..."
    property string _gpuName: "..."

    Process {
        id: osProc
        command: ["/usr/bin/bash", "-c", "grep -oP '(?<=^NAME=).+' /etc/os-release | tr -d '\"'"]
        stdout: SplitParser { splitMarker: ""; onRead: data => { root._osName = data.trim() || "Linux" } }
    }
    Process {
        id: kernelProc
        command: ["/usr/bin/uname", "-r"]
        stdout: SplitParser { splitMarker: ""; onRead: data => { root._kernelVersion = data.trim() } }
    }
    Process {
        id: pkgProc
        command: ["/usr/bin/bash", "-c", "pacman -Q 2>/dev/null | wc -l"]
        stdout: SplitParser { splitMarker: ""; onRead: data => { root._packageCount = data.trim() } }
    }
    Process {
        id: gpuProc
        command: ["/usr/bin/bash", "-c", "lspci 2>/dev/null | grep -i 'vga\\|3d' | sed 's/.*: //' | head -1 | cut -c1-40"]
        stdout: SplitParser { splitMarker: ""; onRead: data => { root._gpuName = data.trim() || "Unknown" } }
    }

    Component.onCompleted: {
        osProc.running = true
        kernelProc.running = true
        pkgProc.running = true
        gpuProc.running = true
    }

    // ── Key-value rows ──
    Repeater {
        model: [
            { label: "UPTIME", value: DateTime.uptime },
            { label: "KERNEL", value: root._kernelVersion },
            { label: "PACKAGES", value: root._packageCount },
            { label: "SHELL", value: "fish" },
            { label: "GPU", value: root._gpuName },
            { label: "WM", value: "niri" }
        ]

        ColumnLayout {
            id: infoRow
            required property var modelData
            required property int index
            Layout.fillWidth: true
            spacing: 0

            // Separator (skip for first item)
            Rectangle {
                visible: infoRow.index > 0
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Qt.rgba(1, 1, 1, 0.04)
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                Layout.bottomMargin: 6
                spacing: 8

                StyledText {
                    text: infoRow.modelData.label
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.5
                    color: Qt.rgba(1, 1, 1, 0.3)
                    Layout.preferredWidth: 74
                }

                StyledText {
                    text: infoRow.modelData.value
                    font.pixelSize: 13
                    color: Qt.rgba(1, 1, 1, 0.7)
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}
