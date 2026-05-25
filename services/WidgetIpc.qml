pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// WidgetIpc - IPC surface for widget-level refresh operations.
// Routes `inir widget refresh <name>` to the appropriate service call or signal.
//
// Supported names:
//   commandroom  -> CommandRoom.refresh()
//   jobhunt      -> emits jobHuntRefreshRequested (JobHuntPulseWidget connects)
Singleton {
    id: root

    signal jobHuntRefreshRequested()

    IpcHandler {
        target: "widget"

        function refresh(name: string): string {
            if (name === "commandroom") {
                CommandRoom.refresh()
                return "ok"
            } else if (name === "jobhunt") {
                root.jobHuntRefreshRequested()
                return "ok"
            }
            return "error: unknown widget: " + name
        }
    }
}
