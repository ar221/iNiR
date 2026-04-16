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
 * Local mode (file://):
 *   Primary: reads MPRIS metadata for FORMAT / RATE / DEPTH / CH / BITRATE.
 *   Fallback: ffprobe on the track URL to extract codec details directly.
 *   ffprobe runs once per track change, gated on sidebar visibility.
 *
 * Online mode (youtube.com / youtu.be):
 *   Shows: Author · Platform · Duration
 *   Author: oEmbed author_name → MPRIS artist → "—"
 *   Platform: "YouTube Music" for music.youtube.com, "YouTube" otherwise.
 *   Duration: from MprisController.activeLength.
 *   oEmbed runs once per URL change via curl, cached by URL.
 */
Item {
    id: root

    Layout.fillWidth: true
    implicitHeight: _hasTrack ? _content.implicitHeight : 0

    readonly property bool _hasTrack: MprisController.activePlayer !== null

    // ── MPRIS metadata ───────────────────────────────────────────────────
    readonly property var _meta: MprisController.activePlayer?.metadata ?? null
    // No underscore — so onTrackUrlChanged handler works in Quickshell
    readonly property string trackUrl: _meta?.["xesam:url"] ?? ""

    // ── Mode detection ───────────────────────────────────────────────────
    readonly property bool _isOnline: {
        const u = trackUrl
        return u.includes("youtube.com") || u.includes("youtu.be")
    }

    // ── Online strip data ────────────────────────────────────────────────
    readonly property string _platform: {
        if (trackUrl.includes("music.youtube.com")) return "YouTube Music"
        if (trackUrl.includes("youtube.com") || trackUrl.includes("youtu.be")) return "YouTube"
        return ""
    }

    // oEmbed cache
    property string _oembedAuthor: ""
    property string _lastOembedUrl: ""

    // Resolved author: oEmbed → MPRIS artist → "—"
    readonly property string _author: {
        if (_oembedAuthor) return _oembedAuthor
        const artist = MprisController.activeTrack?.artist ?? ""
        return artist || "—"
    }

    // Duration format: M:SS or H:MM:SS
    function _formatDuration(seconds: real): string {
        const s = Math.max(0, Math.floor(seconds))
        const h = Math.floor(s / 3600)
        const m = Math.floor((s % 3600) / 60)
        const sec = s % 60
        if (h > 0)
            return h + ":" + String(m).padStart(2, "0") + ":" + String(sec).padStart(2, "0")
        return m + ":" + String(sec).padStart(2, "0")
    }

    // ── oEmbed fetch ─────────────────────────────────────────────────────
    function _tryOembed(): void {
        const url = trackUrl
        if (!_isOnline) {
            _oembedAuthor = ""
            _lastOembedUrl = ""
            return
        }
        if (url === _lastOembedUrl) return
        _lastOembedUrl = url
        _oembedAuthor = ""   // clear stale while fetching
        oembedProc.command = [
            "curl", "-sf",
            "https://www.youtube.com/oembed?url=" + encodeURIComponent(url) + "&format=json"
        ]
        oembedProc.running = true
    }

    Process {
        id: oembedProc
        command: ["true"]
        running: false
        stdout: StdioCollector {
            id: oembedCollector
            onStreamFinished: {
                try {
                    const d = JSON.parse(oembedCollector.text)
                    if (d.author_name) root._oembedAuthor = d.author_name
                } catch (e) {
                    // oEmbed failed — silent, fallback to MPRIS artist
                }
            }
        }
    }

    // ── ffprobe fallback data ────────────────────────────────────────────
    property string _probeCodec: ""
    property string _probeRate: ""
    property string _probeDepth: ""
    property string _probeChannels: ""
    property string _probeBitrate: ""
    property string _lastProbedUrl: ""

    // Run ffprobe when track URL changes (local files only)
    function tryProbe() {
        if (!trackUrl || !trackUrl.startsWith("file://")) {
            _clearProbe()
            return
        }
        if (trackUrl === _lastProbedUrl) return
        _lastProbedUrl = trackUrl
        const localPath = trackUrl.replace("file://", "")
        probeProc.command = ["bash", "-c",
            "ffprobe -v quiet -print_format json -show_format -show_streams " +
            "'" + localPath.replace(/'/g, "'\\''") + "'"
        ]
        probeProc.running = true
    }

    onTrackUrlChanged: {
        tryProbe()
        _tryOembed()
    }

    // Also trigger when becoming visible (URL may already be set when sidebar opens)
    onVisibleChanged: {
        if (visible && trackUrl) {
            if (_lastProbedUrl !== trackUrl) tryProbe()
            if (_lastOembedUrl !== trackUrl) _tryOembed()
        }
    }
    Component.onCompleted: {
        if (trackUrl) {
            tryProbe()
            _tryOembed()
        }
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
        command: ["true"]  // placeholder — set dynamically in onTrackUrlChanged
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

    // ── Resolved local values: MPRIS first, ffprobe fallback ─────────────

    // Format: MPRIS url extension → ffprobe codec
    readonly property string _format: {
        const url = (trackUrl ?? "").toLowerCase()
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

        // ── Online instrument grid (YouTube / YouTube Music) ──────────────
        GridLayout {
            Layout.fillWidth: true
            columns: 3
            columnSpacing: 4
            rowSpacing: 0
            visible: root._isOnline

            InstrumentCell { label: "CHANNEL";  value: root._author }
            InstrumentCell { label: "SOURCE";   value: root._platform || "—" }
            InstrumentCell {
                label: "DURATION"
                value: MprisController.activeLength > 0
                    ? root._formatDuration(MprisController.activeLength) : "—"
            }
        }

        // ── Local instrument grid (file:// sources) ───────────────────────

        // Top row: FORMAT / RATE / DEPTH / CH
        GridLayout {
            Layout.fillWidth: true
            columns: 4
            columnSpacing: 4
            rowSpacing: 0
            visible: !root._isOnline

            InstrumentCell { label: "FORMAT"; value: root._format }
            InstrumentCell { label: "RATE";   value: root._rate   }
            InstrumentCell { label: "DEPTH";  value: root._depth  }
            InstrumentCell { label: "CH";     value: root._channels }
        }

        // Bottom row: BITRATE / QUEUE
        RowLayout {
            Layout.fillWidth: true
            spacing: 4
            visible: !root._isOnline

            InstrumentCell { label: "BITRATE"; value: root._bitrate }
            InstrumentCell { label: "QUEUE";   value: root._queue   }
        }
    }
}
