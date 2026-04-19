pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

/**
 * EasyEffects — service availability + socket IPC.
 *
 * Two layers stacked in one singleton:
 *
 *   1. Availability/lifecycle (pre-existing):
 *      - Detects native vs flatpak install, polls process presence,
 *        starts/stops the daemon (--service-mode).
 *      - Properties: available, active, nativeInstalled
 *      - Functions: enable(), disable(), toggle(), fetchAvailability(), fetchActiveState()
 *
 *   2. Runtime control via Unix socket (NEW):
 *      - Path: $XDG_RUNTIME_DIR/EasyEffectsServer
 *      - Plain text protocol, ONE COMMAND PER CONNECTION (no pipelining).
 *        Open → write "command\n" → optionally read a single reply line → close.
 *      - No push notifications; we poll bypass + current preset every 1.5s
 *        but ONLY when polling is enabled by a consumer (see `pollEnabled`).
 *      - Properties:
 *          socketConnected — true if the most recent probe found a live socket
 *          bypassed        — true when global bypass is active (chain off)
 *          currentPreset   — last loaded output preset name (no .json extension)
 *          presets         — sorted list<string> of available output preset names
 *      - Functions:
 *          toggleBypass()                 — flip global bypass
 *          setBypass(bool)                — explicit set
 *          loadPreset(name)               — load output preset by base name
 *          refreshState()                 — manual poll trigger
 *          refreshPresets()               — re-scan ~/.local/share/easyeffects/output/
 *
 * Polling lifecycle:
 *   Consumers (e.g. AudioView when visible) call EasyEffects.pollEnabled = true
 *   to start the 1.5s state poll. Set false when no longer needed. The poll
 *   gates itself on `available && pollEnabled`.
 *
 * Out of v1 scope — STUBS that warn:
 *   setPluginBypass(plugin, bypassed)    — per-plugin bypass lives inside preset
 *                                          JSON; not exposed by the socket
 *                                          protocol. AudioView's PluginCard calls
 *                                          this when the user clicks the play/
 *                                          pause toggle; we log and no-op so the
 *                                          UI doesn't crash. Plugin cards are
 *                                          default-hidden in config until this
 *                                          gets a proper implementation.
 *   setPluginProperty(plugin, prop, val) — same story for parameter sliders.
 */
Singleton {
    id: root

    // ─────────────────────────────────────────────────────────────────────
    // LAYER 1: availability & lifecycle (pre-existing, unchanged behavior)
    // ─────────────────────────────────────────────────────────────────────

    property bool available: false
    property bool active: false
    property bool nativeInstalled: false

    function fetchAvailability() {
        if (whichProc.running || flatpakInfoProc.running) return
        whichProc.running = true
    }

    function fetchActiveState() {
        if (!root.available) {
            root.active = false
            return
        }
        if (root.nativeInstalled) {
            if (nativeStatusProc.running) return
            nativeStatusProc.running = true
            return
        }
        if (flatpakPsProc.running) return
        flatpakPsProc.running = true
    }

    function disable() {
        if (!root.available) return
        root.active = false
        if (pkillProc.running || flatpakKillProc.running) return
        pkillProc.running = true
    }

    function enable() {
        if (!root.available) return
        root.active = true
        if (root.nativeInstalled) {
            Quickshell.execDetached(["/usr/bin/easyeffects", "--service-mode"])
        } else {
            Quickshell.execDetached(["/usr/bin/flatpak", "run", "com.github.wwmm.easyeffects", "--service-mode"])
        }
        refreshStateTimer.restart()
    }

    function toggle() {
        if (root.active) {
            root.disable()
        } else {
            root.enable()
        }
    }

    Timer {
        id: initTimer
        interval: 1200
        repeat: false
        onTriggered: {
            root.fetchAvailability()
            root.fetchActiveState()
        }
    }

    Timer {
        id: refreshStateTimer
        interval: 900
        repeat: false
        onTriggered: root.fetchActiveState()
    }

    Timer {
        id: statePollTimer
        interval: 5000
        repeat: true
        running: Config.ready && root.available
        onTriggered: root.fetchActiveState()
    }

    Component.onCompleted: {
        if (Config.ready) {
            initTimer.start()
        }
    }

    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.ready) {
                initTimer.start()
            }
        }
    }

    Process {
        id: whichProc
        running: false
        command: ["/usr/bin/which", "easyeffects"]
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.nativeInstalled = true
                root.available = true
            } else {
                root.nativeInstalled = false
                flatpakInfoProc.running = true
            }
        }
    }

    Process {
        id: flatpakInfoProc
        running: false
        command: ["/bin/sh", "-c", "flatpak info com.github.wwmm.easyeffects"]
        onExited: (exitCode, exitStatus) => {
            root.nativeInstalled = false
            root.available = (exitCode === 0)
        }
    }

    Process {
        id: nativeStatusProc
        running: false
        command: ["/usr/bin/bash", "-lc", "/usr/bin/pgrep -af '(^|/)easyeffects($| )' | /usr/bin/grep -v ' -b ' | /usr/bin/grep -v ' -q' >/dev/null"]
        onExited: (exitCode, _exitStatus) => {
            root.active = (exitCode === 0)
        }
    }

    Process {
        id: flatpakPsProc
        running: false
        command: ["/bin/sh", "-c", "flatpak ps --columns=application"]
        stdout: StdioCollector {
            id: flatpakPsCollector
            onStreamFinished: {
                const t = (flatpakPsCollector.text ?? "")
                root.active = t.split("\n").some(l => l.trim().includes("com.github.wwmm.easyeffects"))
            }
        }
    }

    Process {
        id: pkillProc
        running: false
        command: ["/usr/bin/pkill", "easyeffects"]
        onExited: (_exitCode, _exitStatus) => {
            flatpakKillProc.running = true
            refreshStateTimer.restart()
        }
    }

    Process {
        id: flatpakKillProc
        running: false
        command: ["/bin/sh", "-c", "flatpak kill com.github.wwmm.easyeffects"]
        onExited: (_exitCode, _exitStatus) => refreshStateTimer.restart()
    }

    // ─────────────────────────────────────────────────────────────────────
    // LAYER 2: socket IPC + runtime state
    // ─────────────────────────────────────────────────────────────────────

    readonly property string socketPath:
        (Quickshell.env("XDG_RUNTIME_DIR") || "/run/user/1000") + "/EasyEffectsServer"

    readonly property string presetDir:
        (Quickshell.env("HOME") || "") + "/.local/share/easyeffects/output"

    // Live runtime state — bound by AudioView and AudioEffectsConfig
    property bool socketConnected: false
    property bool bypassed: false
    property string currentPreset: ""
    property var presets: []  // list<string>, sorted, no .json extension

    // Set true by a visible consumer (e.g. AudioView) to start the 1.5s poll.
    // Set false when consumer hides — keeps us off the bus when nothing's looking.
    property bool pollEnabled: false

    // Verbose logging toggle. Flip to true while wiring; leave false in normal use.
    property bool debug: false

    function _log(msg) { if (root.debug) console.log("[EasyEffects]", msg) }

    /**
     * Probe presence of the socket file. EasyEffects creates it when it starts
     * in --service-mode; absence means daemon not running.
     */
    function _probeSocket() {
        if (socketProbeProc.running) return
        socketProbeProc.running = true
    }

    Process {
        id: socketProbeProc
        running: false
        command: ["/usr/bin/test", "-S", root.socketPath]
        onExited: (exitCode, _exitStatus) => {
            const wasConnected = root.socketConnected
            root.socketConnected = (exitCode === 0)
            if (root.socketConnected && !wasConnected) {
                root._log("socket appeared at " + root.socketPath)
                // First connection — kick a refresh so UI populates immediately.
                root.refreshState()
                root.refreshPresets()
            } else if (!root.socketConnected && wasConnected) {
                root._log("socket disappeared")
            }
        }
    }

    /**
     * Poll loop — runs only when consumers ask for it AND the daemon is up.
     */
    Timer {
        id: pollTimer
        interval: 1500
        repeat: true
        running: root.available && root.pollEnabled && Config.ready
        triggeredOnStart: true
        onTriggered: {
            root._probeSocket()
            if (root.socketConnected) {
                root.refreshState()
            }
        }
    }

    /**
     * Public: re-fetch bypass + current preset.
     */
    function refreshState() {
        if (!root.socketConnected) {
            // Try a probe — maybe the daemon just came up.
            root._probeSocket()
            return
        }
        root._refreshStateImpl()
    }

    /**
     * Public: rescan the output preset directory for available presets.
     */
    function refreshPresets() {
        if (presetListProc.running) return
        presetListProc.running = true
    }

    Process {
        id: presetListProc
        running: false
        command: ["/bin/sh", "-c",
            "test -d '" + root.presetDir + "' && " +
            "ls -1 '" + root.presetDir + "' 2>/dev/null | grep -i '\\.json$' | sed 's/\\.json$//' | sort -f || true"]
        stdout: StdioCollector {
            id: presetListCollector
            onStreamFinished: {
                const text = (presetListCollector.text ?? "").trim()
                root.presets = text.length === 0
                    ? []
                    : text.split("\n").map(s => s.trim()).filter(s => s.length > 0)
                root._log("presets refreshed: " + root.presets.length)
            }
        }
    }

    // Preset list refresh cadence:
    //   - On daemon-discovery (handled in socketProbeProc.onExited above)
    //   - On a slow background timer so chips reflect newly created presets
    //     without us doing kernel-level inotify (FileView only watches files).
    Timer {
        id: presetRescanTimer
        interval: 30000  // 30s — preset creation is rare; cheap directory list.
        repeat: true
        running: root.available && root.pollEnabled && Config.ready
        onTriggered: root.refreshPresets()
    }

    // ─────────────────────────────────────────────────────────────────────
    // Active preset detail reader
    //
    // When `currentPreset` changes, parse its JSON file to extract:
    //   - currentPresetPlugins  : ordered list of plugin base-names in the chain
    //                             ("equalizer", "compressor", etc — strips #N suffix)
    //   - currentPresetEqBands  : array of {freq, gain} for the equalizer's left
    //                             channel, normalized for visualization. Empty if
    //                             the preset has no equalizer plugin.
    //
    // Uses python3 for safe JSON parsing (vs jq dependency); outputs a single
    // JSON line our QML side parses with JSON.parse(). Process is idempotent.
    // ─────────────────────────────────────────────────────────────────────
    property var currentPresetPlugins: []
    property var currentPresetEqBands: []

    // Internal state for the preset detail reader.
    // _pendingPreset    — the value of currentPreset we want to load next
    // _inflightPreset   — the preset name the running python process was
    //                     spawned with. Captured at launch time so reactive
    //                     re-evaluation of `command` can't desync us.
    // After each parse: if pending != inflight (user clicked a new chip
    // mid-flight), re-fire for the pending value.
    property string _pendingPreset: ""
    property string _inflightPreset: ""

    function _readPresetDetails() {
        if (!root.currentPreset || root.currentPreset.length === 0) {
            root.currentPresetPlugins = []
            root.currentPresetEqBands = []
            root._pendingPreset = ""
            return
        }
        root._pendingPreset = root.currentPreset
        if (presetDetailProc.running) return
        // Capture the value we're about to read so the running command stays
        // consistent even if currentPreset mutates again before we finish.
        root._inflightPreset = root._pendingPreset
        root._log("preset detail: spawning for '" + root._inflightPreset + "'")
        presetDetailProc.running = true
    }

    onCurrentPresetChanged: _readPresetDetails()

    Process {
        id: presetDetailProc
        running: false
        // Read the active preset JSON, emit a single line:
        //   {"plugins":["equalizer","compressor",...],"eq":[{"freq":32,"gain":4.0},...]}
        // Empty fields if missing. python3 ships in cachyos base; no extra dep.
        // Argv targets _inflightPreset (captured at launch) NOT currentPreset
        // directly — prevents reactive re-eval mid-process from corrupting
        // which preset we're actually parsing.
        command: ["/usr/bin/python3", "-c",
            "import json,sys,os\n" +
            "p = os.path.expanduser('~/.local/share/easyeffects/output/') + sys.argv[1] + '.json'\n" +
            "try:\n" +
            "    d = json.load(open(p))\n" +
            "    o = d.get('output', {})\n" +
            "    plugins_raw = o.get('plugins_order', [])\n" +
            "    plugins = [p.split('#')[0] for p in plugins_raw]\n" +
            "    eq = []\n" +
            "    eq_key = next((k for k in o if k.startswith('equalizer')), None)\n" +
            "    if eq_key and 'left' in o[eq_key]:\n" +
            "        left = o[eq_key]['left']\n" +
            "        for i in range(20):\n" +
            "            b = left.get('band' + str(i))\n" +
            "            if not b: break\n" +
            "            eq.append({'freq': b.get('frequency', 0), 'gain': b.get('gain', 0)})\n" +
            "    print(json.dumps({'plugins': plugins, 'eq': eq}))\n" +
            "except Exception as e:\n" +
            "    print('{\"plugins\":[],\"eq\":[]}')\n",
            root._inflightPreset]
        stdout: StdioCollector {
            id: presetDetailCollector
            onStreamFinished: {
                const text = (presetDetailCollector.text ?? "").trim()
                const completedFor = root._inflightPreset
                if (text.length === 0) {
                    root.currentPresetPlugins = []
                    root.currentPresetEqBands = []
                } else {
                    try {
                        const parsed = JSON.parse(text)
                        root.currentPresetPlugins = parsed.plugins ?? []
                        root.currentPresetEqBands = parsed.eq ?? []
                        root._log("preset detail: applied '" + completedFor +
                                  "' (" + root.currentPresetPlugins.length + " plugins, " +
                                  root.currentPresetEqBands.length + " EQ bands)")
                    } catch (e) {
                        root._log("preset detail parse failed for '" + completedFor + "': " + e)
                        root.currentPresetPlugins = []
                        root.currentPresetEqBands = []
                    }
                }
                // Re-fire if user clicked a different chip while we were busy.
                root._inflightPreset = ""
                if (root._pendingPreset && root._pendingPreset !== completedFor) {
                    root._log("preset detail: re-firing for pending '" + root._pendingPreset + "'")
                    Qt.callLater(_readPresetDetails)
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    // One-shot socket commands
    //
    // Each command opens its own Socket, writes a single line, optionally
    // reads ONE reply line, then closes. We declare 4 Socket instances —
    // 2 writers (no reply) + 2 readers (single reply) — so concurrent
    // in-flight commands don't collide on a single connection.
    //
    // Lifecycle per call:
    //   sendOnSocket() sets pending command + sets connected=true
    //   onConnectionStateChanged: when connected, write the command, flush
    //   For writers: closeAfterWriteTimer fires in 50ms → connected=false
    //   For readers: SplitParser.onRead fires → callback → connected=false
    // ─────────────────────────────────────────────────────────────────────

    /**
     * Internal helper. Targets one of the 4 Socket instances by id-property.
     */
    function _sendOnSocket(socketObj, cmd) {
        if (!cmd || cmd.length === 0) return
        // Force-close any in-flight previous connection on this socket.
        if (socketObj.connected) {
            socketObj.connected = false
        }
        socketObj._pending = cmd
        socketObj.connected = true
    }

    function _onSocketStateChanged(socketObj, isWriter) {
        if (socketObj.connected && socketObj._pending.length > 0) {
            const line = socketObj._pending + "\n"
            socketObj.write(line)
            socketObj.flush()
            root._log("→ " + socketObj._pending)
            socketObj._pending = ""
            if (isWriter) {
                // Writers have no reply — close after a tick so the kernel can flush.
                closeAfterWriteTimer.targetSocket = socketObj
                closeAfterWriteTimer.restart()
            }
        }
    }

    // Single shared timer that closes the most recent writer.
    // We only ever fire one writer at a time per UI action, so a shared timer
    // is fine — and avoids a Timer-per-Socket-as-child issue.
    Timer {
        id: closeAfterWriteTimer
        interval: 50
        repeat: false
        property var targetSocket: null
        onTriggered: {
            if (closeAfterWriteTimer.targetSocket) {
                closeAfterWriteTimer.targetSocket.connected = false
                closeAfterWriteTimer.targetSocket = null
            }
        }
    }

    /**
     * Public: flip global bypass.
     * Optimistic update — flip local property immediately, daemon confirms
     * on the next poll cycle.
     */
    function toggleBypass() {
        if (!root.socketConnected) {
            root._log("toggleBypass: socket not connected")
            return
        }
        root.bypassed = !root.bypassed
        root._sendOnSocket(toggleBypassSock, "toggle_global_bypass")
    }

    /**
     * Public: explicit bypass set.
     */
    function setBypass(want) {
        if (!root.socketConnected) {
            root._log("setBypass: socket not connected")
            return
        }
        root.bypassed = want
        // global_bypass:1 == bypassed; :0 == active.
        root._sendOnSocket(toggleBypassSock, "global_bypass:" + (want ? "1" : "0"))
    }

    /**
     * Public: load an output preset by base name (no .json extension).
     */
    function loadPreset(name) {
        if (!root.socketConnected) {
            root._log("loadPreset: socket not connected")
            return
        }
        if (!name || name.length === 0) return
        // Optimistic update so the chip flashes selected immediately.
        root.currentPreset = name
        root._sendOnSocket(loadPresetSock, "load_preset:output:" + name)
    }

    /**
     * Out of v1 scope. EasyEffects per-plugin state lives inside the active
     * preset's JSON — there's no plain socket command for runtime mutation.
     * Stubbed to keep the AudioView PluginCard from blowing up; cards are
     * default-hidden in config until proper preset-mutation lands.
     */
    function setPluginBypass(plugin, bypassed) {
        console.warn("[EasyEffects] setPluginBypass(" + plugin + "," + bypassed +
                     ") — not implemented in v1. Plugin cards are stubs.")
    }
    function setPluginProperty(plugin, prop, value) {
        console.warn("[EasyEffects] setPluginProperty(" + plugin + "," + prop + "," + value +
                     ") — not implemented in v1. Plugin cards are stubs.")
    }

    // ── Writer sockets ─────────────────────────────────────────────────
    Socket {
        id: toggleBypassSock
        path: root.socketPath
        connected: false
        property string _pending: ""
        onConnectionStateChanged: root._onSocketStateChanged(toggleBypassSock, true)
    }

    Socket {
        id: loadPresetSock
        path: root.socketPath
        connected: false
        property string _pending: ""
        onConnectionStateChanged: root._onSocketStateChanged(loadPresetSock, true)
    }

    // ── Reader sockets ─────────────────────────────────────────────────
    Socket {
        id: bypassQuerySock
        path: root.socketPath
        connected: false
        property string _pending: ""
        onConnectionStateChanged: root._onSocketStateChanged(bypassQuerySock, false)
        parser: SplitParser {
            onRead: line => {
                // Reply: "1" = bypassed, "2" = active.
                root._log("← bypass: " + line)
                const v = (line || "").trim()
                if (v === "1") root.bypassed = true
                else if (v === "2") root.bypassed = false
                bypassQuerySock.connected = false
            }
        }
    }

    Socket {
        id: presetQuerySock
        path: root.socketPath
        connected: false
        property string _pending: ""
        onConnectionStateChanged: root._onSocketStateChanged(presetQuerySock, false)
        parser: SplitParser {
            onRead: line => {
                root._log("← preset: " + line)
                const name = (line || "").trim()
                if (name.length > 0 && name !== root.currentPreset) {
                    root.currentPreset = name
                }
                presetQuerySock.connected = false
            }
        }
    }

    // refreshState now references the new socket ids
    function _refreshStateImpl() {
        root._sendOnSocket(bypassQuerySock, "get_global_bypass")
        root._sendOnSocket(presetQuerySock, "get_last_loaded_preset:output")
    }
}
