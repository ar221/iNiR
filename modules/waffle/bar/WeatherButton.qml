import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.waffle.looks

BarButton {
    id: root

    property bool _weatherLeased: false

    leftInset: 8
    rightInset: 8
    implicitWidth: contentRow.implicitWidth + leftInset + rightInset + 8
    readonly property string locationText: Weather.visibleCity
    readonly property string secondaryText: locationText || root.weatherDescription

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

    onClicked: {
        Weather.forceRefresh()
        GlobalStates.waffleWidgetsOpen = !GlobalStates.waffleWidgetsOpen
    }

    contentItem: RowLayout {
        id: contentRow
        spacing: 8
        anchors.centerIn: parent

        MaterialSymbol {
            text: Icons.getWeatherIcon(Weather.data?.wCode, Weather.isNightNow()) ?? "cloud"
            iconSize: 20
            color: Looks.colors.fg
            Layout.alignment: Qt.AlignVCenter
        }

        Column {
            width: 92
            spacing: 0
            Layout.alignment: Qt.AlignVCenter

            WText {
                width: parent.width
                text: Weather.data?.temp ?? "--°"
                font.pixelSize: Looks.font.pixelSize.normal
                font.weight: Font.Medium
                color: Looks.colors.fg
                elide: Text.ElideRight
            }

            WText {
                width: parent.width
                text: root.secondaryText
                font.pixelSize: Looks.font.pixelSize.tiny
                color: Looks.colors.subfg
                elide: Text.ElideRight
            }
        }
    }

    // Weather description based on code
    readonly property string weatherDescription: Weather.describeWeather(Weather.data?.wCode ?? "113")

    BarToolTip {
        extraVisibleCondition: root.shouldShowTooltip
        text: Weather.showVisibleCity ? Weather.visibleCity : root.weatherDescription
    }
}
