pragma Singleton
pragma ComponentBehavior: Bound

import qs
import qs.modules.common
import qs.services
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

/**
 * Focus Mode — profile-based system state management.
 *
 * Profiles orchestrate notifications, power, idle, and compositor settings
 * as a single unit. Each profile is a delta against baseline — only the
 * settings it explicitly specifies change.
 *
 * Profiles: focus, gaming, zen, auto (off)
 */
Singleton {
    id: root

    IpcHandler {
        target: "focus"
        function status(): string { return root.getDiagnostics() }
        function set(mode: string): void { root.setMode(mode) }
        function cycle(): void { root.cycleMode() }
        function off(): void { root.setMode("auto") }
    }

    // ─── Public state ────────────────────────────────────────────
    property string activeMode: "auto"
    readonly property bool active: activeMode !== "auto"
    readonly property var profile: _profiles[activeMode] ?? _profiles["auto"]

    // Convenience for UI bindings
    readonly property string icon: profile.icon ?? ""
    readonly property string label: profile.label ?? ""
    readonly property color accentColor: {
        switch (activeMode) {
            case "focus": return Appearance.m3colors.m3primary
            case "gaming": return Appearance.m3colors.m3tertiary
            case "zen": return Appearance.m3colors.m3secondary
            default: return Appearance.colors.colOnLayer0
        }
    }

    // ─── Profile definitions ─────────────────────────────────────
    readonly property var _profiles: ({
        "auto": {
            label: "Auto",
            icon: "",
            silent: false,
            criticalBreaksThrough: true,
            allowlist: [],
            powerProfile: null,
            idleInhibit: null,
            gameMode: null
        },
        "focus": {
            label: "Focus",
            icon: "center_focus_strong",
            silent: true,
            criticalBreaksThrough: true,
            allowlist: _configAllowlist("focus"),
            powerProfile: "balanced",
            idleInhibit: false,
            gameMode: false
        },
        "gaming": {
            label: "Gaming",
            icon: "sports_esports",
            silent: true,
            criticalBreaksThrough: false,
            allowlist: [],
            powerProfile: "performance",
            idleInhibit: true,
            gameMode: true
        },
        "zen": {
            label: "Zen",
            icon: "self_improvement",
            silent: true,
            criticalBreaksThrough: false,
            allowlist: [],
            powerProfile: "power-saver",
            idleInhibit: false,
            gameMode: false
        }
    })

    readonly property var _modeOrder: ["auto", "focus", "gaming", "zen"]

    function _configAllowlist(mode) {
        return Config.options?.focusMode?.profiles?.[mode]?.allowlist ?? []
    }

    // ─── Saved baseline state (restored on deactivate) ───────────
    property bool _prevSilent: false
    property string _prevPowerProfile: ""
    property bool _prevIdleInhibit: false
    property bool _prevGameMode: false

    // ─── Actions ─────────────────────────────────────────────────

    function setMode(mode) {
        if (mode === activeMode) return
        if (!_profiles.hasOwnProperty(mode)) {
            print("[FocusMode] Unknown mode: " + mode)
            return
        }

        // Deactivate current mode first (restore baseline)
        if (active) {
            _deactivate()
        }

        // Activate new mode
        if (mode !== "auto") {
            _activate(mode)
        }

        activeMode = mode
        Config.setNestedValue("focusMode.activeMode", mode)
        print("[FocusMode] Mode set to: " + mode)
    }

    function cycleMode() {
        const idx = _modeOrder.indexOf(activeMode)
        const next = _modeOrder[(idx + 1) % _modeOrder.length]
        setMode(next)
    }

    function _activate(mode) {
        const p = _profiles[mode]
        if (!p) return

        // Save baseline
        _prevSilent = Notifications.silent
        _prevPowerProfile = _currentPowerProfileString()
        _prevIdleInhibit = Idle.inhibit
        _prevGameMode = GameMode.active

        // Apply profile
        if (p.silent !== null && p.silent !== undefined) {
            Notifications.silent = p.silent
        }

        if (p.powerProfile !== null && p.powerProfile !== undefined) {
            _setPowerProfile(p.powerProfile)
        }

        if (p.idleInhibit !== null && p.idleInhibit !== undefined) {
            Idle.toggleInhibit(p.idleInhibit)
        }

        if (p.gameMode === true && !GameMode.active) {
            GameMode.activate()
        } else if (p.gameMode === false && GameMode.active) {
            GameMode.deactivate()
        }

        print("[FocusMode] Activated: " + mode)
    }

    function _deactivate() {
        // Restore baseline
        Notifications.silent = _prevSilent

        if (_prevPowerProfile.length > 0) {
            _setPowerProfile(_prevPowerProfile)
            // Fix PowerProfilePersistence overwrite
            Config.setNestedValue("powerProfiles.preferredProfile", _prevPowerProfile)
        }

        Idle.toggleInhibit(_prevIdleInhibit)

        if (_prevGameMode && !GameMode.active) {
            GameMode.activate()
        } else if (!_prevGameMode && GameMode.active) {
            GameMode.deactivate()
        }

        print("[FocusMode] Deactivated, restored baseline")
    }

    // ─── Notification filtering ──────────────────────────────────
    // Called by Notifications.qml to check if a notification should popup
    function shouldAllowPopup(notification): bool {
        if (!active) return true

        const p = profile
        if (!p.silent) return true

        // Critical notifications break through if configured
        if (p.criticalBreaksThrough && notification.urgency === 2) { // Critical = 2
            return true
        }

        // Check per-app allowlist
        const allowlist = p.allowlist ?? []
        if (allowlist.length > 0) {
            const appName = (notification.appName ?? "").toLowerCase()
            const appIcon = (notification.appIcon ?? "").toLowerCase()
            for (const pattern of allowlist) {
                const lp = pattern.toLowerCase()
                if (appName.includes(lp) || appIcon.includes(lp)) {
                    return true
                }
            }
        }

        return false
    }

    // ─── Power profile helpers ───────────────────────────────────
    function _currentPowerProfileString() {
        switch (PowerProfiles.profile) {
            case PowerProfile.PowerSaver: return "power-saver"
            case PowerProfile.Balanced: return "balanced"
            case PowerProfile.Performance: return "performance"
            default: return "balanced"
        }
    }

    function _setPowerProfile(name) {
        switch (name) {
            case "power-saver":
                PowerProfiles.profile = PowerProfile.PowerSaver; break
            case "balanced":
                PowerProfiles.profile = PowerProfile.Balanced; break
            case "performance":
                if (PowerProfiles.hasPerformanceProfile)
                    PowerProfiles.profile = PowerProfile.Performance
                break
        }
    }

    // ─── Scheduled focus modes ───────────────────────────────────
    Timer {
        id: scheduleTimer
        interval: 60000 // Check every minute
        repeat: true
        running: _hasSchedules
        onTriggered: root._checkSchedule()
    }

    readonly property bool _hasSchedules: {
        const schedules = Config.options?.focusMode?.schedules
        return schedules && Object.keys(schedules).length > 0
    }

    function _checkSchedule() {
        const schedules = Config.options?.focusMode?.schedules ?? {}
        const now = new Date()
        const currentMinutes = now.getHours() * 60 + now.getMinutes()
        const currentDay = now.getDay() // 0=Sun, 6=Sat

        for (const mode in schedules) {
            const sched = schedules[mode]
            if (!sched.enabled) continue

            const days = sched.days ?? [0, 1, 2, 3, 4, 5, 6]
            if (!days.includes(currentDay)) continue

            const startParts = (sched.start ?? "").split(":")
            const endParts = (sched.end ?? "").split(":")
            if (startParts.length !== 2 || endParts.length !== 2) continue

            const startMin = parseInt(startParts[0]) * 60 + parseInt(startParts[1])
            const endMin = parseInt(endParts[0]) * 60 + parseInt(endParts[1])

            const inRange = startMin <= endMin
                ? (currentMinutes >= startMin && currentMinutes < endMin)
                : (currentMinutes >= startMin || currentMinutes < endMin) // Overnight

            if (inRange && activeMode === "auto") {
                print("[FocusMode] Schedule activated: " + mode)
                setMode(mode)
            } else if (!inRange && activeMode === mode) {
                print("[FocusMode] Schedule ended: " + mode)
                setMode("auto")
            }
        }
    }

    // ─── Startup: restore persisted mode ─────────────────────────
    Timer {
        id: startupRestore
        interval: 3000
        repeat: false
        running: Config.ready
        onTriggered: {
            const saved = Config.options?.focusMode?.activeMode ?? "auto"
            if (saved !== "auto") {
                root._activate(saved)
                root.activeMode = saved
                print("[FocusMode] Restored mode from config: " + saved)
            }
            if (root._hasSchedules) root._checkSchedule()
        }
    }

    function getDiagnostics(): string {
        return JSON.stringify({
            activeMode: activeMode,
            active: active,
            label: label,
            icon: icon,
            profile: profile,
            baseline: {
                silent: _prevSilent,
                powerProfile: _prevPowerProfile,
                idleInhibit: _prevIdleInhibit,
                gameMode: _prevGameMode
            },
            hasSchedules: _hasSchedules
        }, null, 2)
    }
}
