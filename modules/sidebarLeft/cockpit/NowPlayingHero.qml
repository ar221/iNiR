import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell

/**
 * NowPlayingHero — cockpit top slot (~40% of sidebar height).
 *
 * Session C: full implementation.
 *   - Album art card (square, clipped, rounded at rounding.normal)
 *   - Track title (2-line clamp) + artist (single line) beside art
 *   - 2px progress hairline spanning text column bottom
 *   - Transport row (prev / play-pause / next) centered under art column
 *   - Album-dominant accent ColorQuantizer for progress + play/pause hover
 *   - Art cross-fade via two stacked StyledImage with opposing opacity Behaviors
 *   - Dual MaterialSymbol stack for play/pause icon swap (120ms)
 *   - Collapses to 0 height when no active MPRIS player (80ms exit)
 *
 * Guard: _hasTrack drives on MprisController.activePlayer !== null.
 * (activeTrack is always an object once any player has connected — the
 *  controller resets to "Unknown Title/Artist" on loss, not to null.
 *  activePlayer is the reliable nil sentinel.)
 */
Item {
    id: root

    // ── Layout reactive on player presence ───────────────────────────────
    // Content-sized: art square + transport row + 4px gap.
    // Collapse to 0 when no player. ColumnLayout reflows automatically.
    Layout.fillWidth: true
    Layout.preferredHeight: _hasTrack ? (_artSide + transportRow.implicitHeight + 4) : 0
    Layout.minimumHeight: _hasTrack ? (_artSide + transportRow.implicitHeight + 4) : 0

    // Asymmetric enter (150ms elementMove) / exit (80ms elementMoveExit).
    // _hasTrack already reflects the new value when the Behavior evaluates.
    Behavior on Layout.preferredHeight {
        enabled: Appearance.animationsEnabled
        NumberAnimation {
            duration: root._hasTrack
                ? Appearance.animation.elementMove.duration
                : Appearance.animation.elementMoveExit.duration
            easing.type: root._hasTrack
                ? Appearance.animation.elementMove.type
                : Appearance.animation.elementMoveExit.type
            easing.bezierCurve: root._hasTrack
                ? Appearance.animation.elementMove.bezierCurve
                : Appearance.animation.elementMoveExit.bezierCurve
        }
    }

    // ── Track detection ───────────────────────────────────────────────────
    readonly property bool _hasTrack: MprisController.activePlayer !== null

    // ── Art URL ───────────────────────────────────────────────────────────
    // artUrlSanitized: no leading underscore so onArtUrlSanitizedChanged fires.
    // Sanitize before binding: strips oversized data URIs that crash the loader.
    readonly property string artUrlSanitized: _hasTrack && MprisController.activeTrack
        ? MprisController.sanitizeArtUrl(MprisController.activeTrack.artUrl ?? "")
        : ""
    readonly property bool _hasArt: artUrlSanitized.length > 0

    // ── Art side: 35% of hero width, min 80px ────────────────────────────
    // Width-only binding — avoids circular dependency with topRow.height
    // (which is now derived from _artSide, not the other way around).
    // Text column guaranteed ≥ 65% of root.width.
    readonly property real _artSide: Math.max(80, root.width * 0.35)

    // ── Accent color extraction ───────────────────────────────────────────
    // Independent quantizer — AmbientBackground._artColor has alpha pre-applied
    // (12% wash). We need raw dominant for accents at full opacity.
    ColorQuantizer {
        id: heroAccentQuant
        source: root._hasArt ? root.artUrlSanitized : ""
        depth: 0        // 2^0 = 1 colour — dominant bucket only
        rescaleSize: 1
    }

    readonly property color _accentRaw: heroAccentQuant.colors.length > 0
        ? heroAccentQuant.colors[0]
        : Appearance.colors.colPrimary

    // ── Art cross-fade slot tracker ───────────────────────────────────────
    // Two StyledImage slots alternate as front/back. When artUrl changes:
    //   1. New URL loads into the back slot (opacity 0, invisible)
    //   2. _artSlotA flips — the newly-loaded image becomes front
    //   3. Opposing Behaviors cross-fade old→new over 150ms
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

    // ── Expand signal (wired in Session F) ───────────────────────────────
    signal expandRequested()

    // ── Outer expand MouseArea ────────────────────────────────────────────
    // Z=0 — sits below transport buttons. RippleButton's internal MouseArea
    // consumes presses before they reach this area.
    MouseArea {
        anchors.fill: parent
        z: 0
        hoverEnabled: false
        onClicked: root.expandRequested()
    }

    // ── Top row: art wrapper + text column ───────────────────────────────
    // Fills hero minus transport shim at bottom.
    RowLayout {
        id: topRow
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: transportShim.top
        anchors.bottomMargin: 4
        spacing: Appearance.font.pixelSize.normal  // ~16px

        // ── Art wrapper — explicitly square at _artSide × _artSide ─────────
        // NOT fillHeight — hero height is now derived from _artSide, so
        // fillHeight would be circular. Fixed preferred height = preferred width.
        Item {
            id: artWrapper
            Layout.fillHeight: false
            Layout.preferredWidth: root._artSide
            Layout.preferredHeight: root._artSide
            Layout.minimumWidth: 0

            // Shadow positioned behind artCard
            StyledRectangularShadow {
                target: artCard
                blur: Appearance.auroraEverywhere ? 20 : 12
                color: Qt.rgba(0, 0, 0, Appearance.auroraEverywhere ? 0.65 : 0.45)
                offset: Qt.vector2d(0, 4)
                radius: artCard.radius
            }

            // Art card — fills artWrapper, clipped, rounded
            Rectangle {
                id: artCard
                anchors.fill: parent
                radius: Appearance.rounding.normal  // 4px scaled
                color: "transparent"
                clip: true

                // ── Fallback tile: solid colSecondaryContainer + music_note glyph
                // Sits below the art images; shows through when art fails/absent.
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: Appearance.colors.colSecondaryContainer
                    z: 0

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "music_note"
                        iconSize: Appearance.font.pixelSize.huge * 2.5
                        color: ColorUtils.applyAlpha(
                            Appearance.colors.colOnSecondaryContainer, 0.6)
                    }
                }

                // ── Art slot A ────────────────────────────────────────────
                StyledImage {
                    id: artImageA
                    anchors.fill: parent
                    source: root._artUrlA
                    fillMode: Image.PreserveAspectCrop
                    // Override StyledImage's built-in opacity so we control
                    // cross-fade ourselves. Show only when this is the front slot
                    // AND the image has actually loaded.
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

                // ── Art slot B ────────────────────────────────────────────
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

        // ── Text column: title / artist / progress ────────────────────────
        ColumnLayout {
            id: textColumn
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Track title — top-aligned, 2-line clamp, title font
            Text {
                id: titleText
                Layout.fillWidth: true
                text: MprisController.activeTrack?.title ?? ""
                color: Appearance.colors.colOnLayer1
                font.family: Appearance.font.family.title
                font.pixelSize: Appearance.font.pixelSize.larger   // 19px
                maximumLineCount: 2
                wrapMode: Text.WordWrap
                elide: Text.ElideRight
                lineHeightMode: Text.FixedHeight
                lineHeight: font.pixelSize * 1.25
            }

            // Gap between title and artist
            Item {
                Layout.preferredHeight: Appearance.font.pixelSize.smaller  // ~12px
            }

            // Artist — single line, subdued
            Text {
                id: artistText
                Layout.fillWidth: true
                text: MprisController.activeTrack?.artist ?? ""
                color: Appearance.colors.colOnLayer1Inactive
                font.family: Appearance.font.family.main
                font.pixelSize: Appearance.font.pixelSize.normal   // 16px
                maximumLineCount: 1
                elide: Text.ElideRight
            }

            // Push progress hairline to bottom of text column.
            // textColumn.height == artWrapper.height (both fill topRow),
            // so progressContainer.bottom == artCard.bottom. Spec §2 achieved.
            Item { Layout.fillHeight: true }

            // Progress hairline — 2px, accent-tinted, spans text column width
            Item {
                id: progressContainer
                Layout.fillWidth: true
                implicitHeight: 2
                height: 2

                // Track (background) — accent hue at 18% alpha
                Rectangle {
                    anchors.fill: parent
                    color: ColorUtils.applyAlpha(root._accentRaw, 0.18)
                    Behavior on color {
                        enabled: Appearance.animationsEnabled
                        ColorAnimation {
                            duration: Appearance.animation.elementMove.duration
                            easing.type: Appearance.animation.elementMove.type
                            easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                        }
                    }
                }

                // Fill — accent at full opacity, width = ratio × container width
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom

                    readonly property real _ratio: MprisController.activeLength > 0
                        ? Math.max(0, Math.min(1,
                            MprisController.activePosition / MprisController.activeLength))
                        : 0.0

                    width: progressContainer.width * _ratio
                    color: root._accentRaw

                    Behavior on width {
                        enabled: Appearance.animationsEnabled
                        NumberAnimation {
                            duration: Appearance.animation.elementMoveEnter.duration
                            easing.type: Appearance.animation.elementMoveEnter.type
                            easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
                        }
                    }
                    Behavior on color {
                        enabled: Appearance.animationsEnabled
                        ColorAnimation {
                            duration: Appearance.animation.elementMove.duration
                            easing.type: Appearance.animation.elementMove.type
                            easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                        }
                    }
                }
            }
        }
    }

    // ── Transport shim — at least as wide as transport row ───────────────
    // Left-aligned. Width = max(artWrapper, transport row implicit) so if
    // transport overflows art width on narrow sidebars it still fits.
    // z: 1 — above outer MouseArea so RippleButton clicks win.
    Item {
        id: transportShim
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: Math.max(artWrapper.width, transportRow.implicitWidth)
        height: transportRow.implicitHeight
        z: 1

        RowLayout {
            id: transportRow
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            spacing: Appearance.font.pixelSize.large  // ~17px between glyphs

            // Previous
            RippleButton {
                id: prevButton
                implicitWidth: 36
                implicitHeight: 36
                colBackground: "transparent"
                colBackgroundHover: Appearance.colors.colLayer1Hover
                enabled: MprisController.canGoPrevious
                onClicked: MprisController.previous()

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "skip_previous"
                    iconSize: Appearance.font.pixelSize.larger
                    color: prevButton.enabled
                        ? (prevButton.buttonHovered
                            ? Appearance.colors.colOnLayer1
                            : Appearance.colors.colOnLayer1Inactive)
                        : Appearance.colors.colOnLayer1Inactive
                }
            }

            // Play / Pause — dual-symbol stack for smooth icon swap
            RippleButton {
                id: playPauseButton
                implicitWidth: 36
                implicitHeight: 36
                colBackground: "transparent"
                colBackgroundHover: Appearance.colors.colLayer1Hover
                onClicked: MprisController.togglePlaying()
                z: 1

                // play_arrow — visible when paused
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "play_arrow"
                    iconSize: Appearance.font.pixelSize.huge  // 22px — anchor
                    color: playPauseButton.buttonHovered ? root._accentRaw : Appearance.colors.colOnLayer1
                    opacity: MprisController.isPlaying ? 0.0 : 1.0
                    Behavior on opacity {
                        enabled: Appearance.animationsEnabled
                        NumberAnimation {
                            duration: Appearance.animation.elementMoveEnter.duration
                            easing.type: Appearance.animation.elementMoveEnter.type
                            easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
                        }
                    }
                    Behavior on color {
                        enabled: Appearance.animationsEnabled
                        ColorAnimation {
                            duration: Appearance.animation.elementMoveEnter.duration
                            easing.type: Appearance.animation.elementMoveEnter.type
                            easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
                        }
                    }
                }

                // pause — visible when playing
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "pause"
                    iconSize: Appearance.font.pixelSize.huge
                    color: playPauseButton.buttonHovered ? root._accentRaw : Appearance.colors.colOnLayer1
                    opacity: MprisController.isPlaying ? 1.0 : 0.0
                    Behavior on opacity {
                        enabled: Appearance.animationsEnabled
                        NumberAnimation {
                            duration: Appearance.animation.elementMoveEnter.duration
                            easing.type: Appearance.animation.elementMoveEnter.type
                            easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
                        }
                    }
                    Behavior on color {
                        enabled: Appearance.animationsEnabled
                        ColorAnimation {
                            duration: Appearance.animation.elementMoveEnter.duration
                            easing.type: Appearance.animation.elementMoveEnter.type
                            easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
                        }
                    }
                }
            }

            // Next
            RippleButton {
                id: nextButton
                implicitWidth: 36
                implicitHeight: 36
                colBackground: "transparent"
                colBackgroundHover: Appearance.colors.colLayer1Hover
                enabled: MprisController.canGoNext
                onClicked: MprisController.next()

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "skip_next"
                    iconSize: Appearance.font.pixelSize.larger
                    color: nextButton.enabled
                        ? (nextButton.buttonHovered
                            ? Appearance.colors.colOnLayer1
                            : Appearance.colors.colOnLayer1Inactive)
                        : Appearance.colors.colOnLayer1Inactive
                }
            }
        }
    }
}

