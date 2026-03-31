pragma Singleton
pragma ComponentBehavior: Bound

import qs
import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Plugin registry — discovers, loads, and manages plugins.
 *
 * Plugins live in ~/.config/quickshell/ii/plugins/<plugin-id>/
 * Each plugin has a manifest.json describing its type and entry points.
 *
 * Two plugin types:
 *   "poll" — runs a script, renders output with built-in PluginBarWidget
 *   "qml"  — loads a custom BarWidget.qml with full UI control
 *
 * Poll plugin output contract (JSON on stdout):
 *   text:    string  — display text (required)
 *   icon:    string  — Material Symbol icon name (optional)
 *   tooltip: string  — hover tooltip (optional)
 *   status:  string  — "normal" | "warning" | "error" (optional)
 *   value:   number  — 0-100 for progress indicator (optional)
 *
 * QML plugins receive a pluginApi object with stable access to shell services.
 */
Singleton {
    id: root

    IpcHandler {
        target: "plugins"
        function list(): string { return root.getPluginList() }
        function reload(): void { root.scanPlugins() }
        function diagnose(): string { return root.getDiagnostics() }
    }

    readonly property bool enabled: Config.options?.plugins?.enabled ?? true
    readonly property string pluginDir: FileUtils.trimFileProtocol(Quickshell.shellPath("plugins"))

    // Public model: array of plugin data objects for UI consumption
    // Poll plugins: { id, name, type:"poll", icon, text, tooltip, status, value, position, visible }
    // QML plugins:  { id, name, type:"qml", position, visible, sourceUrl, pluginDirPath }
    property var barPlugins: []

    // Internal: loaded manifest data + process state
    property var _plugins: ({})
    property bool _scanning: false

    // Reload counter for QML component cache-busting
    property int _reloadVersion: 0

    function getPluginList(): string {
        const list = []
        for (const id in _plugins) {
            const p = _plugins[id]
            list.push({ id: id, name: p.name, type: p.type, enabled: p.enabled, position: p.position })
        }
        return JSON.stringify(list, null, 2)
    }

    function getDiagnostics(): string {
        return JSON.stringify({
            enabled: root.enabled,
            pluginDir: root.pluginDir,
            pluginCount: Object.keys(_plugins).length,
            barPluginCount: barPlugins.length,
            reloadVersion: _reloadVersion,
            plugins: Object.keys(_plugins).map(id => ({
                id: id,
                name: _plugins[id].name,
                type: _plugins[id].type,
                enabled: _plugins[id].enabled,
                contract: _plugins[id].contract ?? null,
                interval: _plugins[id].interval ?? null,
                lastStatus: _plugins[id].lastStatus,
                lastError: _plugins[id].lastError
            }))
        }, null, 2)
    }

    function scanPlugins() {
        if (_scanning) return
        _scanning = true
        _reloadVersion++
        // Reset contract overrides before re-scan to clear stale state
        Contracts.resetAll()
        print("[PluginRegistry] Scanning " + pluginDir + " (v" + _reloadVersion + ")")
        scanProc.running = true
    }

    // Scan plugin directories for manifest.json files
    Process {
        id: scanProc
        running: false
        command: [
            "/usr/bin/bash", "-c",
            "shopt -s nullglob; " +
            "for d in '" + root.pluginDir + "'/*/; do " +
            "  [[ -f \"${d}manifest.json\" ]] && cat \"${d}manifest.json\" && echo '---PLUGIN_SEP---'; " +
            "done; exit 0"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                root._processManifests(text ?? "")
            }
        }
        onExited: (exitCode, exitStatus) => {
            root._scanning = false
            if (exitCode !== 0) {
                print("[PluginRegistry] Scan failed (exit " + exitCode + ")")
            }
        }
    }

    function _processManifests(raw) {
        const chunks = raw.split("---PLUGIN_SEP---").filter(c => c.trim().length > 0)
        const newPlugins = {}
        const enabledList = Config.options?.plugins?.enabled_list ?? null

        for (const chunk of chunks) {
            try {
                const manifest = JSON.parse(chunk.trim())
                if (!manifest.id) continue

                const isEnabled = enabledList ? (enabledList.indexOf(manifest.id) !== -1) : true

                // Override plugins — replace a contract slot with a custom component
                if (manifest.override) {
                    const pluginEntry = {
                        name: manifest.name ?? manifest.id,
                        type: "override",
                        enabled: isEnabled,
                        contract: manifest.override.contract ?? "",
                        entryPoint: manifest.override.entryPoint ?? "Main.qml",
                        lastStatus: isEnabled ? "active" : "disabled",
                        lastError: "",
                        manifest: manifest
                    }
                    newPlugins[manifest.id] = pluginEntry

                    // Apply override to the contract slot if enabled
                    if (isEnabled && pluginEntry.contract) {
                        const slot = Contracts.getSlot(pluginEntry.contract)
                        if (slot) {
                            const pluginUrl = "file://" + root.pluginDir + "/" + manifest.id + "/" + pluginEntry.entryPoint
                            slot.override(pluginUrl)
                            pluginEntry.lastStatus = "active"
                        } else {
                            pluginEntry.lastStatus = "error"
                            pluginEntry.lastError = "Unknown contract slot: " + pluginEntry.contract
                        }
                    }
                    continue
                }

                // Bar widget plugins — existing poll/qml types
                if (!manifest.barWidget) continue

                const widgetType = manifest.barWidget.type ?? "poll"

                const pluginEntry = {
                    name: manifest.name ?? manifest.id,
                    type: widgetType,
                    enabled: isEnabled,
                    position: manifest.barWidget.position ?? "leftCenter",
                    lastStatus: "pending",
                    lastError: "",
                    manifest: manifest
                }

                if (widgetType === "poll") {
                    pluginEntry.command = manifest.barWidget.command ?? []
                    pluginEntry.interval = manifest.barWidget.interval ?? 5000
                    pluginEntry.icon = manifest.barWidget.defaultIcon ?? ""
                    pluginEntry.text = ""
                    pluginEntry.tooltip = ""
                    pluginEntry.status = "normal"
                    pluginEntry.value = -1
                } else if (widgetType === "qml") {
                    pluginEntry.entryPoint = manifest.barWidget.entryPoint ?? "BarWidget.qml"
                    pluginEntry.settingsFile = manifest.barWidget.settings ?? ""
                }

                newPlugins[manifest.id] = pluginEntry
            } catch (e) {
                print("[PluginRegistry] Failed to parse manifest: " + e)
            }
        }

        root._plugins = newPlugins
        print("[PluginRegistry] Found " + Object.keys(newPlugins).length + " plugin(s)")

        root._rebuildBarModel()
        root._startPolling()
    }

    function _rebuildBarModel() {
        const model = []
        for (const id in _plugins) {
            const p = _plugins[id]
            if (!p.enabled) continue

            if (p.type === "poll") {
                model.push({
                    id: id,
                    name: p.name,
                    type: "poll",
                    icon: p.icon,
                    text: p.text,
                    tooltip: p.tooltip,
                    status: p.status,
                    value: p.value,
                    position: p.position,
                    visible: p.text.length > 0
                })
            } else if (p.type === "qml") {
                model.push({
                    id: id,
                    name: p.name,
                    type: "qml",
                    position: p.position,
                    visible: true,
                    sourceUrl: "file://" + root.pluginDir + "/" + id + "/" + p.entryPoint + "?v=" + root._reloadVersion,
                    pluginDirPath: root.pluginDir + "/" + id
                })
            }
        }
        root.barPlugins = model
    }

    // =========================================================================
    // Plugin API — stable interface injected into QML plugins
    // =========================================================================

    /**
     * Build a pluginApi object for a specific plugin.
     * This wraps shell singletons behind stable property names so internal
     * renames don't break plugins.
     */
    function buildPluginApi(pluginId, pluginDirPath) {
        return {
            // Identity
            pluginId: pluginId,
            pluginDir: pluginDirPath,

            // Settings (per-plugin persistent storage)
            pluginSettings: _loadPluginSettings(pluginId),
            saveSettings: function(settings) { _savePluginSettings(pluginId, settings) },

            // Shell services — stable names wrapping iNiR singletons
            appearance: Appearance,
            config: Config,
            globalStates: GlobalStates
        }
    }

    function _loadPluginSettings(pluginId) {
        // Settings stored at ~/.config/illogical-impulse/plugins/<id>/settings.json
        // For now, read from config.json under plugins.settings.<id>
        return Config.options?.plugins?.settings?.[pluginId] ?? {}
    }

    function _savePluginSettings(pluginId, settings) {
        Config.setNestedValue("plugins.settings." + pluginId, settings)
    }

    // =========================================================================
    // Poll plugin infrastructure (Phase 1)
    // =========================================================================

    property var _pollCounters: ({})

    Timer {
        id: pollTimer
        interval: 1000
        repeat: true
        running: root.enabled && Object.keys(root._plugins).length > 0
        onTriggered: root._tickPolling()
    }

    function _startPolling() {
        const counters = {}
        for (const id in _plugins) {
            if (_plugins[id].enabled && _plugins[id].type === "poll") {
                counters[id] = 0
                _runPluginCommand(id)
            }
        }
        _pollCounters = counters
    }

    function _tickPolling() {
        for (const id in _pollCounters) {
            const p = _plugins[id]
            if (!p || !p.enabled) continue
            _pollCounters[id] += 1000
            if (_pollCounters[id] >= p.interval) {
                _pollCounters[id] = 0
                _runPluginCommand(id)
            }
        }
    }

    function _runPluginCommand(pluginId) {
        const p = _plugins[pluginId]
        if (!p || !p.enabled || !p.command || p.command.length === 0) return

        const cmd = p.command.slice()
        if (cmd[0].startsWith("./")) {
            cmd[0] = root.pluginDir + "/" + pluginId + "/" + cmd[0].substring(2)
        }

        const proc = pluginProcComponent.createObject(root, {
            pluginId: pluginId,
            command: cmd
        })
        proc.running = true
    }

    Component {
        id: pluginProcComponent

        Process {
            id: pluginProc
            property string pluginId: ""
            running: false

            stdout: StdioCollector {
                onStreamFinished: {
                    const output = (text ?? "").trim()
                    if (output.length === 0) return

                    try {
                        const data = JSON.parse(output)
                        const p = root._plugins[pluginProc.pluginId]
                        if (!p) return

                        p.text = data.text ?? ""
                        p.icon = data.icon ?? p.icon ?? ""
                        p.tooltip = data.tooltip ?? ""
                        p.status = data.status ?? "normal"
                        p.value = (data.value !== undefined && data.value !== null) ? Number(data.value) : -1
                        p.lastStatus = "ok"
                        p.lastError = ""
                        root._rebuildBarModel()
                    } catch (e) {
                        const p = root._plugins[pluginProc.pluginId]
                        if (p) {
                            p.lastStatus = "error"
                            p.lastError = "JSON parse error: " + e
                        }
                        print("[PluginRegistry] " + pluginProc.pluginId + ": " + e)
                    }
                }
            }

            onExited: (exitCode, exitStatus) => {
                if (exitCode !== 0) {
                    const p = root._plugins[pluginProc.pluginId]
                    if (p) {
                        p.lastStatus = "error"
                        p.lastError = "exit code " + exitCode
                    }
                }
                pluginProc.destroy()
            }
        }
    }

    // Startup: scan after config is ready
    Timer {
        id: startupDelay
        interval: 2000
        repeat: false
        running: root.enabled && Config.ready
        onTriggered: root.scanPlugins()
    }

    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.ready && root.enabled) {
                startupDelay.restart()
            }
        }
    }
}
