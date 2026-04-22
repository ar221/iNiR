import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Scope {
    id: root

    property bool _weatherLeased: false

    function _syncWeatherLease() {
        const active = GlobalStates.waffleWidgetsOpen && Weather.enabled
        if (active && !root._weatherLeased) {
            Weather.acquire()
            root._weatherLeased = true
        } else if (!active && root._weatherLeased) {
            Weather.release()
            root._weatherLeased = false
        }
    }

    Component.onCompleted: root._syncWeatherLease()
    Component.onDestruction: {
        if (root._weatherLeased) {
            Weather.release()
            root._weatherLeased = false
        }
    }

    Connections {
        target: GlobalStates
        function onWaffleWidgetsOpenChanged() {
            if (GlobalStates.waffleWidgetsOpen) panelLoader.active = true
            root._syncWeatherLease()
        }
    }

    Connections {
        target: Weather
        function onEnabledChanged() {
            root._syncWeatherLease()
        }
    }

    // Click-outside-to-close overlay
    LazyLoader {
        active: GlobalStates.waffleWidgetsOpen
        component: PanelWindow {
            anchors { top: true; bottom: true; left: true; right: true }
            WlrLayershell.namespace: "quickshell:wWidgetsBg"
            WlrLayershell.layer: WlrLayer.Top
            color: "transparent"
            MouseArea {
                anchors.fill: parent
                onClicked: GlobalStates.waffleWidgetsOpen = false
            }
        }
    }

    Loader {
        id: panelLoader
        active: GlobalStates.waffleWidgetsOpen
        sourceComponent: PanelWindow {
            id: panelWindow
            exclusiveZone: 0
            WlrLayershell.namespace: "quickshell:wWidgets"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: "transparent"

            anchors {
                bottom: Config.options?.waffles?.bar?.bottom ?? false
                top: !(Config.options?.waffles?.bar?.bottom ?? false)
                left: true
            }

            implicitWidth: content.implicitWidth
            implicitHeight: content.implicitHeight

            Connections {
                target: GlobalStates
                function onWaffleWidgetsOpenChanged() {
                    if (!GlobalStates.waffleWidgetsOpen) content.close()
                }
            }

            WidgetsContent {
                id: content
                anchors.fill: parent

                onClosed: {
                    GlobalStates.waffleWidgetsOpen = false
                    panelLoader.active = false
                }
            }
        }
    }

    function toggleOpen() {
        GlobalStates.waffleWidgetsOpen = !GlobalStates.waffleWidgetsOpen
    }

    IpcHandler {
        target: "wwidgets"
        function toggle(): void { root.toggleOpen() }
        function close(): void { GlobalStates.waffleWidgetsOpen = false }
        function open(): void { GlobalStates.waffleWidgetsOpen = true }
    }
}
