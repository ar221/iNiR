import QtQuick
import QtQuick.Layouts
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

    // Section header
    StyledText {
        text: "STORAGE"
        font.pixelSize: Appearance.font.pixelSize.smallest
        font.weight: Font.DemiBold
        font.letterSpacing: 2.0
        color: Appearance.colors.colSubtext
    }

    // Disk data model
    property var disks: []

    // Color per partition index
    readonly property var barColors: [
        Appearance.colors.colPrimary,
        Appearance.colors.colSecondary,
        Appearance.colors.colTertiary
    ]

    Process {
        id: dfProcess
        command: ["/usr/bin/df", "-B1", "/", "/mnt/hdd"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                const lines = data.trim().split("\n")
                const parsed = []
                for (let i = 1; i < lines.length; i++) {
                    const parts = lines[i].trim().split(/\s+/)
                    if (parts.length >= 6) {
                        const total = parseInt(parts[1])
                        const used = parseInt(parts[2])
                        const mount = parts[5]
                        const label = mount === "/" ? "ROOT" : mount === "/mnt/hdd" ? "HDD" : mount.split("/").pop().toUpperCase()
                        parsed.push({
                            label: label,
                            mount: mount,
                            total: total,
                            used: used,
                            percentage: total > 0 ? used / total : 0
                        })
                    }
                }
                root.disks = parsed
            }
        }
    }

    // Refresh disk stats periodically
    Timer {
        running: root.visible
        interval: 30000
        repeat: true
        triggeredOnStart: true
        onTriggered: dfProcess.running = true
    }

    Component.onCompleted: dfProcess.running = true

    // Disk bars
    Repeater {
        model: root.disks

        ColumnLayout {
            id: diskItem
            required property var modelData
            required property int index
            Layout.fillWidth: true
            spacing: 4

            readonly property color diskColor: {
                if (diskItem.modelData.percentage > 0.9)
                    return Appearance.colors.colError
                return root.barColors[diskItem.index % root.barColors.length]
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                MaterialSymbol {
                    text: diskItem.modelData.mount === "/" ? "hard_drive" : "save"
                    iconSize: 14
                    color: diskItem.diskColor
                }

                StyledText {
                    Layout.fillWidth: true
                    text: diskItem.modelData.label
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer0
                }

                StyledText {
                    text: Math.round(diskItem.modelData.percentage * 100) + "%"
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.family: Appearance.font.family.monospace
                    font.weight: Font.Medium
                    color: Appearance.colors.colSubtext
                }
            }

            // Progress bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 8
                radius: 4
                color: ColorUtils.transparentize(Appearance.colors.colSurfaceContainer, 0.3)

                Rectangle {
                    width: parent.width * diskItem.modelData.percentage
                    height: parent.height
                    radius: parent.radius
                    color: diskItem.diskColor

                    Behavior on width {
                        NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
                    }
                }
            }
        }
    }

    function formatBytes(bytes) {
        if (bytes < 1073741824) return (bytes / 1048576).toFixed(0) + " MB"
        if (bytes < 1099511627776) return (bytes / 1073741824).toFixed(1) + " GB"
        return (bytes / 1099511627776).toFixed(2) + " TB"
    }
}
