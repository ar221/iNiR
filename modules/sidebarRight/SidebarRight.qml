import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Quickshell.Io

SidebarShell {
    id: shell
    side: "right"
    soundEnabled: true

    Component {
        id: defaultContentComponent
        SidebarRightContent {
            screenWidth: shell.screenWidth
            screenHeight: shell.screenHeight
            panelScreen: shell.panelScreen
        }
    }

    Component {
        id: compactContentComponent
        CompactSidebarRightContent {
            screenWidth: shell.screenWidth
            screenHeight: shell.screenHeight
            panelScreen: shell.panelScreen
        }
    }

    Component {
        id: bridgeContentComponent
        BridgeSidebarRightContent {
            screenWidth: shell.screenWidth
            screenHeight: shell.screenHeight
            panelScreen: shell.panelScreen
        }
    }

    contentComponent: Component {
        Item {
            anchors.fill: parent

            FadeLoader {
                anchors.fill: parent
                shown: (Config?.options?.sidebar?.layout ?? "default") === "default"
                sourceComponent: defaultContentComponent
            }

            FadeLoader {
                anchors.fill: parent
                shown: (Config?.options?.sidebar?.layout ?? "default") === "compact"
                sourceComponent: compactContentComponent
            }

            FadeLoader {
                anchors.fill: parent
                shown: (Config?.options?.sidebar?.layout ?? "default") === "bridge"
                sourceComponent: bridgeContentComponent
            }
        }
    }

    // Literal IPC target so scripts/lib/generate-ipc-registry.py discovers it.
    // SidebarShell intentionally omits the dynamic-target IpcHandler — see note there.
    IpcHandler {
        target: "sidebarRight"

        function toggle(): void {
            GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
        }

        function close(): void {
            GlobalStates.sidebarRightOpen = false;
        }

        function open(): void {
            GlobalStates.sidebarRightOpen = true;
        }
    }
}
