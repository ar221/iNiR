pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Services.Mpris
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

/**
 * MediaView — Media tab for the Deck sidebar.
 *
 * Layout (top → bottom):
 *   [ Placeholder: SpectrumVisualizer — Task 7 ]
 *   Track Row: album art (80×80, glow) + title/artist/album
 *   Transport: shuffle / prev / play / next / repeat
 *   Progress bar: interactive, timestamps
 *   [ Placeholder: SignalPanel — Task 6 ]
 *   [ Placeholder: QueuePreview — Task 8 ]
 *   SystemStrip
 *
 * When no player is active: music note icon + "No media playing".
 * SystemStrip is always visible.
 */
Item {
    id: root

    // ── Track detection ───────────────────────────────────────────────────
    readonly property bool _hasTrack: MprisController.activePlayer !== null

    // ── Art URL ───────────────────────────────────────────────────────────
    readonly property string artUrlSanitized: _hasTrack && MprisController.activeTrack
        ? MprisController.sanitizeArtUrl(MprisController.activeTrack.artUrl ?? "")
        : ""
    readonly property bool _hasArt: artUrlSanitized.length > 0

    // ── Accent color extraction (dominant color from album art) ───────────
    ColorQuantizer {
        id: artAccentQuant
        source: root._hasArt ? root.artUrlSanitized : ""
        depth: 0        // 2^0 = 1 colour — dominant bucket only
        rescaleSize: 1
    }

    readonly property color _accentRaw: artAccentQuant.colors.length > 0
        ? artAccentQuant.colors[0]
        : Appearance.colors.colPrimary

    // ── Art cross-fade slot tracker ───────────────────────────────────────
    property bool   _artSlotA: true
    property string _artUrlA:  ""
    property string _artUrlB:  ""

    onArtUrlSanitizedChanged: {
        if (_artSlotA) {
            _artUrlB = artUrlSanitized
        } else {
            _artUrlA = artUrlSanitized
        }
        _artSlotA = !_artSlotA
    }

    // ── Time formatter ────────────────────────────────────────────────────
    function formatTime(seconds: real): string {
        const s = Math.max(0, Math.floor(seconds))
        const h = Math.floor(s / 3600)
        const m = Math.floor((s % 3600) / 60)
        const sec = s % 60
        if (h > 0)
            return h + ":" + String(m).padStart(2, "0") + ":" + String(sec).padStart(2, "0")
        return m + ":" + String(sec).padStart(2, "0")
    }

    // ── Loop cycle helper ─────────────────────────────────────────────────
    function cycleLoop(): void {
        const state = MprisController.loopState
        if (state === MprisLoopState.None)
            MprisController.setLoopState(MprisLoopState.Track)
        else if (state === MprisLoopState.Track)
            MprisController.setLoopState(MprisLoopState.Playlist)
        else
            MprisController.setLoopState(MprisLoopState.None)
    }

    // ── Main layout ───────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 4

        // ── Spectrum Visualizer — Task 7 ─────────────────────────────────
        SpectrumVisualizer {
            Layout.fillWidth: true
        }

        // ── No-player state ───────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !root._hasTrack

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8

                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    text: "music_note"
                    iconSize: 48
                    color: ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.20)
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "No media playing"
                    font.pixelSize: 12
                    color: ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.40)
                }
            }
        }

        // ── Album Art (centered, above title) ────────────────────────────
        Item {
            id: artWrapper
            Layout.fillWidth: true
            Layout.preferredHeight: 160
            visible: root._hasTrack

            // Radial glow behind art — dominant color at 30% opacity
            RadialGradient {
                anchors.centerIn: artCard
                width: artCard.width + 24
                height: artCard.height + 24
                gradient: Gradient {
                    GradientStop { position: 0.0; color: ColorUtils.applyAlpha(root._accentRaw, 0.30) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            // Art card — centered, square, clipped, rounded
            Rectangle {
                id: artCard
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                width: 160
                height: 160
                radius: 6
                color: "transparent"
                clip: true
                border.width: 1
                border.color: Appearance.colors.colLayer1

                // Fallback: colSecondaryContainer + music_note
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: Appearance.colors.colSecondaryContainer
                    z: 0

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "music_note"
                        iconSize: 48
                        color: ColorUtils.applyAlpha(
                            Appearance.colors.colOnSecondaryContainer, 0.6)
                    }
                }

                // Art slot A
                StyledImage {
                    id: artImageA
                    anchors.fill: parent
                    source: root._artUrlA
                    fillMode: Image.PreserveAspectCrop
                    opacity: (root._artSlotA && status === Image.Ready) ? 1.0 : 0.0
                    z: root._artSlotA ? 2 : 1
                    Behavior on opacity {
                        enabled: Appearance.animationsEnabled
                        NumberAnimation {
                            duration: Appearance.animation.elementMove.duration
                            easing.type: Appearance.animation.elementMove.type
                            easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                        }
                    }
                }

                // Art slot B
                StyledImage {
                    id: artImageB
                    anchors.fill: parent
                    source: root._artUrlB
                    fillMode: Image.PreserveAspectCrop
                    opacity: (!root._artSlotA && status === Image.Ready) ? 1.0 : 0.0
                    z: root._artSlotA ? 1 : 2
                    Behavior on opacity {
                        enabled: Appearance.animationsEnabled
                        NumberAnimation {
                            duration: Appearance.animation.elementMove.duration
                            easing.type: Appearance.animation.elementMove.type
                            easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                        }
                    }
                }
            }
        }

        // ── Track Info (centered text below art) ─────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            visible: root._hasTrack

            // Track title — 17px bold, centered
            Text {
                Layout.fillWidth: true
                text: MprisController.activeTrack?.title ?? ""
                font.pixelSize: 17
                font.bold: true
                color: Appearance.colors.colOnLayer1
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                maximumLineCount: 2
                wrapMode: Text.WordWrap
            }

            // Artist — 14px subdued, centered
            Text {
                Layout.fillWidth: true
                text: MprisController.activeTrack?.artist ?? ""
                font.pixelSize: 14
                color: Appearance.colors.colOnSurfaceVariant
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                maximumLineCount: 1
            }

            // Album — 12px dim italic, centered
            Text {
                Layout.fillWidth: true
                text: MprisController.activeTrack?.album ?? ""
                font.pixelSize: 12
                font.italic: true
                color: ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.50)
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                maximumLineCount: 1
            }
        }

        // ── Transport Controls ────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            implicitHeight: 44
            visible: root._hasTrack

            RowLayout {
                anchors.centerIn: parent
                spacing: 16

                // Shuffle
                RippleButton {
                    id: shuffleBtn
                    implicitWidth: 32
                    implicitHeight: 32
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.colors.colLayer1Hover
                    enabled: MprisController.shuffleSupported
                    onClicked: MprisController.setShuffle(!MprisController.hasShuffle)

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "shuffle"
                        iconSize: 18
                        color: MprisController.hasShuffle
                            ? Appearance.colors.colPrimary
                            : ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.60)
                        Behavior on color {
                            enabled: Appearance.animationsEnabled
                            ColorAnimation { duration: 120 }
                        }
                    }
                }

                // Previous
                RippleButton {
                    id: prevBtn
                    implicitWidth: 34
                    implicitHeight: 34
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.colors.colLayer1Hover
                    enabled: MprisController.canGoPrevious
                    onClicked: MprisController.previous()

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "skip_previous"
                        iconSize: 20
                        color: prevBtn.enabled
                            ? ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.80)
                            : ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.30)
                    }
                }

                // Play / Pause — hero control with colPrimary accent
                Rectangle {
                    id: playPauseCard
                    implicitWidth: 44
                    implicitHeight: 44
                    radius: 4
                    color: playPauseMouse.containsMouse
                        ? ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.15)
                        : ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.06)
                    border.width: 1.5
                    border.color: Appearance.colors.colPrimary

                    Behavior on color {
                        enabled: Appearance.animationsEnabled
                        ColorAnimation { duration: 120 }
                    }

                    // play_arrow — visible when paused
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "play_arrow"
                        iconSize: 24
                        color: Appearance.colors.colPrimary
                        opacity: MprisController.isPlaying ? 0.0 : 1.0
                        Behavior on opacity {
                            enabled: Appearance.animationsEnabled
                            NumberAnimation { duration: 120 }
                        }
                    }

                    // pause — visible when playing
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "pause"
                        iconSize: 24
                        color: Appearance.colors.colPrimary
                        opacity: MprisController.isPlaying ? 1.0 : 0.0
                        Behavior on opacity {
                            enabled: Appearance.animationsEnabled
                            NumberAnimation { duration: 120 }
                        }
                    }

                    MouseArea {
                        id: playPauseMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (MprisController.canTogglePlaying) MprisController.togglePlaying()
                    }
                }

                // Next
                RippleButton {
                    id: nextBtn
                    implicitWidth: 34
                    implicitHeight: 34
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.colors.colLayer1Hover
                    enabled: MprisController.canGoNext
                    onClicked: MprisController.next()

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "skip_next"
                        iconSize: 20
                        color: nextBtn.enabled
                            ? ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.80)
                            : ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.30)
                    }
                }

                // Repeat
                RippleButton {
                    id: repeatBtn
                    implicitWidth: 32
                    implicitHeight: 32
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.colors.colLayer1Hover
                    enabled: MprisController.loopSupported
                    onClicked: root.cycleLoop()

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: MprisController.loopState === MprisLoopState.Track
                            ? "repeat_one"
                            : "repeat"
                        iconSize: 18
                        color: MprisController.loopState !== MprisLoopState.None
                            ? Appearance.colors.colPrimary
                            : ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.60)
                        Behavior on color {
                            enabled: Appearance.animationsEnabled
                            ColorAnimation { duration: 120 }
                        }
                    }
                }
            }
        }

        // ── Progress Bar ──────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            implicitHeight: 24
            visible: root._hasTrack

            // Elapsed timestamp
            Text {
                id: elapsedLabel
                anchors.left: parent.left
                anchors.verticalCenter: progressTrack.verticalCenter
                text: root.formatTime(MprisController.activePosition)
                font.pixelSize: 11
                font.family: Appearance.font.numbers?.family ?? Appearance.font.family.main
                color: ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.40)
            }

            // Total timestamp
            Text {
                id: totalLabel
                anchors.right: parent.right
                anchors.verticalCenter: progressTrack.verticalCenter
                text: root.formatTime(MprisController.activeLength)
                font.pixelSize: 11
                font.family: Appearance.font.numbers?.family ?? Appearance.font.family.main
                color: ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.40)
            }

            // Track background
            Rectangle {
                id: progressTrack
                anchors.left: elapsedLabel.right
                anchors.right: totalLabel.left
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                height: 4
                radius: 2
                color: ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.15)

                // Ratio — clamped
                readonly property real _ratio: MprisController.activeLength > 0
                    ? Math.max(0, Math.min(1,
                        MprisController.activePosition / MprisController.activeLength))
                    : 0.0

                // Fill — colPrimary gradient (base → lighter)
                Rectangle {
                    id: progressFill
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    // No Behavior — position updates every ~1s from MPRIS; animation fights it
                    width: progressTrack.width * progressTrack._ratio
                    radius: parent.radius

                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: Appearance.colors.colPrimary }
                        GradientStop { position: 1.0; color: Qt.lighter(Appearance.colors.colPrimary, 1.15) }
                    }
                }

                // Scrub dot — always visible with glow halo
                Rectangle {
                    id: scrubDot
                    width: 10
                    height: 10
                    radius: 5
                    color: Appearance.colors.colPrimary
                    anchors.verticalCenter: parent.verticalCenter
                    x: progressTrack.width * progressTrack._ratio - width / 2

                    // Glow halo
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width + 8
                        height: parent.height + 8
                        radius: width / 2
                        color: Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b, 0.35)
                        z: -1
                    }
                }

                // Interactive scrub
                MouseArea {
                    id: progressMouseArea
                    anchors.fill: parent
                    // Extend hit area vertically for easier grabbing
                    anchors.topMargin: -8
                    anchors.bottomMargin: -8
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    function _seek(mouseX: real): void {
                        if (!MprisController.canSeek) return
                        if (MprisController.activeLength <= 0) return
                        const ratio = Math.max(0, Math.min(1, mouseX / progressTrack.width))
                        MprisController.setPosition(ratio * MprisController.activeLength)
                    }

                    onClicked: (event) => { _seek(event.x) }
                    onPositionChanged: (event) => {
                        if (pressed) _seek(event.x)
                    }
                }
            }
        }

        // ── Signal Panel — Task 6 ────────────────────────────────────────
        DeckDivider { visible: signalPanel.visible }
        DeckLabel { text: "SIGNAL"; visible: signalPanel.visible }
        SignalPanel {
            id: signalPanel
            Layout.fillWidth: true
        }

        // ── Source Info — player identity + metadata ─────────────────────
        DeckDivider { visible: root._hasTrack }
        DeckLabel { text: "SOURCE"; visible: root._hasTrack }
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 4
            rowSpacing: 4
            visible: root._hasTrack

            InstrumentCell {
                label: "PLAYER"
                value: MprisController.activePlayer?.identity ?? "—"
            }
            InstrumentCell {
                label: "STATUS"
                value: MprisController.isPlaying ? "PLAYING"
                     : MprisController.activePlayer ? "PAUSED" : "—"
            }
        }

        // ── Queue Preview — Task 8 ───────────────────────────────────────
        DeckDivider { visible: queuePreview._visible }
        DeckLabel { text: "UP NEXT"; visible: queuePreview._visible }
        QueuePreview {
            id: queuePreview
            Layout.fillWidth: true
        }

        // Push SystemStrip to bottom
        Item { Layout.fillHeight: true; Layout.maximumHeight: 60 }

        // ── System Strip — always visible ─────────────────────────────────
        SystemStrip {
            Layout.fillWidth: true
        }
    }
}
