import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Quickshell.Io

SidebarShell {
    id: shell
    side: "left"

    contentComponent: Component {
        SidebarLeftContent {
            screenWidth: shell.screenWidth
            screenHeight: shell.screenHeight
            panelScreen: shell.panelScreen
        }
    }

    // Literal IPC target so scripts/lib/generate-ipc-registry.py discovers it.
    // SidebarShell intentionally omits the dynamic-target IpcHandler — see note there.
    IpcHandler {
        target: "sidebarLeft"

        function toggle(): void {
            GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen;
        }

        function close(): void {
            GlobalStates.sidebarLeftOpen = false;
        }

        function open(): void {
            GlobalStates.sidebarLeftOpen = true;
        }
    }
}
