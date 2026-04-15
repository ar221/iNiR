pragma ComponentBehavior: Bound

import QtQuick
import qs
import QtQuick.Layouts
import Quickshell.Io
import qs.modules.common
import qs.services

/**
 * SignalPanel — Audio signal metadata instrument cluster.
 *
 * Primary: reads MPRIS metadata for FORMAT / RATE / DEPTH / CH / BITRATE.
 * Fallback: when MPRIS metadata is sparse (most players), runs ffprobe on
 * the track URL (local files only) to extract codec details directly.
 *
 * ffprobe runs once per track change, gated on sidebar visibility.
 */
Item {
    id: root

    Layout.fillWidth: true
    implicitHeight: _hasTrack ? _content.implicitHeight : 0

    readonly property bool _hasTrack: MprisController.activePlayer !== null

    // ── MPRIS metadata ───────────────────────────────────────────────────
    readonly property var _meta: MprisController.activePlayer?.metadata ?? null
    readonly property string _trackUrl: _meta?.["xesam:url"] ?? ""

    // ── ffprobe fallback data ────────────────────────────────────────────
    property string _probeCodec: ""
    property string _probeRate: ""
    property string _probeDepth: ""
    property string _probeChannels: ""
    property string _probeBitrate: ""
    property string _lastProbedUrl: ""

    // Run ffprobe when track URL changes (local files only)
    onTrackUrlChanged: {
        if (!_trackUrl || !_trackUrl.startsWith("file://")) {
            _clearProbe()
            return
        }
        if (_trackUrl === _lastProbedUrl) return
        _lastProbedUrl = _trackUrl
        probeProc.running = true
    }

    function _clearProbe() {
        _probeCodec = ""
        _probeRate = ""
        _probeDepth = ""
        _probeChannels = ""
        _probeBitrate = ""
        _lastProbedUrl = ""
    }

    Process {
        id: probeProc
        command: ["bash", "-c",
            "ffprobe -v quiet -print_format json -show_format -show_streams \"" +
            root._trackUrl.replace("file://", "") + "\" 2>/dev/null"
        ]
        running: false
        stdout: StdioCollector {
            id: probeCollector
            onStreamFinished: {
                try {
                    const d = JSON.parse(probeCollector.text)
                    const s = d.streams?.[0] ?? {}
                    const f = d.format ?? {}
                    root._probeCodec = (s.codec_name ?? "").toUpperCase()
                    const rate = Number(s.sample_rate ?? 0)
                    root._probeRate = rate > 0
                        ? (Math.round(rate / 100) / 10) + "k" : ""
                    const depth = Number(s.bits_per_raw_sample ?? s.bits_per_sample ?? 0)
                    root._probeDepth = depth > 0 ? String(depth) : ""
                    const ch = Number(s.channels ?? 0)
                    root._probeChannels = ch === 1 ? "MONO"
                        : ch === 2 ? "ST" : ch > 0 ? ch + "ch" : ""
                    let br = Number(f.bit_rate ?? s.bit_rate ?? 0)
                    root._probeBitrate = br > 0
                        ? Math.round(br / 1000) + "k" : ""
                } catch (e) {
                    // ffprobe failed or not installed — silent
                }
            }
        }
    }

    // ── Resolved values: MPRIS first, ffprobe fallback ───────────────────

    // Format: MPRIS url extension → ffprobe codec
    readonly property string _format: {
        const url = (_trackUrl ?? "").toLowerCase()
        const match = url.match(/\.([a-z0-9]{2,5})(?:\?|#|$)/)
        if (match) {
            const ext = match[1]
            const known = ["flac", "mp3", "ogg", "opus", "aac", "wav",
                           "m4a", "alac", "ape", "wv", "wma", "mp4"]
            if (known.includes(ext)) return ext.toUpperCase()
        }
        return _probeCodec || "—"
    }

    readonly property string _rate: {
        const r = _meta?.["xesam:audioSampleRate"]
            ?? _meta?.["audio-samplerate"] ?? null
        if (r) {
            const khz = Math.round(Number(r) / 100) / 10
            if (!isNaN(khz) && khz > 0) return khz + "k"
        }
        return _probeRate || "—"
    }

    readonly property string _depth: {
        const d = _meta?.["xesam:audioBitsPerSample"]
            ?? _meta?.["audio-depth"] ?? null
        if (d) {
            const n = Number(d)
            if (!isNaN(n) && n > 0) return String(n)
        }
        return _probeDepth || "—"
    }

    readonly property string _channels: {
        const c = _meta?.["xesam:audioChannels"]
            ?? _meta?.["audio-channels"] ?? null
        if (c) {
            const n = Number(c)
            if (!isNaN(n) && n > 0)
                return n === 1 ? "MONO" : n === 2 ? "ST" : n + "ch"
        }
        return _probeChannels || "—"
    }

    readonly property string _bitrate: {
        const b = _meta?.["mpris:bitrate"]
            ?? _meta?.["xesam:audioBitrate"] ?? null
        if (b) {
            let n = Number(b)
            if (!isNaN(n) && n > 0) {
                if (n > 10000) n = Math.round(n / 1000)
                return n + "k"
            }
        }
        return _probeBitrate || "—"
    }

    // Queue length — YtMusic only
    readonly property string _queue: {
        if (MprisController.isYtMusicActive) {
            const len = YtMusic.queue?.length ?? 0
            return len > 0 ? String(len) : "—"
        }
        return "—"
    }

    visible: _hasTrack
    opacity: visible ? 1.0 : 0.0

    Behavior on implicitHeight {
        enabled: Appearance.animationsEnabled
        NumberAnimation {
            duration: Appearance.animation.elementMove.duration
            easing.type: Appearance.animation.elementMove.type
            easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
        }
    }
    Behavior on opacity {
        enabled: Appearance.animationsEnabled
        NumberAnimation { duration: 120 }
    }

    // ── Content ───────────────────────────────────────────────────────────
    ColumnLayout {
        id: _content
        width: parent.width
        spacing: 4

        // Top row: FORMAT / RATE / DEPTH / CH
        GridLayout {
            Layout.fillWidth: true
            columns: 4
            columnSpacing: 4
            rowSpacing: 0

            InstrumentCell { label: "FORMAT"; value: root._format }
            InstrumentCell { label: "RATE";   value: root._rate   }
            InstrumentCell { label: "DEPTH";  value: root._depth  }
            InstrumentCell { label: "CH";     value: root._channels }
        }

        // Bottom row: BITRATE / QUEUE
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            InstrumentCell { label: "BITRATE"; value: root._bitrate }
            InstrumentCell { label: "QUEUE";   value: root._queue   }
        }
    }
}
