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
    accentHeader: true

    property string _kernelVersion: "..."
    property string _packageCount: "..."
    property string _gpuName: "..."

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
        command: ["/usr/bin/bash", "-c", "lspci 2>/dev/null | grep -E 'VGA compatible controller|3D controller|Display controller' | sed 's/.*\\[AMD\\/ATI\\] //; s/ (rev [0-9a-f]*)$//; s/\\[//g; s/\\]//g' | head -1"]
        stdout: SplitParser { splitMarker: ""; onRead: data => { root._gpuName = data.trim() || "Unknown" } }
    }

    Component.onCompleted: {
        kernelProc.running = true
        pkgProc.running = true
        gpuProc.running = true
    }

    // ── Key-value rows (4 glance rows) ──
    Repeater {
        model: [
            { label: "KERNEL",   value: root._kernelVersion },
            { label: "UPTIME",   value: DateTime.uptime },
            { label: "PACKAGES", value: root._packageCount },
            { label: "GPU",      value: root._gpuName }
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
                color: Appearance.mission.colGrid
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 34
                radius: Appearance.mission.radiusSmall
                color: infoRow.index % 2 === 0 ? ColorUtils.transparentize(Appearance.mission.colSurfaceRaised, 0.22) : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8

                    StyledText {
                        text: infoRow.modelData.label
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        font.family: Appearance.font.family.monospace
                        font.letterSpacing: 1.0
                        color: Appearance.mission.colTextMuted
                        Layout.preferredWidth: 74
                    }

                    StyledText {
                        text: infoRow.modelData.value
                        font.pixelSize: 13
                        font.family: Appearance.font.family.monospace
                        color: infoRow.index === 1 ? Appearance.mission.colAccent : Appearance.mission.colText
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }
    }
}
