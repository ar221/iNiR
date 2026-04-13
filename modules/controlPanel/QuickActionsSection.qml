pragma ComponentBehavior: Bound
import qs
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

ColumnLayout {
    id: root
    Layout.fillWidth: true
    spacing: root.compactMode ? 4 : 6
    readonly property bool compactMode: Config.options?.controlPanel?.compactMode ?? true

    readonly property bool inirEverywhere: Appearance.inirEverywhere
    readonly property bool auroraEverywhere: Appearance.auroraEverywhere

    Rectangle {
        id: gridCard
        Layout.fillWidth: true
        implicitHeight: actionsGrid.implicitHeight + (root.compactMode ? 12 : 16)

        radius: Appearance.angelEverywhere ? Appearance.angel.roundingNormal
            : root.inirEverywhere ? Appearance.inir.roundingNormal : Appearance.rounding.normal
        color: Appearance.angelEverywhere ? Appearance.angel.colGlassCard
             : root.inirEverywhere ? Appearance.inir.colLayer1
             : root.auroraEverywhere ? Appearance.aurora.colSubSurface
             : Appearance.colors.colLayer1
        border.width: Appearance.angelEverywhere ? 0 : (root.inirEverywhere ? 1 : 0)
        border.color: Appearance.angelEverywhere ? "transparent"
            : root.inirEverywhere ? Appearance.inir.colBorder : "transparent"

        AngelPartialBorder { targetRadius: parent.radius; coverage: 0.45 }

        GridLayout {
            id: actionsGrid
            anchors.fill: parent
            anchors.margins: root.compactMode ? 6 : 8
            columns: 4
            rowSpacing: root.compactMode ? 4 : 6
            columnSpacing: root.compactMode ? 4 : 6

        // Row 1: Audio
        ActionTile {
            icon: Audio.sink?.audio?.muted ? "volume_off" : "volume_up"
            active: !(Audio.sink?.audio?.muted ?? false)
            onClicked: Audio.toggleMute()
        }

        ActionTile {
            icon: Audio.micMuted ? "mic_off" : "mic"
            active: !Audio.micMuted
            onClicked: Audio.toggleMicMute()
        }

        ActionTile {
            icon: "notifications"
            active: !Notifications.silent
            onClicked: Notifications.silent = !Notifications.silent
        }

        ActionTile {
            icon: "dark_mode"
            active: Appearance.m3colors.darkmode
            onClicked: Appearance.toggleDarkMode()
        }

        // Row 2: Connectivity & System
        ActionTile {
            icon: Network.wifiEnabled ? "wifi" : "wifi_off"
            active: Network.wifiEnabled
            onClicked: Network.toggleWifi()
        }

        ActionTile {
            visible: BluetoothStatus.available
            icon: BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
            active: BluetoothStatus.enabled
            onClicked: BluetoothStatus.toggle()
        }

        ActionTile {
            icon: "coffee"
            active: Idle.inhibit
            onClicked: Idle.toggleInhibit()
        }

        ActionTile {
            icon: "sports_esports"
            active: GameMode.active
            onClicked: GameMode.toggle()
        }

        // Row 3: Tools
        ActionTile {
            icon: "screenshot_monitor"
            onClicked: {
                GlobalStates.controlPanelOpen = false
                GlobalStates.regionSelectorOpen = true
            }
        }

        ActionTile {
            icon: "settings"
            onClicked: {
                GlobalStates.controlPanelOpen = false
                Quickshell.execDetached([Quickshell.shellPath("scripts/inir"), "settings"])
            }
        }

        ActionTile {
            icon: "lock"
            onClicked: {
                GlobalStates.controlPanelOpen = false
                Quickshell.execDetached([Quickshell.shellPath("scripts/inir"), "lock", "activate"])
            }
        }

        ActionTile {
            icon: "power_settings_new"
            iconColor: Appearance.angelEverywhere ? Appearance.m3colors.m3error
                     : root.inirEverywhere ? Appearance.inir.colError
                     : root.auroraEverywhere ? Appearance.m3colors.m3error
                     : Appearance.colors.colError
            onClicked: {
                GlobalStates.controlPanelOpen = false
                GlobalStates.sessionOpen = true
            }
        }
    }
    }

    // ─── Focus Mode chip row ─────────────────────────────────
    ButtonGroup {
        Layout.fillWidth: true
        Layout.preferredHeight: root.compactMode ? 28 : 32
        spacing: root.compactMode ? 3 : 4
        color: "transparent"

        Repeater {
            model: FocusMode._modeOrder

            GroupButton {
                required property string modelData
                required property int index

                readonly property var modeProfile: FocusMode._profiles[modelData] ?? ({})
                readonly property bool isActive: FocusMode.activeMode === modelData

                toggled: isActive
                buttonText: modeProfile.label ?? modelData
                buttonRadius: Appearance.angelEverywhere ? Appearance.angel.roundingSmall
                    : root.inirEverywhere ? Appearance.inir.roundingSmall : Appearance.rounding.small

                implicitHeight: root.compactMode ? 28 : 32
                horizontalPadding: root.compactMode ? 8 : 12
                verticalPadding: 0
                bounce: false

                colBackgroundToggled: {
                    switch (modelData) {
                        case "focus": return Appearance.m3colors.m3primary
                        case "gaming": return Appearance.m3colors.m3tertiary
                        case "zen": return Appearance.m3colors.m3secondary
                        default: return Appearance.angelEverywhere ? Appearance.angel.colGlassCard
                            : root.inirEverywhere ? Appearance.inir.colLayer2
                            : root.auroraEverywhere ? Appearance.aurora.colSubSurface
                            : Appearance.colors.colLayer2
                    }
                }
                colBackgroundToggledHover: ColorUtils.transparentize(colBackgroundToggled, 0.15)
                colBackground: "transparent"
                colBackgroundHover: Appearance.angelEverywhere ? Appearance.angel.colGlassCardHover
                    : root.inirEverywhere ? Appearance.inir.colLayer2Hover
                    : root.auroraEverywhere ? Appearance.aurora.colSubSurfaceHover
                    : Appearance.colors.colLayer2Hover

                Layout.fillWidth: true

                onClicked: FocusMode.setMode(modelData)

                contentItem: RowLayout {
                    spacing: 4

                    MaterialSymbol {
                        visible: modeProfile.icon !== ""
                        text: modeProfile.icon ?? ""
                        iconSize: root.compactMode ? 14 : 16
                        color: isActive
                            ? (Appearance.angelEverywhere ? Appearance.angel.colOnPrimary
                                : root.inirEverywhere ? Appearance.inir.colOnPrimary
                                : Appearance.m3colors.m3onPrimary)
                            : (Appearance.angelEverywhere ? Appearance.angel.colText
                                : root.inirEverywhere ? Appearance.inir.colText
                                : Appearance.colors.colOnLayer1)

                        Behavior on color {
                            enabled: Appearance.animationsEnabled
                            animation: ColorAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
                        }
                    }

                    StyledText {
                        text: modeProfile.label ?? modelData
                        font.pixelSize: root.compactMode ? Appearance.font.pixelSize.smallest : Appearance.font.pixelSize.small
                        font.weight: Font.Medium
                        color: isActive
                            ? (Appearance.angelEverywhere ? Appearance.angel.colOnPrimary
                                : root.inirEverywhere ? Appearance.inir.colOnPrimary
                                : Appearance.m3colors.m3onPrimary)
                            : (Appearance.angelEverywhere ? Appearance.angel.colText
                                : root.inirEverywhere ? Appearance.inir.colText
                                : Appearance.colors.colOnLayer1)

                        Behavior on color {
                            enabled: Appearance.animationsEnabled
                            animation: ColorAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
                        }
                    }
                }
            }
        }
    }

    component ActionTile: Rectangle {
        id: tile
        property string icon
        property bool active: false
        property color iconColor: active 
            ? (Appearance.angelEverywhere ? Appearance.angel.colOnPrimary
             : root.inirEverywhere ? Appearance.inir.colOnPrimary 
             : root.auroraEverywhere ? Appearance.m3colors.m3onPrimary
             : Appearance.colors.colOnPrimary)
            : (Appearance.angelEverywhere ? Appearance.angel.colText
             : root.inirEverywhere ? Appearance.inir.colText 
             : root.auroraEverywhere ? Appearance.m3colors.m3onSurface
             : Appearance.colors.colOnLayer1)
        signal clicked()

        Layout.fillWidth: true
        implicitHeight: root.compactMode ? 30 : 36
        radius: Appearance.angelEverywhere ? Appearance.angel.roundingSmall
            : root.inirEverywhere ? Appearance.inir.roundingSmall : Appearance.rounding.small
        
        color: tileMouseArea.containsMouse 
            ? (active 
                ? (Appearance.angelEverywhere ? ColorUtils.transparentize(Appearance.angel.colPrimaryHover, 0.35)
                 : root.inirEverywhere ? Appearance.inir.colPrimaryHover 
                 : root.auroraEverywhere ? Appearance.colors.colPrimaryHover
                 : Appearance.colors.colPrimaryHover)
                : (Appearance.angelEverywhere ? Appearance.angel.colGlassCardHover
                 : root.inirEverywhere ? Appearance.inir.colLayer2Hover 
                 : root.auroraEverywhere ? Appearance.aurora.colSubSurfaceHover
                 : Appearance.colors.colLayer2Hover))
            : (active 
                ? (Appearance.angelEverywhere ? ColorUtils.transparentize(Appearance.angel.colPrimary, 0.45)
                 : root.inirEverywhere ? Appearance.inir.colPrimary 
                 : root.auroraEverywhere ? Appearance.m3colors.m3primary
                 : Appearance.colors.colPrimary)
                : (Appearance.angelEverywhere ? Appearance.angel.colGlassCard
                 : root.inirEverywhere ? Appearance.inir.colLayer2 
                 : root.auroraEverywhere ? Appearance.aurora.colSubSurface
                 : Appearance.colors.colLayer2))

        border.width: Appearance.angelEverywhere ? 0 : (root.inirEverywhere ? 1 : 0)
        border.color: Appearance.angelEverywhere ? "transparent"
            : root.inirEverywhere ? (active ? Appearance.inir.colPrimary : Appearance.inir.colBorderSubtle) : "transparent"

        AngelPartialBorder { targetRadius: parent.radius; coverage: 0.4; borderColor: active ? Appearance.angel.colPrimary : Appearance.angel.colBorderSubtle }

        Behavior on color {
            enabled: Appearance.animationsEnabled
            animation: ColorAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
        }

        MaterialSymbol {
            anchors.centerIn: parent
            text: tile.icon
            iconSize: root.compactMode ? 16 : 18
            color: tile.iconColor

            Behavior on color {
                enabled: Appearance.animationsEnabled
                animation: ColorAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
            }
        }

        MouseArea {
            id: tileMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.clicked()
        }
    }
}
