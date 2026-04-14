import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick

SidebarShell {
    id: shell
    side: "left"

    contentComponent: Component {
        SidebarLeftContent {
            screenWidth: shell.screenWidth
            screenHeight: shell.screenHeight
            panelScreen: shell.panelScreen
            onPluginViewActiveChanged: shell.pluginViewActive = pluginViewActive
        }
    }
}
