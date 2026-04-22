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

    property bool active: false
    readonly property int port: 10531
    readonly property string serviceName: "gpt-proxy.service"

    IpcHandler {
        target: "gptProxy"
        function toggle(): void { root.toggle() }
        function start(): void { root.start() }
        function stop(): void { root.stop() }
        function status(): void {
            root._log("[GptProxy] active:", root.active)
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

    Process {
        id: startProc
        command: ["/usr/bin/systemctl", "--user", "start", root.serviceName]
        onExited: (code, status) => {
            root._log("[GptProxy] start exited:", code)
            if (code !== 0) {
                Quickshell.execDetached(["/usr/bin/notify-send",
                    "GPT Proxy", "Failed to start service", "-a", "Shell"])
            }
            root.refreshStatus()
        }
    }

    Process {
        id: stopProc
        command: ["/usr/bin/systemctl", "--user", "stop", root.serviceName]
        onExited: (code, status) => {
            root._log("[GptProxy] stop exited:", code)
            root.refreshStatus()
        }
    }

    Process {
        id: checkProc
        running: false
        command: ["/usr/bin/systemctl", "--user", "is-active", root.serviceName]
        onExited: (code, status) => {
            root.active = (code === 0)
        }
    }

    Timer {
        interval: 5000
        running: Config.ready
        repeat: true
        onTriggered: root.refreshStatus()
    }

    Component.onCompleted: root.refreshStatus()
}
