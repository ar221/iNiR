import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

ColumnLayout {
    id: root

    property var configEntry: ({})
    readonly property bool hasWeather: Weather.enabled && Weather.data?.temp && !Weather.data.temp.startsWith("--")

    visible: hasWeather
    spacing: 8

    // Main weather row: icon + temp + description/city
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        MaterialSymbol {
            text: Icons.getWeatherIcon(Weather.data?.wCode, Weather.isNightNow()) ?? "cloud"
            iconSize: 36
            color: Appearance.colors.colPrimary
        }

        StyledText {
            text: Weather.data?.temp ?? "--°C"
            font.pixelSize: Appearance.font.pixelSize.huge
            font.weight: Font.Medium
            font.family: Appearance.font.family.numbers
            color: Appearance.colors.colOnLayer0
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: Weather.data?.city ?? ""
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer0
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: Weather.data?.description ?? ""
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colSubtext
                elide: Text.ElideRight
                visible: text !== ""
            }
        }

        // Refresh button
        RippleButton {
            implicitWidth: 24; implicitHeight: 24
            buttonRadius: 12
            colBackground: "transparent"
            colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.85)
            onClicked: Weather.fetchWeather()
            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                text: "refresh"
                iconSize: 14
                color: Appearance.colors.colSubtext
            }
        }
    }

    // Detail pills row
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        // Humidity pill
        Rectangle {
            visible: Weather.data?.humidity
            Layout.preferredHeight: 26
            Layout.preferredWidth: humidRow.implicitWidth + 14
            radius: 13
            color: ColorUtils.transparentize(Appearance.colors.colSurfaceContainer, 0.4)

            RowLayout {
                id: humidRow
                anchors.centerIn: parent
                spacing: 4
                MaterialSymbol { text: "humidity_percentage"; iconSize: 13; color: Appearance.colors.colPrimary }
                StyledText {
                    text: Weather.data?.humidity ?? ""
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colOnLayer0
                }
            }
        }

        // Wind pill
        Rectangle {
            visible: Weather.data?.wind
            Layout.preferredHeight: 26
            Layout.preferredWidth: windRow.implicitWidth + 14
            radius: 13
            color: ColorUtils.transparentize(Appearance.colors.colSurfaceContainer, 0.4)

            RowLayout {
                id: windRow
                anchors.centerIn: parent
                spacing: 4
                MaterialSymbol { text: "air"; iconSize: 13; color: Appearance.colors.colSecondary }
                StyledText {
                    text: (Weather.data?.wind ?? "") + (Weather.data?.windDir ? " " + Weather.data.windDir : "")
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colOnLayer0
                }
            }
        }

        // UV pill
        Rectangle {
            visible: Weather.data?.uv && Weather.data.uv !== "0"
            Layout.preferredHeight: 26
            Layout.preferredWidth: uvRow.implicitWidth + 14
            radius: 13
            color: ColorUtils.transparentize(Appearance.colors.colSurfaceContainer, 0.4)

            RowLayout {
                id: uvRow
                anchors.centerIn: parent
                spacing: 4
                MaterialSymbol {
                    text: "wb_sunny"
                    iconSize: 13
                    color: {
                        const uv = parseInt(Weather.data?.uv ?? "0")
                        return uv >= 6 ? Appearance.colors.colError : Appearance.colors.colTertiary
                    }
                }
                StyledText {
                    text: "UV " + (Weather.data?.uv ?? "")
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colOnLayer0
                }
            }
        }

        Item { Layout.fillWidth: true }
    }
}
