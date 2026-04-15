pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.modules.common
import qs.services

/**
 * SpectrumVisualizer — Animated fallback spectrum display.
 *
 * 24 bars split into left (12) and right (12) channels.
 * Bars animate with staggered sine-wave patterns when playing.
 * Paused: animations freeze at current heights.
 * No track: collapses to height 0 with an 80ms exit animation.
 *
 * CAVA integration is Task 13 (stretch). This is the pure-QML fallback.
 */
Item {
    id: root

    Layout.fillWidth: true

    readonly property bool _isPlaying: MprisController.isPlaying
    readonly property bool _hasTrack: MprisController.activePlayer !== null

    // Container height: 110px bars + 20px reflection + 4px gap
    readonly property int _barHeight: 110
    readonly property int _reflHeight: 20
    readonly property int _totalHeight: _barHeight + _reflHeight + 4

    implicitHeight: _hasTrack ? _totalHeight : 0

    clip: true

    Behavior on implicitHeight {
        enabled: Appearance.animationsEnabled
        NumberAnimation {
            duration: _hasTrack ? 150 : 80
            easing.type: Easing.InOutQuad
        }
    }

    // ── Bar data model ────────────────────────────────────────────────────
    // Per-bar config: min height, max height, animation duration.
    // Center bars are taller for a natural spectral curve.
    readonly property var _barConfig: {
        const n = 24
        const cfg = []
        for (let i = 0; i < n; i++) {
            // Distance from center (0–11), normalised 0–1
            const dist = Math.abs(i - (n - 1) / 2) / ((n - 1) / 2)
            const maxH = Math.round((1.0 - dist * 0.65) * _barHeight)
            const minH = Math.max(2, Math.round(maxH * 0.08))
            // Stagger duration across bars: 1.6s–2.4s
            const dur = 1600 + i * 33
            cfg.push({ minH, maxH, dur })
        }
        return cfg
    }

    // ── Bar gap and width ─────────────────────────────────────────────────
    readonly property real _gap: 2
    readonly property real _barWidth: (width - (_gap * 23)) / 24

    // ── Main bar container ────────────────────────────────────────────────
    Rectangle {
        id: barContainer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root._barHeight
        color: Appearance.colors.colLayer0
        border.width: 1
        border.color: Appearance.colors.colLayer1
        radius: 4
        clip: true

        Row {
            anchors.fill: parent
            anchors.margins: 0
            spacing: root._gap

            Repeater {
                id: barRepeater
                model: 24

                Rectangle {
                    id: barRect
                    required property int index

                    readonly property var _cfg: root._barConfig[index] ?? { minH: 2, maxH: root._barHeight, dur: 2000 }

                    // Left channel: indices 0–11, Right: 12–23
                    readonly property bool _isLeft: index < 12

                    width: root._barWidth
                    height: _anim.currentValue
                    anchors.bottom: parent.bottom
                    radius: 1

                    color: _isLeft
                        ? Qt.rgba(1.0, 0.15 + index * 0.04, 0.0, 1.0)
                        : Qt.rgba(1.0, 0.27 + (index - 12) * 0.04, 0.0, 0.70)

                    // ── Animated height via NumberAnimation ───────────────
                    property real _targetHigh: _cfg.maxH
                    property real _targetLow:  _cfg.minH

                    NumberAnimation {
                        id: _anim
                        target: barRect
                        property: "height"
                        from: barRect._targetLow
                        to: barRect._targetHigh
                        duration: barRect._cfg.dur
                        easing.type: Easing.InOutSine
                        loops: Animation.Infinite
                        running: root._hasTrack && root._isPlaying
                        paused: !root._isPlaying

                        onFinished: {
                            // Alternate between low→high and high→low for natural motion
                            const tmp = barRect._targetHigh
                            barRect._targetHigh = barRect._targetLow
                            barRect._targetLow = tmp
                        }
                    }

                    // Offset start time so bars don't all peak simultaneously
                    Component.onCompleted: {
                        _anim.from = _cfg.minH + Math.random() * (_cfg.maxH - _cfg.minH)
                        _anim.to   = _cfg.minH + Math.random() * (_cfg.maxH - _cfg.minH)
                    }
                }
            }
        }
    }

    // ── Reflection ────────────────────────────────────────────────────────
    Item {
        id: reflContainer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: barContainer.bottom
        anchors.topMargin: 4
        height: root._reflHeight
        clip: true
        opacity: 0.15

        // Reflect the bar row
        ShaderEffectSource {
            id: barMirrorSource
            sourceItem: barContainer
            hideSource: false
            visible: false
        }

        ShaderEffect {
            anchors.fill: parent
            property var src: barMirrorSource
            // Flip vertically and fade to transparent at bottom
            fragmentShader: "
                uniform sampler2D src;
                uniform float qt_Opacity;
                varying vec2 qt_TexCoord0;
                void main() {
                    // Sample from bottom of source (flipped)
                    float srcY = 1.0 - qt_TexCoord0.y * (float(" + root._reflHeight + ") / float(" + root._barHeight + "));
                    vec4 col = texture2D(src, vec2(qt_TexCoord0.x, srcY));
                    // Fade to transparent toward bottom of reflection
                    float fade = 1.0 - qt_TexCoord0.y;
                    gl_FragColor = col * fade * qt_Opacity;
                }
            "
        }
    }
}
