pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.background.widgets
import qs.modules.mediaControls.components
import qs.services

// Now Playing — a tall poster card on the desktop background.
// Album art hero, meta, seekable progress, transport, Cava mini-spectrum.
// Standalone AbstractBackgroundWidget; reuses the mediaControls/ components
// through PlayerBase — their intended substrate (art-download pipeline,
// YtMusic effective* fallbacks, artDominantColor quantizer).
AbstractBackgroundWidget {
    id: root

    configEntryName: "nowPlaying"

    readonly property var npConfig: configEntry
    readonly property real cardWidth: npConfig?.cardWidth ?? 320
    readonly property real cardOpacity: npConfig?.cardOpacity ?? 0.85
    readonly property bool showVisualizer: npConfig?.showVisualizer ?? true
    readonly property point screenPos: root.mapToItem(null, 0, 0)

    // Idle = no active MPRIS player. PlayerBase's effective* props all
    // null-coalesce, so binding a null player is safe.
    readonly property bool idle: !MprisController.activePlayer

    // Single PlayerBase — the substrate every mediaControls component is
    // designed against. One per widget, keyed to the active player.
    PlayerBase {
        id: playerBase
        player: MprisController.activePlayer
    }

    implicitWidth: cardWidth
    implicitHeight: cardContent.implicitHeight + cardContent.anchors.margins * 2

    // ── Drop shadow ──
    StyledRectangularShadow {
        target: cardBackground
        visible: !Appearance.inirEverywhere && !Appearance.auroraEverywhere
    }

    // ── Glass card background (Courier Console: square / micro-radius) ──
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
            fallbackColor: ColorUtils.transparentize(
                Appearance.colors.colLayer0,
                1.0 - root.cardOpacity
            )
        }

        Rectangle {
            anchors.fill: parent
            visible: !Appearance.auroraEverywhere && !Appearance.angelEverywhere
            radius: parent.radius
            color: ColorUtils.transparentize(
                Appearance.colors.colLayer0,
                1.0 - root.cardOpacity
            )
        }

        // ── Album-art wash — blurred art fill behind the content ──
        // (FullPlayer.qml:101-119 pattern; the spec's "album art wash")
        Image {
            anchors.fill: parent
            source: playerBase.displayedArtFilePath
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            smooth: true
            mipmap: true
            opacity: root.idle ? 0.0 : 0.18
            visible: playerBase.displayedArtFilePath !== ""

            layer.enabled: Appearance.effectsEnabled
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 0.4
                blurMax: 24
                saturation: 0.1
            }

            Behavior on opacity {
                enabled: Appearance.animationsEnabled
                NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
            }
        }

        // ── Border ──
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.width: 1
            border.color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.88)
        }

        // Inset depth — top edge gradient
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

    // ── Content: tall poster stack ──
    ColumnLayout {
        id: cardContent
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        // 1 — Album art hero (near full-width square)
        PlayerArtwork {
            Layout.fillWidth: true
            Layout.preferredHeight: width
            artSource: playerBase.displayedArtFilePath
            downloaded: playerBase.downloaded && !root.idle
            artRadius: Appearance.rounding.unsharpen
        }

        // 2 — Meta block
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                Layout.fillWidth: true
                text: root.idle
                    ? Translation.tr("Nothing playing")
                    : (StringUtils.cleanMusicTitle(playerBase.effectiveTitle) || "—")
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.DemiBold
                color: root.idle ? Appearance.colors.colSubtext : Appearance.colors.colOnLayer0
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            StyledText {
                Layout.fillWidth: true
                visible: !root.idle && text !== ""
                text: {
                    const a = playerBase.effectiveArtist || ""
                    const al = playerBase.effectiveAlbum || ""
                    if (a && al) return a + "  ·  " + al
                    return a || al
                }
                font.family: Appearance.font.family.monospace
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.Medium
                color: Appearance.colors.colSubtext
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }

        // 3 — Progress + time
        ColumnLayout {
            Layout.fillWidth: true
            visible: !root.idle
            spacing: 2

            PlayerProgress {
                Layout.fillWidth: true
                implicitHeight: 16
                position: playerBase.effectivePosition
                length: playerBase.effectiveLength
                canSeek: playerBase.effectiveCanSeek
                isPlaying: playerBase.effectiveIsPlaying
                highlightColor: playerBase.artDominantColor
                onSeekRequested: seconds => playerBase.seek(seconds)
            }

            RowLayout {
                Layout.fillWidth: true

                StyledText {
                    text: StringUtils.friendlyTimeForSeconds(playerBase.effectivePosition)
                    font.family: Appearance.font.family.numbers
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colSubtext
                }

                Item { Layout.fillWidth: true }

                StyledText {
                    text: StringUtils.friendlyTimeForSeconds(playerBase.effectiveLength)
                    font.family: Appearance.font.family.numbers
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colSubtext
                }
            }
        }

        // 4 — Transport
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: transportRow.implicitHeight
            visible: !root.idle

            PlayerControls {
                id: transportRow
                anchors.horizontalCenter: parent.horizontalCenter
                isPlaying: playerBase.effectiveIsPlaying
                onPreviousClicked: playerBase.previous()
                onPlayPauseClicked: playerBase.togglePlaying()
                onNextClicked: playerBase.next()
            }
        }

        // 5 — Cava mini-spectrum (stays visible when idle, just frozen — the
        // process is gated off because MprisController.isPlaying is false)
        MiniSpectrum {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            active: MprisController.isPlaying && root.visible && root.showVisualizer
            barColor: playerBase.artDominantColor
        }
    }
}
