import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick

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
        }
    }
}
