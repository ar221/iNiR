import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

/**
 * Compact iNiR shell update indicator for the bar.
 * Shows when a new version is available in the git repo.
 * Follows TimerIndicator pattern for global style support.
 */
MouseArea {
    id: root

    visible: ShellUpdates.showUpdate
    implicitWidth: visible ? pill.width : 0
    implicitHeight: Appearance.sizes.barHeight

    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    readonly property color accentColor: Appearance.inirEverywhere ? (Appearance.inir?.colAccent ?? Appearance.m3colors.m3primary)
        : Appearance.auroraEverywhere ? (Appearance.aurora?.colAccent ?? Appearance.m3colors.m3primary)
        : Appearance.m3colors.m3primary

    readonly property color textColor: {
        if (Appearance.inirEverywhere) return Appearance.inir?.colText ?? Appearance.colors.colOnLayer1
        if (Appearance.auroraEverywhere) return Appearance.aurora?.colText ?? Appearance.colors.colOnLayer1
        return Appearance.colors.colOnLayer1
    }

    onClicked: (mouse) => {
        if (mouse.button === Qt.RightButton) {
            ShellUpdates.dismiss()
        } else {
            ShellUpdates.performUpdate()
        }
    }

    // Background pill (follows TimerIndicator pattern)
    Rectangle {
        id: pill
        anchors.centerIn: parent
        width: contentRow.implicitWidth + 12
        height: contentRow.implicitHeight + 8
        radius: height / 2
        scale: root.pressed ? 0.95 : 1.0
        color: {
            if (root.pressed) {
                if (Appearance.inirEverywhere) return Appearance.inir.colLayer2Active
                if (Appearance.auroraEverywhere) return Appearance.aurora.colSubSurfaceActive
                return Appearance.colors.colLayer1Active
            }
            if (root.containsMouse) {
                if (Appearance.inirEverywhere) return Appearance.inir.colLayer1Hover
                if (Appearance.auroraEverywhere) return Appearance.aurora.colSubSurface
                return Appearance.colors.colLayer1Hover
            }
            if (Appearance.inirEverywhere) return ColorUtils.transparentize(Appearance.inir?.colAccent ?? Appearance.m3colors.m3primary, 0.85)
            if (Appearance.auroraEverywhere) return ColorUtils.transparentize(Appearance.aurora?.colAccent ?? Appearance.m3colors.m3primary, 0.85)
            return Appearance.colors.colPrimaryContainer
        }

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
        Behavior on scale {
            NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
        }
    }

    RowLayout {
        id: contentRow
        anchors.centerIn: pill
        spacing: 4

        MaterialSymbol {
            text: "system_update_alt"
            iconSize: Appearance.font.pixelSize.normal
            color: root.accentColor
            Layout.alignment: Qt.AlignVCenter
        }

        StyledText {
            text: ShellUpdates.commitsBehind > 0
                ? ShellUpdates.commitsBehind.toString()
                : "!"
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.weight: Font.DemiBold
            color: root.textColor
            Layout.alignment: Qt.AlignVCenter
        }
    }

    // Hover popup with update details
    StyledPopup {
        id: updatePopup
        hoverTarget: root

        ColumnLayout {
            spacing: 6

            // Header
            RowLayout {
                spacing: 8

                MaterialSymbol {
                    text: "system_update_alt"
                    iconSize: Appearance.font.pixelSize.larger
                    color: root.accentColor
                }

                StyledText {
                    text: Translation.tr("iNiR Update Available")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnSurfaceVariant
                }
            }

            // Version info
            ColumnLayout {
                spacing: 2

                RowLayout {
                    StyledText {
                        text: Translation.tr("Current:")
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        color: Appearance.colors.colSubtext
                    }
                    Item { Layout.fillWidth: true }
                    StyledText {
                        text: ShellUpdates.localCommit || "\u2014"
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.family: Appearance.font.family.monospace
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                }

                RowLayout {
                    StyledText {
                        text: Translation.tr("Available:")
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        color: Appearance.colors.colSubtext
                    }
                    Item { Layout.fillWidth: true }
                    StyledText {
                        text: ShellUpdates.remoteCommit || "\u2014"
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.family: Appearance.font.family.monospace
                        font.weight: Font.DemiBold
                        color: root.accentColor
                    }
                }

                RowLayout {
                    StyledText {
                        text: Translation.tr("Commits behind:")
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        color: Appearance.colors.colSubtext
                    }
                    Item { Layout.fillWidth: true }
                    StyledText {
                        text: ShellUpdates.commitsBehind.toString()
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.weight: Font.Bold
                        color: ShellUpdates.commitsBehind > 10
                            ? Appearance.m3colors.m3error
                            : root.accentColor
                    }
                }
            }

            // Latest commit message
            StyledText {
                Layout.fillWidth: true
                Layout.maximumWidth: 240
                visible: ShellUpdates.latestMessage.length > 0
                text: ShellUpdates.latestMessage
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.family: Appearance.font.family.monospace
                color: Appearance.colors.colSubtext
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.WordWrap
            }

            // Error message
            StyledText {
                Layout.fillWidth: true
                Layout.maximumWidth: 240
                visible: ShellUpdates.lastError.length > 0
                text: ShellUpdates.lastError
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.m3colors.m3error
                wrapMode: Text.WordWrap
            }

            // Hint
            StyledText {
                Layout.fillWidth: true
                Layout.maximumWidth: 240
                text: Translation.tr("Click to update • Right-click to dismiss")
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colSubtext
                opacity: 0.6
            }
        }
    }
}
