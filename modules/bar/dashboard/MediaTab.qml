import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

Item {
    id: root
    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    function formatTime(seconds) {
        if (!seconds || seconds < 0) return "0:00"
        const h = Math.floor(seconds / 3600)
        const m = Math.floor((seconds % 3600) / 60)
        const s = Math.floor(seconds % 60).toString().padStart(2, "0")
        return h > 0 ? `${h}:${m.toString().padStart(2, "0")}:${s}` : `${m}:${s}`
    }

    RowLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: 10
        spacing: 16

        // Album art area
        Rectangle {
            Layout.preferredWidth: 220
            Layout.preferredHeight: 220
            Layout.alignment: Qt.AlignVCenter
            radius: Appearance.rounding.large
            color: Appearance.colors.colSurfaceContainer
            border.width: 1
            border.color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.92)
            clip: true

            Image {
                id: albumArt
                anchors.fill: parent
                source: MprisController.activePlayer?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
                sourceSize.width: 440
                sourceSize.height: 440
            }

            MaterialSymbol {
                anchors.centerIn: parent
                visible: albumArt.status !== Image.Ready
                text: "album"
                iconSize: 64
                color: Appearance.colors.colSubtext
            }
        }

        // Track info + controls + progress
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4

            Item { Layout.fillHeight: true }

            // Track title
            StyledText {
                Layout.fillWidth: true
                text: MprisController.activePlayer?.trackTitle ?? "No media playing"
                font.pixelSize: Appearance.font.pixelSize.larger
                font.weight: Font.Bold
                color: Appearance.colors.colOnLayer0
                elide: Text.ElideRight
                wrapMode: Text.Wrap
                maximumLineCount: 2
            }

            // Album name
            StyledText {
                Layout.fillWidth: true
                text: MprisController.activePlayer?.trackAlbum ?? ""
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colSubtext
                elide: Text.ElideRight
                visible: text.length > 0
            }

            // Artist name
            StyledText {
                Layout.fillWidth: true
                text: MprisController.activePlayer?.trackArtist ?? ""
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer0
                elide: Text.ElideRight
                visible: text.length > 0
            }

            Item { Layout.preferredHeight: 8 }

            // Interactive progress bar
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 6

                readonly property real pos: MprisController.activePlayer?.position ?? 0
                readonly property real len: MprisController.activePlayer?.length ?? 0
                readonly property real fraction: len > 0 ? Math.min(1, Math.max(0, pos / len)) : 0

                // Track background
                Rectangle {
                    anchors.fill: parent
                    radius: Appearance.rounding.unsharpen
                    color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.88)
                }

                // Filled portion
                Rectangle {
                    width: parent.width * parent.fraction
                    height: parent.height
                    radius: Appearance.rounding.unsharpen
                    color: Appearance.colors.colPrimary

                    Behavior on width {
                        NumberAnimation { duration: Appearance.animation.elementMove.duration; easing.type: Appearance.animation.elementMove.type; easing.bezierCurve: Appearance.animation.elementMove.bezierCurve }
                    }
                }

                // Seek interaction
                MouseArea {
                    anchors.fill: parent
                    anchors.topMargin: -6
                    anchors.bottomMargin: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: function(mouse) {
                        if (parent.len > 0) {
                            const seekPos = (mouse.x / width) * parent.len
                            MprisController.activePlayer.position = seekPos
                        }
                    }
                }
            }

            // Time labels
            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    text: formatTime(MprisController.activePlayer?.position ?? 0)
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    font.family: Appearance.font.family.numbers
                    color: Appearance.colors.colSubtext
                }

                Item { Layout.fillWidth: true }

                StyledText {
                    text: formatTime(MprisController.activePlayer?.length ?? 0)
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    font.family: Appearance.font.family.numbers
                    color: Appearance.colors.colSubtext
                }
            }

            Item { Layout.preferredHeight: 4 }

            // Playback controls
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 16

                // Previous
                RippleButton {
                    implicitWidth: 36; implicitHeight: 36; buttonRadius: 18
                    colBackground: "transparent"
                    colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.85)
                    onClicked: MprisController.activePlayer?.previous()
                    opacity: buttonHovered ? 0.85 : 1.0
                    Behavior on opacity { NumberAnimation { duration: Appearance.animation.elementMove.duration; easing.type: Appearance.animation.elementMove.type; easing.bezierCurve: Appearance.animation.elementMove.bezierCurve } }
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "skip_previous"
                        iconSize: 24
                        color: Appearance.colors.colOnLayer0
                    }
                }

                // Play/Pause — hero button
                RippleButton {
                    implicitWidth: 48; implicitHeight: 48; buttonRadius: 24
                    colBackground: Appearance.colors.colPrimary
                    colBackgroundHover: Qt.lighter(Appearance.colors.colPrimary, 1.1)
                    onClicked: MprisController.activePlayer?.togglePlaying()
                    opacity: buttonHovered ? 0.85 : 1.0
                    Behavior on opacity { NumberAnimation { duration: Appearance.animation.elementMove.duration; easing.type: Appearance.animation.elementMove.type; easing.bezierCurve: Appearance.animation.elementMove.bezierCurve } }
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: MprisController.activePlayer?.isPlaying ? "pause" : "play_arrow"
                        iconSize: 28
                        color: Appearance.colors.colOnPrimary
                    }
                }

                // Next
                RippleButton {
                    implicitWidth: 36; implicitHeight: 36; buttonRadius: 18
                    colBackground: "transparent"
                    colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.85)
                    onClicked: MprisController.activePlayer?.next()
                    opacity: buttonHovered ? 0.85 : 1.0
                    Behavior on opacity { NumberAnimation { duration: Appearance.animation.elementMove.duration; easing.type: Appearance.animation.elementMove.type; easing.bezierCurve: Appearance.animation.elementMove.bezierCurve } }
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "skip_next"
                        iconSize: 24
                        color: Appearance.colors.colOnLayer0
                    }
                }
            }

            Item { Layout.preferredHeight: 4 }

            // Player selector — only when multiple players
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 6
                visible: (MprisController.displayPlayers?.length ?? 0) > 1

                MaterialSymbol {
                    text: "devices"
                    iconSize: 14
                    color: Appearance.colors.colSubtext
                }

                StyledText {
                    text: MprisController.activePlayer?.identity ?? ""
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colSubtext
                }

                MaterialSymbol {
                    text: "chevron_right"
                    iconSize: 14
                    color: Appearance.colors.colSubtext
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const players = MprisController.displayPlayers
                        if (!players || players.length <= 1) return
                        const current = MprisController.activePlayer
                        let nextIdx = 0
                        for (let i = 0; i < players.length; i++) {
                            if (players[i] === current) {
                                nextIdx = (i + 1) % players.length
                                break
                            }
                        }
                        MprisController.setActivePlayer(players[nextIdx])
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
