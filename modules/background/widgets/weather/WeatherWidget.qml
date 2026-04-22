import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.background.widgets

AbstractBackgroundWidget {
    id: root

    configEntryName: "weather"

    implicitHeight: backgroundShape.implicitHeight
    implicitWidth: backgroundShape.implicitWidth

    property bool _weatherLeased: false

    function _syncWeatherLease() {
        const active = root.visible && Weather.enabled
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

    onVisibleChanged: root._syncWeatherLease()

    Connections {
        target: Weather
        function onEnabledChanged() {
            root._syncWeatherLease()
        }
    }

    StyledDropShadow {
        target: backgroundShape
    }

    MaterialShape {
        id: backgroundShape
        anchors.fill: parent
        shape: MaterialShape.Shape.Pill
        color: Appearance.colors.colPrimaryContainer
        implicitSize: 200

        StyledText {
            font {
                pixelSize: 80
                family: Appearance.font.family.expressive
                weight: Font.Medium
            }
            color: Appearance.colors.colPrimary
            text: Weather.data?.temp.substring(0,Weather.data?.temp.length - 1) ?? "--°"
            anchors {
                right: parent.right
                top: parent.top
                rightMargin: 20
                topMargin: 24
            }
        }

        MaterialSymbol {
            iconSize: 80
            color: Appearance.colors.colOnPrimaryContainer
            text: Icons.getWeatherIcon(Weather.data?.wCode, Weather.isNightNow()) ?? "cloud"
            anchors {
                left: parent.left
                bottom: parent.bottom

                leftMargin: 20
                bottomMargin: 24
            }
        }
    }
}
