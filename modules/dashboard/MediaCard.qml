import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.dashboard
import qs.services

DashboardCard {
    id: root
    headerText: "Now Playing"
    // Visibility owned by DashboardContent (sectionMedia toggle only).
    // Playing/idle state is handled internally via the Loader below.

    readonly property bool isPlaying: MprisController.activePlayer !== null
        && (MprisController.activePlayer?.trackTitle ?? "") !== ""

    // ── Playing state ──
    Loader {
        Layout.fillWidth: true
        active: root.isPlaying
        visible: active
        sourceComponent: playingContent
    }

    // ── Idle placeholder ──
    Loader {
        Layout.fillWidth: true
        active: !root.isPlaying
        visible: active
        sourceComponent: idlePlaceholder
    }

    // ── Playing content ──
    Component {
        id: playingContent

        ColumnLayout {
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                // Album art thumbnail
                Rectangle {
                    implicitWidth: 52
                    implicitHeight: 52
                    radius: Appearance.rounding.small
                    color: ColorUtils.transparentize(Appearance.colors.colSurfaceContainer, 0.5)
                    clip: true

                    Image {
                        id: albumArt
                        anchors.fill: parent
                        source: MprisController.activePlayer?.trackArtUrl ?? ""
                        fillMode: Image.PreserveAspectCrop
                        visible: status === Image.Ready
                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        visible: albumArt.status !== Image.Ready
                        text: "album"
                        iconSize: 28
                        color: Appearance.colors.colSubtext
                    }
                }

                // Track info
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    StyledText {
                        Layout.fillWidth: true
                        text: MprisController.activePlayer?.trackTitle ?? "No media"
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer0
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: MprisController.activePlayer?.trackArtist ?? ""
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        color: Appearance.colors.colSubtext
                        elide: Text.ElideRight
                        visible: text !== ""
                    }
                }
            }

            // ── Playback controls ──
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 4
                spacing: 8

                RippleButton {
                    implicitWidth: 32; implicitHeight: 32; buttonRadius: 16
                    colBackground: "transparent"
                    colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.85)
                    enabled: MprisController.canGoPrevious
                    opacity: enabled ? 1.0 : 0.3
                    onClicked: MprisController.activePlayer?.previous()
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "skip_previous"
                        iconSize: 20
                        color: Appearance.colors.colOnLayer0
                    }
                }

                RippleButton {
                    implicitWidth: 40; implicitHeight: 40; buttonRadius: 20
                    colBackground: ColorUtils.transparentize(Appearance.colors.colSecondary, 0.85)
                    colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colSecondary, 0.75)
                    enabled: MprisController.canTogglePlaying
                    onClicked: MprisController.activePlayer?.togglePlaying()
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: MprisController.isPlaying ? "pause" : "play_arrow"
                        iconSize: 24
                        color: Appearance.colors.colOnLayer0
                    }
                }

                RippleButton {
                    implicitWidth: 32; implicitHeight: 32; buttonRadius: 16
                    colBackground: "transparent"
                    colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.85)
                    enabled: MprisController.canGoNext
                    opacity: enabled ? 1.0 : 0.3
                    onClicked: MprisController.activePlayer?.next()
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

    // ── Idle placeholder (~72px — mirrors identity strip height at top) ──
    Component {
        id: idlePlaceholder

        Item {
            implicitHeight: 40

            RowLayout {
                anchors.fill: parent
                spacing: 8

                MaterialSymbol {
                    text: "music_off"
                    iconSize: 16
                    color: Qt.rgba(1, 1, 1, 0.2)
                }

                StyledText {
                    text: "Not playing"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Qt.rgba(1, 1, 1, 0.25)
                }
            }
        }
    }
}
