import qs.modules.common
import qs.modules.common.functions
import qs.services
import QtQuick
import Quickshell

/**
 * AmbientBackground — the Deck sidebar's skin.
 *
 * Two-layer stack (bottom → top), all siblings inside a full-bleed Item:
 *   0. Base gradient:   colLayer1 (top) → mix(colLayer1, colPrimary, 0.12) (bottom). Always solid.
 *   1. Album-art wash:  transparent (top) → extracted dominant @ 8% alpha (bottom). Gated on artUrl.
 *
 * The wallpaper-accent (colTertiary) layer from the cockpit is intentionally omitted — it competed
 * with the album wash and added visual noise. The #ff1100 accent provides energy; surfaces stay dark.
 *
 * Aurora/angel halve wash opacity (6%) — blurred compositor shows through base.
 * Base becomes 60% opaque on aurora to let the blur bleed through.
 *
 * Motion: only album-art wash cross-fades on track change.
 *   Enter/change: 150ms quint-out (Appearance.animation.elementMove).
 *   Exit (art gone): 80ms emphasizedAccel (Appearance.animation.elementMoveExit).
 *   No Behavior on base colors — matugen owns that repaint cycle.
 */
Item {
    id: root
    anchors.fill: parent

    // ── Derived intensities ───────────────────────────────────────────────
    // auroraEverywhere is true for both aurora + angel styles.
    readonly property bool _isGlass: Appearance.auroraEverywhere
    // Tighter album alpha vs cockpit (8% normal / 6% aurora) — spec §4 deck-specific.
    readonly property real _albumAlpha: _isGlass ? 0.06 : 0.08

    // ── Album-art extraction ──────────────────────────────────────────────
    // artUrl from activeTrack; may be empty if no player or no art available.
    // Guard: pass empty string to ColorQuantizer rather than resolving — Qt.resolvedUrl
    // may mangle HTTP URLs (MPRIS players report file:// and https:// alike).
    readonly property string _artUrl: MprisController.activeTrack?.artUrl ?? ""
    readonly property bool   _hasArt: _artUrl.length > 0

    ColorQuantizer {
        id: artColorQuant
        // Only bind source when art is present; empty string suppresses load warnings.
        source: root._hasArt ? root._artUrl : ""
        depth: 0       // 2^0 = 1 colour — dominant bucket only, same as wallpaper quant
        rescaleSize: 1 // Tiny rescale; we only care about dominant hue, not fine detail
    }

    // Dominant colour from quantiser, or fallback to colTertiary if extraction fails
    // (empty colors list = quantiser not ready or art failed to load → layer stays hidden).
    readonly property bool  _artColorReady: artColorQuant.colors.length > 0
    readonly property color _artColor: _artColorReady
        ? ColorUtils.applyAlpha(artColorQuant.colors[0], root._albumAlpha)
        : ColorUtils.applyAlpha(Appearance.colors.colTertiary, root._albumAlpha)

    // ── Layer 0: Base gradient ────────────────────────────────────────────
    // Vertical top→bottom: floor colour at top, warm-shifted variant at bottom.
    // Aurora: base becomes semi-transparent so compositor blur bleeds through.
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: root._isGlass
                    ? ColorUtils.transparentize(Appearance.colors.colLayer1, 0.4)
                    : Appearance.colors.colLayer1
            }
            GradientStop {
                position: 1.0
                // mix(colLayer1, colPrimary, 0.12) = 88% layer1 + 12% primary.
                // On aurora: transparentize the already-mixed value by 0.4.
                color: root._isGlass
                    ? ColorUtils.transparentize(
                        ColorUtils.mix(Appearance.colors.colLayer1, Appearance.colors.colPrimary, 0.12),
                        0.4)
                    : ColorUtils.mix(Appearance.colors.colLayer1, Appearance.colors.colPrimary, 0.12)
            }
        }
    }

    // ── Layer 1: Album-art wash ───────────────────────────────────────────
    // Transparent at top → extracted dominant colour at _albumAlpha opacity at bottom.
    // Visible only when artUrl is set (playing OR paused with art — paused != dead).
    // Opacity transitions asymmetrically: 150ms enter, 80ms exit.
    Rectangle {
        id: albumWash
        anchors.fill: parent

        // _showWash: art present AND colour extraction succeeded.
        // Falls back to colTertiary if quantiser fails (spec §3 fallback chain), but only
        // shows if we have a non-empty artUrl — avoids a phantom wash with no track.
        readonly property bool _showWash: root._hasArt

        opacity: _showWash ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation {
                // Asymmetric: 150ms enter (elementMove), 80ms exit (elementMoveExit).
                // QML evaluates Behavior properties when the transition starts, at which
                // point albumWash._showWash already reflects the new value.
                duration: albumWash._showWash
                    ? Appearance.animation.elementMove.duration
                    : Appearance.animation.elementMoveExit.duration
                easing.type: albumWash._showWash
                    ? Appearance.animation.elementMove.type
                    : Appearance.animation.elementMoveExit.type
                easing.bezierCurve: albumWash._showWash
                    ? Appearance.animation.elementMove.bezierCurve
                    : Appearance.animation.elementMoveExit.bezierCurve
            }
        }

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: "transparent"
            }
            GradientStop {
                id: albumStop
                position: 1.0
                color: root._artColor
                // Cross-fade on track change / art reload — 150ms quint-out.
                Behavior on color {
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
