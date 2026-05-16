pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.background.widgets
import qs.services

// Command Room - read-only cockpit projection consumer for the desktop.
AbstractBackgroundWidget {
    id: root

    configEntryName: "commandRoom"

    readonly property var commandRoomConfig: configEntry
    readonly property real cardWidth: commandRoomConfig?.cardWidth ?? 460
    readonly property real cardOpacity: commandRoomConfig?.cardOpacity ?? 0.95
    readonly property int maxTasks: commandRoomConfig?.maxTasks ?? 3
    readonly property point screenPos: root.mapToItem(null, 0, 0)
    readonly property var visibleTasks: CommandRoom.openTasks.slice(0, Math.max(0, maxTasks))
    readonly property string statusLabel: CommandRoom.freshnessState.toUpperCase()
    readonly property color statusColor: {
        if (CommandRoom.freshnessState === "fresh")
            return Appearance.m3colors.m3primary
        if (CommandRoom.freshnessState === "stale")
            return Appearance.colors.colTertiary
        return Appearance.colors.colError
    }
    readonly property string ageLabel: {
        if (CommandRoom.ageMinutes < 0)
            return "no signal"
        if (CommandRoom.ageMinutes === 0)
            return "now"
        return CommandRoom.ageMinutes + "m ago"
    }

    implicitWidth: cardWidth
    implicitHeight: cardContent.implicitHeight + cardContent.anchors.margins * 2

    StyledRectangularShadow {
        target: cardBackground
        visible: !Appearance.inirEverywhere && !Appearance.auroraEverywhere
    }

    Rectangle {
        id: cardBackground
        anchors.fill: parent
        radius: Appearance.rounding.unsharpen
        color: "transparent"
        clip: true

        GlassBackground {
            anchors.fill: parent
            radius: parent.radius
            screenX: root.screenPos.x
            screenY: root.screenPos.y
            fallbackColor: ColorUtils.transparentize(Appearance.colors.colLayer0, 1.0 - root.cardOpacity)
        }

        Rectangle {
            anchors.fill: parent
            visible: !Appearance.auroraEverywhere && !Appearance.angelEverywhere
            radius: parent.radius
            color: ColorUtils.transparentize(Appearance.colors.colLayer0, 1.0 - root.cardOpacity)
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.width: 1
            border.color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.88)
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 1
            height: 6
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.7) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }

    ColumnLayout {
        id: cardContent
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            StyledText {
                text: "COMMAND ROOM"
                font.family: Appearance.font.family.monospace
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.Bold
                font.letterSpacing: 2
                color: Appearance.colors.colPrimary
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                implicitWidth: statusRow.implicitWidth + 14
                implicitHeight: statusRow.implicitHeight + 8
                radius: 3
                color: ColorUtils.transparentize(root.statusColor, 0.86)
                border.width: 1
                border.color: ColorUtils.transparentize(root.statusColor, 0.45)

                RowLayout {
                    id: statusRow
                    anchors.centerIn: parent
                    spacing: 5

                    Rectangle {
                        implicitWidth: 6
                        implicitHeight: 6
                        radius: 3
                        color: root.statusColor
                    }

                    StyledText {
                        text: root.statusLabel + " / " + root.ageLabel
                        font.family: Appearance.font.family.monospace
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.1
                        color: Appearance.colors.colOnLayer0
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.82)
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            StyledText {
                text: CommandRoom.openTaskCount + " OPEN"
                font.family: Appearance.font.family.numbers
                font.pixelSize: Appearance.font.pixelSize.larger
                font.weight: Font.Bold
                color: Appearance.colors.colOnLayer0
            }

            StyledText {
                Layout.fillWidth: true
                text: CommandRoom.generatedAt.length > 0 ? "projection / " + CommandRoom.generatedAt : Directories.shortHomePath(CommandRoom.sourcePath)
                font.family: Appearance.font.family.monospace
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.letterSpacing: 1.1
                color: Appearance.colors.colSubtext
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 7

            StyledText {
                Layout.fillWidth: true
                visible: CommandRoom.lastError.length > 0
                text: CommandRoom.lastError === "Projection missing" ? "No cockpit projection yet." : CommandRoom.lastError
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.Medium
                color: CommandRoom.lastError === "Projection missing" ? Appearance.colors.colSubtext : Appearance.colors.colError
                wrapMode: Text.WordWrap
            }

            StyledText {
                Layout.fillWidth: true
                visible: CommandRoom.lastError.length === 0 && CommandRoom.openTaskCount === 0
                text: "No open command-room tasks. The board is clear."
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.Medium
                color: Appearance.colors.colSubtext
                wrapMode: Text.WordWrap
            }

            Repeater {
                model: root.visibleTasks

                delegate: Rectangle {
                    id: taskRow
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    implicitHeight: taskContent.implicitHeight + 14
                    radius: 4
                    color: ColorUtils.transparentize(Appearance.colors.colLayer1, 0.34)
                    border.width: 1
                    border.color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.9)

                    ColumnLayout {
                        id: taskContent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 3

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 7

                            StyledText {
                                text: "#" + String(taskRow.modelData?.id ?? taskRow.index + 1)
                                font.family: Appearance.font.family.monospace
                                font.pixelSize: Appearance.font.pixelSize.smallest
                                font.weight: Font.Bold
                                color: Appearance.colors.colPrimary
                            }

                            StyledText {
                                text: String(taskRow.modelData?.priority ?? "normal").toUpperCase()
                                font.family: Appearance.font.family.monospace
                                font.pixelSize: Appearance.font.pixelSize.smallest
                                font.weight: Font.DemiBold
                                font.letterSpacing: 1.1
                                color: Appearance.colors.colTertiary
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: String(taskRow.modelData?.owner ?? "unassigned")
                                font.family: Appearance.font.family.monospace
                                font.pixelSize: Appearance.font.pixelSize.smallest
                                font.letterSpacing: 1.1
                                color: Appearance.colors.colSubtext
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: String(taskRow.modelData?.title ?? "Untitled command-room task")
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnLayer0
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }
                    }
                }
            }
        }
    }
}
