import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects as GE
import Quickshell
import Quickshell.Services.Mpris
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

ColumnLayout {
    id: root

    property var configEntry: ({})
    readonly property var player: MprisController.activePlayer
    readonly property bool hasPlayer: player !== null && player !== undefined
    readonly property var allPlayers: MprisController.displayPlayers ?? []
    readonly property bool multiplePlayers: allPlayers.length > 1
    readonly property bool isPlaying: MprisController.isPlaying
    readonly property bool hasArt: albumArt.status === Image.Ready

    visible: hasPlayer
    spacing: 8

    // Preload album art (invisible until used)
    Image {
        id: albumArt
        visible: false
        source: root.player?.trackArtUrl ?? ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        width: 0; height: 0
    }

    // Cava visualizer process
    CavaProcess {
        id: cavaProcess
        active: root.hasPlayer && root.isPlaying
    }

    // Player switcher (only when multiple sources)
    RowLayout {
        Layout.fillWidth: true
        visible: root.multiplePlayers
        spacing: 6

        MaterialSymbol {
            text: "devices"
            iconSize: 14
            color: Appearance.colors.colSubtext
        }

        StyledText {
            Layout.fillWidth: true
            text: root.player?.identity ?? "Unknown Player"
            font.pixelSize: Appearance.font.pixelSize.smallest
            font.weight: Font.Medium
            color: Appearance.colors.colSubtext
            elide: Text.ElideRight
        }

        RippleButton {
            implicitWidth: 24; implicitHeight: 24
            buttonRadius: 12
            colBackground: "transparent"
            colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.85)
            onClicked: {
                const players = root.allPlayers
                const currentIdx = players.indexOf(root.player)
                const prevIdx = (currentIdx - 1 + players.length) % players.length
                MprisController.setActivePlayer(players[prevIdx])
            }
            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                text: "chevron_left"
                iconSize: 16
                color: Appearance.colors.colSubtext
            }
        }

        RippleButton {
            implicitWidth: 24; implicitHeight: 24
            buttonRadius: 12
            colBackground: "transparent"
            colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.85)
            onClicked: {
                const players = root.allPlayers
                const currentIdx = players.indexOf(root.player)
                const nextIdx = (currentIdx + 1) % players.length
                MprisController.setActivePlayer(players[nextIdx])
            }
            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                text: "chevron_right"
                iconSize: 16
                color: Appearance.colors.colSubtext
            }
        }
    }

    // ── Album art with visualizer (only when playing + has art) ──
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: artContainer.height
        visible: root.hasArt && root.isPlaying
        clip: true

        Behavior on Layout.preferredHeight {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        Rectangle {
            id: artContainer
            anchors.left: parent.left
            anchors.right: parent.right
            height: 120
            radius: Appearance.rounding.normal
            color: Appearance.colors.colSurfaceContainer
            clip: true

            Image {
                id: artDisplay
                anchors.fill: parent
                source: albumArt.source
                fillMode: Image.PreserveAspectCrop
                visible: false
                asynchronous: true
            }

            GE.OpacityMask {
                anchors.fill: parent
                source: artDisplay
                maskSource: Rectangle {
                    width: artContainer.width
                    height: artContainer.height
                    radius: artContainer.radius
                }
                visible: artDisplay.status === Image.Ready
            }

            // Gradient overlay
            Rectangle {
                anchors.fill: parent
                visible: artDisplay.status === Image.Ready
                radius: artContainer.radius
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.5; color: "transparent" }
                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.7) }
                }
            }

            // Cava wave overlay
            WaveVisualizer {
                anchors.fill: parent
                points: cavaProcess.points
                live: root.isPlaying
                maxVisualizerValue: 800
                smoothing: 3
            }
        }
    }

    // ── Track info + controls ──
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        // Small album art thumbnail (when no big art or paused)
        Rectangle {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            radius: Appearance.rounding.small
            color: Appearance.colors.colSurfaceContainer
            visible: !root.isPlaying || !root.hasArt
            clip: true

            Image {
                anchors.fill: parent
                source: albumArt.source
                fillMode: Image.PreserveAspectCrop
                visible: false
                id: thumbArt
                asynchronous: true
            }

            GE.OpacityMask {
                anchors.fill: parent
                source: thumbArt
                maskSource: Rectangle { width: 40; height: 40; radius: Appearance.rounding.small }
                visible: thumbArt.status === Image.Ready
            }

            MaterialSymbol {
                anchors.centerIn: parent
                text: "music_note"
                iconSize: 20
                color: ColorUtils.transparentize(Appearance.colors.colSubtext, 0.4)
                visible: thumbArt.status !== Image.Ready
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            StyledText {
                Layout.fillWidth: true
                text: root.player?.trackTitle ?? "Nothing Playing"
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer0
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            StyledText {
                Layout.fillWidth: true
                text: root.player?.trackArtist ?? ""
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colSubtext
                elide: Text.ElideRight
                maximumLineCount: 1
                visible: text !== ""
            }
        }

        RowLayout {
            spacing: 2

            RippleButton {
                implicitWidth: 30; implicitHeight: 30
                buttonRadius: 15
                colBackground: "transparent"
                colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.85)
                onClicked: MprisController.previous()
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: "skip_previous"
                    iconSize: 20
                    color: Appearance.colors.colOnLayer0
                }
            }

            RippleButton {
                implicitWidth: 36; implicitHeight: 36
                buttonRadius: 18
                colBackground: Appearance.colors.colPrimary
                colBackgroundHover: ColorUtils.lighten(Appearance.colors.colPrimary, 0.1)
                onClicked: MprisController.togglePlaying()
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: root.isPlaying ? "pause" : "play_arrow"
                    iconSize: 22
                    color: Appearance.colors.colOnPrimary
                }
            }

            RippleButton {
                implicitWidth: 30; implicitHeight: 30
                buttonRadius: 15
                colBackground: "transparent"
                colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.85)
                onClicked: MprisController.next()
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: "skip_next"
                    iconSize: 20
                    color: Appearance.colors.colOnLayer0
                }
            }
        }
    }
}
