pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

Singleton {
    id: root

    property bool isRecording: false
    readonly property string _recordScript: Directories.recordScriptPath

    // Read initial state once on startup; maintained locally after that
    Process {
        id: initCheck
        command: ["/usr/bin/pgrep", "-x", "wf-recorder"]
        onExited: (exitCode, exitStatus) => {
            root.isRecording = (exitCode === 0)
        }
    }

    function startRecording(args: list<string>): void {
        root.isRecording = true
        Quickshell.execDetached([root._recordScript].concat(args))
    }

    function stopRecording(): void {
        root.isRecording = false
        Quickshell.execDetached(["/usr/bin/pkill", "-x", "wf-recorder"])
    }

    function toggle(args: list<string>): void {
        if (root.isRecording) root.stopRecording()
        else root.startRecording(args)
    }

    Component.onCompleted: {
        if (Config.ready) initCheck.running = true
    }

    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.ready) initCheck.running = true
        }
    }
}
