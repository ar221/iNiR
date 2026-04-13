pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

Item {
    id: root
    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    property var workspaces: []
    property bool workspacesLoaded: false
    property bool moveExpanded: true
    property bool utilitiesExpanded: true

    Process {
        id: workspaceProc
        command: ["/usr/bin/bash", "-c", "niri msg -j workspaces 2>/dev/null"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    const parsed = JSON.parse(data.trim())
                    // Sort by idx
                    parsed.sort((a, b) => a.idx - b.idx)
                    root.workspaces = parsed
                    root.workspacesLoaded = true
                } catch (e) {
                    root.workspacesLoaded = false
                }
            }
        }
    }

    Component.onCompleted: workspaceProc.running = true

    Timer {
        running: root.visible
        interval: 2000
        repeat: true
        onTriggered: workspaceProc.running = true
    }

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14

        // Move Window to Workspace section
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            // Collapsible header
            RippleButton {
                Layout.fillWidth: true
                implicitHeight: 36
                buttonRadius: Appearance.rounding.small
                colBackground: "transparent"
                colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.4)
                onClicked: root.moveExpanded = !root.moveExpanded

                contentItem: RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 4
                    anchors.rightMargin: 4

                    StyledText {
                        Layout.fillWidth: true
                        text: "Move Window to Workspace"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer0
                    }
                    MaterialSymbol {
                        text: "expand_more"
                        iconSize: 20
                        color: Appearance.colors.colSubtext
                        rotation: root.moveExpanded ? 0 : -90
                        Behavior on rotation { NumberAnimation { duration: Appearance.animation.elementMove.duration; easing.type: Appearance.animation.elementMove.type; easing.bezierCurve: Appearance.animation.elementMove.bezierCurve } }
                    }
                }
            }

            // Workspace buttons
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                visible: root.moveExpanded
                opacity: root.moveExpanded ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Appearance.animation.elementMove.duration; easing.type: Appearance.animation.elementMove.type; easing.bezierCurve: Appearance.animation.elementMove.bezierCurve } }

                Repeater {
                    model: root.workspaces

                    RippleButton {
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        implicitHeight: 40
                        buttonRadius: Appearance.rounding.small

                        colBackground: modelData.is_focused
                            ? Appearance.colors.colPrimary
                            : ColorUtils.transparentize(Appearance.colors.colLayer0, 0.4)
                        colBackgroundHover: modelData.is_focused
                            ? Appearance.colors.colPrimaryHover
                            : ColorUtils.transparentize(Appearance.colors.colLayer0, 0.2)

                        onClicked: {
                            movProc.command = ["/usr/bin/bash", "-c", "niri msg action move-window-to-workspace " + modelData.idx]
                            movProc.running = true
                        }

                        Process { id: movProc }

                        contentItem: RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12

                            StyledText {
                                Layout.fillWidth: true
                                text: modelData.name || ("Workspace " + modelData.idx)
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: Font.Medium
                                color: modelData.is_focused
                                    ? Appearance.colors.colOnPrimary
                                    : Appearance.colors.colOnLayer0
                            }
                            MaterialSymbol {
                                text: "circle"
                                iconSize: 8
                                color: modelData.is_focused
                                    ? Appearance.colors.colOnPrimary
                                    : "transparent"
                                visible: modelData.is_focused
                            }
                        }
                    }
                }
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.92)
        }

        // Window Utilities section
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            // Collapsible header
            RippleButton {
                Layout.fillWidth: true
                implicitHeight: 36
                buttonRadius: Appearance.rounding.small
                colBackground: "transparent"
                colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.4)
                onClicked: root.utilitiesExpanded = !root.utilitiesExpanded

                contentItem: RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 4
                    anchors.rightMargin: 4

                    StyledText {
                        Layout.fillWidth: true
                        text: "Window Utilities"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer0
                    }
                    MaterialSymbol {
                        text: "expand_more"
                        iconSize: 20
                        color: Appearance.colors.colSubtext
                        rotation: root.utilitiesExpanded ? 0 : -90
                        Behavior on rotation { NumberAnimation { duration: Appearance.animation.elementMove.duration; easing.type: Appearance.animation.elementMove.type; easing.bezierCurve: Appearance.animation.elementMove.bezierCurve } }
                    }
                }
            }

            // Action cards grid
            GridLayout {
                Layout.fillWidth: true
                columns: 3
                rowSpacing: 8
                columnSpacing: 8
                visible: root.utilitiesExpanded
                opacity: root.utilitiesExpanded ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Appearance.animation.elementMove.duration; easing.type: Appearance.animation.elementMove.type; easing.bezierCurve: Appearance.animation.elementMove.bezierCurve } }

                NiriAction {
                    actionIcon: "fullscreen"
                    actionLabel: "Fullscreen"
                    cmd: "niri msg action fullscreen-window"
                }
                NiriAction {
                    actionIcon: "fit_screen"
                    actionLabel: "Maximize"
                    cmd: "niri msg action maximize-column"
                }
                NiriAction {
                    actionIcon: "center_focus_strong"
                    actionLabel: "Center"
                    cmd: "niri msg action center-window"
                }
                NiriAction {
                    actionIcon: "keyboard_off"
                    actionLabel: "Inhibit Keys"
                    cmd: "niri msg action toggle-keyboard-shortcuts-inhibit"
                }
                NiriAction {
                    actionIcon: "screenshot_monitor"
                    actionLabel: "Screenshot"
                    cmd: "niri msg action screenshot-window"
                }
                NiriAction {
                    actionIcon: "close"
                    actionLabel: "Close"
                    cmd: "niri msg action close-window"
                }
            }
        }

        Item { Layout.fillHeight: true }
    }

    component NiriAction: RippleButton {
        property string actionIcon: ""
        property string actionLabel: ""
        property string cmd: ""

        Layout.fillWidth: true
        implicitHeight: 72
        buttonRadius: Appearance.rounding.small
        colBackground: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.4)
        colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.2)
        opacity: buttonHovered ? 0.85 : 1.0
        Behavior on opacity { NumberAnimation { duration: Appearance.animation.elementMove.duration; easing.type: Appearance.animation.elementMove.type; easing.bezierCurve: Appearance.animation.elementMove.bezierCurve } }
        onClicked: niriActionProc.running = true

        Process { id: niriActionProc; command: ["/usr/bin/bash", "-c", parent.cmd] }

        contentItem: ColumnLayout {
            anchors.centerIn: parent
            spacing: 6

            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                text: parent.parent.actionIcon
                iconSize: 24
                color: Appearance.colors.colOnLayer0
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: parent.parent.actionLabel
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colSubtext
            }
        }
    }
}
