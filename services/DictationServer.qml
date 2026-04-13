pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

Singleton {
    id: root

    function _log(...args): void {
        if (Quickshell.env("QS_DEBUG") === "1") console.log(...args);
    }

    // Public API
    property bool active: false
    readonly property int port: 8384
    readonly property string serviceName: "dictation-server.service"

    // IPC handler for external control
    IpcHandler {
        target: "dictation"
        function toggle(): void { root.toggle() }
        function start(): void { root.start() }
        function stop(): void { root.stop() }
        function status(): void {
            root._log("[DictationServer] active:", root.active)
        }
    }

    function toggle() {
        if (active) stop(); else start();
    }

    function start() {
        startProc.running = true
    }

    function stop() {
        stopProc.running = true
    }

    function refreshStatus() {
        checkProc.running = false
        checkProc.running = true
    }

    // systemctl --user start
    Process {
        id: startProc
        command: ["/usr/bin/systemctl", "--user", "start", root.serviceName]
        onExited: (code, status) => {
            root._log("[DictationServer] start exited:", code)
            if (code !== 0) {
                Quickshell.execDetached(["/usr/bin/notify-send",
                    "Dictation Server", "Failed to start service", "-a", "Shell"])
            }
            root.refreshStatus()
        }
    }

    // systemctl --user stop
    Process {
        id: stopProc
        command: ["/usr/bin/systemctl", "--user", "stop", root.serviceName]
        onExited: (code, status) => {
            root._log("[DictationServer] stop exited:", code)
            root.refreshStatus()
        }
    }

    // systemctl --user is-active
    Process {
        id: checkProc
        running: false
        command: ["/usr/bin/systemctl", "--user", "is-active", root.serviceName]
        onExited: (code, status) => {
            root.active = (code === 0)
        }
    }

    // Only poll when the bar button is enabled; start/stop handlers call refreshStatus() directly
    Timer {
        interval: 5000
        running: Config.ready && (Config.options?.bar?.utilButtons?.showDictationToggle ?? false)
        repeat: true
        onTriggered: root.refreshStatus()
    }

    Component.onCompleted: root.refreshStatus()
}
