pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.services

/**
 * SignalPanel — Audio signal metadata instrument cluster.
 *
 * Reads MPRIS metadata to display FORMAT / RATE / DEPTH / CH / BITRATE / QUEUE.
 * All fields default to "—" — MPRIS metadata coverage varies wildly by player.
 * Collapses entirely when no track is active or no fields are available.
 */
Item {
    id: root

    Layout.fillWidth: true
    implicitHeight: _hasTrack ? _content.implicitHeight : 0

    readonly property bool _hasTrack: MprisController.activePlayer !== null

    // ── Metadata extraction ───────────────────────────────────────────────
    readonly property var _meta: MprisController.activePlayer?.metadata ?? null

    // Format: parsed from xesam:url file extension
    readonly property string _format: {
        const url = (_meta?.["xesam:url"] ?? "").toLowerCase()
        const match = url.match(/\.([a-z0-9]{2,5})(?:\?|#|$)/)
        if (!match) return "—"
        const ext = match[1]
        const known = ["flac", "mp3", "ogg", "opus", "aac", "wav", "m4a", "alac", "ape", "wv", "wma", "mp4"]
        return known.includes(ext) ? ext.toUpperCase() : "—"
    }

    // Sample rate: try common MPRIS keys
    readonly property string _rate: {
        const r = _meta?.["xesam:audioSampleRate"]
            ?? _meta?.["audio-samplerate"]
            ?? _meta?.["xesam:sampleRate"]
            ?? null
        if (!r) return "—"
        const khz = Math.round(Number(r) / 100) / 10
        return isNaN(khz) || khz <= 0 ? "—" : khz + "k"
    }

    // Bit depth
    readonly property string _depth: {
        const d = _meta?.["xesam:audioBitsPerSample"]
            ?? _meta?.["audio-depth"]
            ?? null
        if (!d) return "—"
        const n = Number(d)
        return isNaN(n) || n <= 0 ? "—" : String(n)
    }

    // Channels
    readonly property string _channels: {
        const c = _meta?.["xesam:audioChannels"]
            ?? _meta?.["audio-channels"]
            ?? null
        if (!c) return "—"
        const n = Number(c)
        if (isNaN(n) || n <= 0) return "—"
        if (n === 1) return "MONO"
        if (n === 2) return "ST"
        return String(n) + "ch"
    }

    // Bitrate (reported in bits/sec by some players, kbps by others)
    readonly property string _bitrate: {
        const b = _meta?.["mpris:bitrate"]
            ?? _meta?.["xesam:audioBitrate"]
            ?? _meta?.["bitrate"]
            ?? null
        if (!b) return "—"
        let n = Number(b)
        if (isNaN(n) || n <= 0) return "—"
        // Values > 10000 are likely in bps — convert to kbps
        if (n > 10000) n = Math.round(n / 1000)
        return n + "k"
    }

    // Queue length — YtMusic only, MPRIS trackList not widely implemented
    readonly property string _queue: {
        if (MprisController.isYtMusicActive) {
            const len = YtMusic.queue?.length ?? 0
            return len > 0 ? String(len) : "—"
        }
        return "—"
    }

    readonly property bool _anyAvailable:
        _format !== "—" || _rate !== "—" || _depth !== "—" ||
        _channels !== "—" || _bitrate !== "—"

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
