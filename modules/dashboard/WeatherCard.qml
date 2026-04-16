import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.dashboard
import qs.services

DashboardCard {
    id: root
    headerText: ""

    visible: Weather.enabled

    // ── Temperature + icon hero row ──
    RowLayout {
        Layout.fillWidth: true
        spacing: 14

        MaterialSymbol {
            text: Icons.getWeatherIcon(Weather.data?.wCode, Weather.isNightNow()) ?? "cloud"
            iconSize: 36
            color: Appearance.colors.colPrimary
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                text: Weather.data?.temp ?? "--°C"
                font.pixelSize: 28
                font.weight: Font.Bold
                font.family: Appearance.font.family.monospace
                color: Appearance.colors.colOnLayer0
            }

            StyledText {
                text: Weather.data?.description ?? ""
                font.pixelSize: 11
                color: Qt.rgba(1, 1, 1, 0.35)
                visible: text !== ""
            }
        }
    }

    // ── Feels like ──
    StyledText {
        text: "Feels like " + (Weather.data?.tempFeelsLike ?? "--")
        font.pixelSize: Appearance.font.pixelSize.smallest
        color: Appearance.colors.colSubtext
        Layout.fillWidth: true
    }

    // ── Separator ──
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Qt.rgba(1, 1, 1, 0.04)
    }

    // ── Detail row ──
    RowLayout {
        Layout.fillWidth: true
        spacing: 16

        // Wind
        RowLayout {
            spacing: 4
            MaterialSymbol { text: "air"; iconSize: 14; color: Appearance.colors.colSecondary }
            StyledText {
                text: (Weather.data?.windSpeed ?? "--") + " km/h"
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colSubtext
            }
        }

        // Humidity
        RowLayout {
            spacing: 4
            MaterialSymbol { text: "humidity_percentage"; iconSize: 14; color: Appearance.colors.colSecondary }
            StyledText {
                text: (Weather.data?.humidity ?? "--") + "%"
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colSubtext
            }
        }

        // City
        RowLayout {
            spacing: 4
            MaterialSymbol { text: "location_on"; iconSize: 14; color: Appearance.colors.colSecondary }
            StyledText {
                text: Weather.data?.city ?? ""
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colSubtext
                elide: Text.ElideRight
                Layout.maximumWidth: 80
                visible: text !== ""
            }
        }
    }
}
