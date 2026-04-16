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

    // Only visible when actually playing or has a track loaded
    visible: MprisController.activePlayer !== null
        && (MprisController.activePlayer?.trackTitle ?? "") !== ""

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
            colBackground: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.85)
            colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.75)
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
