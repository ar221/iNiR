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
    readonly property int sectionTopMargin: 2

    // ── Track detection ───────────────────────────────────────────────────
    readonly property bool _hasTrack: MprisController.activePlayer !== null

    // ── Art URL ───────────────────────────────────────────────────────────
    // MPRIS artUrl (direct from player metadata)
    readonly property string _mprisArtUrl: _hasTrack && MprisController.activeTrack
        ? MprisController.sanitizeArtUrl(MprisController.activeTrack.artUrl ?? "")
        : ""

    // YouTube thumbnail fallback — derive from xesam:url when MPRIS provides no art.
    // Firefox's MPRIS doesn't include mpris:artUrl for YouTube videos, but does
    // provide xesam:url. We extract the video ID and construct the thumbnail URL.
    readonly property string _trackUrl: _hasTrack
        ? (MprisController.activePlayer?.metadata?.["xesam:url"] ?? "")
        : ""
    readonly property string _youtubeArt: {
        const url = root._trackUrl
        if (!url) return ""
        const m = url.match(/(?:youtube\.com\/(?:watch\?v=|shorts\/|live\/|embed\/)|youtu\.be\/)([a-zA-Z0-9_-]{11})/)
        return m ? "https://i.ytimg.com/vi/" + m[1] + "/maxresdefault.jpg" : ""
    }
    readonly property string _youtubeArtFallback: _youtubeArt.length > 0
        ? _youtubeArt.replace("maxresdefault", "hqdefault") : ""

    // Effective art: MPRIS artUrl → YouTube thumbnail → empty
    // Named artUrlSanitized so existing onArtUrlSanitizedChanged handler works
    // (underscore-prefixed change handlers are unreliable in Quickshell)
    readonly property string artUrlSanitized: _mprisArtUrl.length > 0
        ? _mprisArtUrl : _youtubeArt
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
        // Reset aspect ratio when art clears (no track / no art URL)
        if (artUrlSanitized.length === 0) _currentAspectRatio = 1.0
        if (_artSlotA) {
            _artUrlB = artUrlSanitized
        } else {
            _artUrlA = artUrlSanitized
        }
        _artSlotA = !_artSlotA
    }

    // ── Dynamic aspect ratio ──────────────────────────────────────────────
    // Driven by whichever slot last reported a ready image matching the
    // current artUrlSanitized. Resets to 1.0 when art URL clears (no track).
    property real _currentAspectRatio: 1.0

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
        spacing: 6

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
            // Height tracks artCard so ColumnLayout reflows smoothly as aspect ratio changes
            Layout.preferredHeight: artCard.height
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

            // Art card — centered, dynamic aspect ratio, clipped, rounded
            Rectangle {
                id: artCard
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top

                // ── Dynamic sizing ──────────────────────────────────────
                // Max usable width = artWrapper minus 8px padding each side.
                // Landscape: grow to fill available width (capped at _maxW).
                // Portrait:  hold at _base width, grow taller.
                readonly property real _maxW: artWrapper.width - 16
                readonly property real _base: 200
                readonly property real _w: root._currentAspectRatio >= 1.0
                    ? Math.min(_maxW, _base * root._currentAspectRatio)
                    : _base
                readonly property real _h: _w / root._currentAspectRatio

                width: _w
                height: _h

                // Animate both dimensions using the resize token (300ms, emphasized bezier)
                Behavior on width {
                    enabled: Appearance.animationsEnabled
                    NumberAnimation {
                        duration: Appearance.animation.elementResize.duration
                        easing.type: Appearance.animation.elementResize.type
                        easing.bezierCurve: Appearance.animation.elementResize.bezierCurve
                    }
                }
                Behavior on height {
                    enabled: Appearance.animationsEnabled
                    NumberAnimation {
                        duration: Appearance.animation.elementResize.duration
                        easing.type: Appearance.animation.elementResize.type
                        easing.bezierCurve: Appearance.animation.elementResize.bezierCurve
                    }
                }

                radius: 6
                color: "transparent"
                clip: true
                border.width: 1
                border.color: Appearance.colors.colLayer1

                // Fallback: colSecondaryContainer + music_note — always 200×200 square
                Rectangle {
                    anchors.centerIn: parent
                    width: 200
                    height: 200
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
                    fallbacks: root._youtubeArtFallback.length > 0 ? [root._youtubeArtFallback] : []
                    fillMode: Image.PreserveAspectFit
                    opacity: (root._artSlotA && status === Image.Ready) ? 1.0 : 0.0
                    z: root._artSlotA ? 2 : 1

                    onStatusChanged: {
                        if (status === Image.Ready && source == root.artUrlSanitized) {
                            const r = implicitHeight > 0
                                ? implicitWidth / implicitHeight
                                : 1.0
                            root._currentAspectRatio = r
                        }
                    }

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
                    fallbacks: root._youtubeArtFallback.length > 0 ? [root._youtubeArtFallback] : []
                    fillMode: Image.PreserveAspectFit
                    opacity: (!root._artSlotA && status === Image.Ready) ? 1.0 : 0.0
                    z: root._artSlotA ? 1 : 2

                    onStatusChanged: {
                        if (status === Image.Ready && source == root.artUrlSanitized) {
                            const r = implicitHeight > 0
                                ? implicitWidth / implicitHeight
                                : 1.0
                            root._currentAspectRatio = r
                        }
                    }

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
        // Online (YouTube): bigger title, no album line — video titles need room.
        // Local audio: standard title + artist + album hierarchy.
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3
            visible: root._hasTrack

            // Track title — bigger for YouTube (20px), standard for local (17px)
            Text {
                Layout.fillWidth: true
                text: MprisController.activeTrack?.title ?? ""
                font.pixelSize: root._youtubeArt.length > 0 ? 20 : 17
                font.bold: true
                color: Appearance.colors.colOnLayer1
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                maximumLineCount: 2
                wrapMode: Text.WordWrap
            }

            // Artist — 14px, readable but subordinate to title
            Text {
                Layout.fillWidth: true
                text: MprisController.activeTrack?.artist ?? ""
                font.pixelSize: 14
                color: ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.70)
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                maximumLineCount: 1
            }

            // Album — 12px dim italic, centered (hidden for YouTube — videos don't have albums)
            Text {
                Layout.fillWidth: true
                text: MprisController.activeTrack?.album ?? ""
                font.pixelSize: 12
                font.italic: true
                color: ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.50)
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                maximumLineCount: 1
                visible: root._youtubeArt.length === 0
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
        SectionHeader {
            text: "Signal"
            visible: signalPanel.visible
            Layout.topMargin: root.sectionTopMargin
        }
        SignalPanel {
            id: signalPanel
            Layout.fillWidth: true
        }

        // ── Source Info — player identity + metadata ─────────────────────
        SectionHeader {
            text: "Source"
            visible: root._hasTrack
            Layout.topMargin: root.sectionTopMargin
        }
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 6
            rowSpacing: 6
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
        SectionHeader {
            text: "Up Next"
            visible: queuePreview._visible
            Layout.topMargin: root.sectionTopMargin
        }
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
