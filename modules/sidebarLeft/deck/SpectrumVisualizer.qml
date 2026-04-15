pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Io
import qs
import qs.modules.common
import qs.services

/**
 * SpectrumVisualizer — Spectrum display with CAVA integration.
 *
 * Primary mode: CAVA-driven real spectrum data (24 bars, 30fps).
 * Fallback mode: staggered sine-wave animations (when CAVA unavailable or disabled).
 *
 * CAVA process is gated: only runs when sidebar is open AND music is playing.
 * Switch between modes via the `cavaActive` flag — no animation code removed.
 *
 * 24 bars split into left (12) and right (12) channels.
 * Paused: animations freeze at current heights.
 * No track: collapses to height 0 with an 80ms exit animation.
 */
Item {
    id: root

    Layout.fillWidth: true

    readonly property bool _isPlaying: MprisController.isPlaying
    readonly property bool _hasTrack: MprisController.activePlayer !== null

    // ── CAVA integration ──────────────────────────────────────────────────
    // User can disable via config.json: sidebar.deck.visualizer.useCava = false
    property bool useCava: Config.options?.sidebar?.deck?.visualizer?.useCava ?? true

    // Live CAVA state
    property var cavaValues: new Array(24).fill(0)
    property bool cavaActive: false

    // Write CAVA config on first run, then start the process
    Process {
        id: configWriter
        command: [
            "bash", "-c",
            "printf '[general]\\nbars = 24\\nframerate = 30\\n[output]\\nmethod = raw\\nraw_target = /dev/stdout\\ndata_format = ascii\\nascii_max_range = 255\\n[smoothing]\\nnoise_reduction = 77\\n' > /tmp/cava-inir.conf"
        ]
        running: false
    }

    Process {
        id: cavaProc
        command: ["cava", "-p", "/tmp/cava-inir.conf"]
        // Gate: only run when sidebar is open, music is playing, and CAVA is enabled
        running: root.useCava && GlobalStates.sidebarLeftOpen && root._hasTrack && root._isPlaying
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                const trimmed = data.trim().replace(/;$/, "")
                if (trimmed.length === 0) return
                const parts = trimmed.split(";")
                if (parts.length !== 24) return
                const vals = parts.map(v => parseInt(v) || 0)
                root.cavaValues = vals
                root.cavaActive = true
            }
        }
        onRunningChanged: {
            if (!running) root.cavaActive = false
        }
    }

    Component.onCompleted: {
        if (root.useCava) configWriter.running = true
    }

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
                    anchors.bottom: parent.bottom
                    radius: 1

                    // ── CAVA-driven height ────────────────────────────────
                    // When CAVA is active, map 0-255 range to bar pixel height.
                    // Clamped to minimum 2px so bars never fully disappear.
                    property real cavaHeight: Math.max(2, (root.cavaValues[index] / 255) * root._barHeight)

                    // Smooth CAVA transitions at ~30fps to avoid jagginess
                    Behavior on cavaHeight {
                        enabled: root.cavaActive
                        NumberAnimation { duration: 33 }
                    }

                    // ── Fallback: animated height via NumberAnimation ──────
                    // Animates an intermediate property to avoid binding conflict on `height`.
                    // The binding on `height` would win over a direct animation target — using
                    // fallbackHeight as the animation target keeps both modes independent.
                    property real fallbackHeight: _cfg.minH
                    property real _targetHigh: _cfg.maxH
                    property real _targetLow:  _cfg.minH

                    // Switch between CAVA data and fallback sine-wave animation
                    height: root.cavaActive ? cavaHeight : fallbackHeight

                    color: _isLeft
                        ? Qt.rgba(1.0, 0.15 + index * 0.04, 0.0, 1.0)
                        : Qt.rgba(1.0, 0.27 + (index - 12) * 0.04, 0.0, 0.70)

                    NumberAnimation {
                        id: _anim
                        target: barRect
                        property: "fallbackHeight"
                        from: barRect._targetLow
                        to: barRect._targetHigh
                        duration: barRect._cfg.dur
                        easing.type: Easing.InOutSine
                        loops: Animation.Infinite
                        running: root._hasTrack && !root.cavaActive
                        paused: running && !root._isPlaying

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
