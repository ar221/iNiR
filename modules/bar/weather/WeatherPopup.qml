import qs.services
import qs.modules.common
import qs.modules.common.widgets

import QtQuick
import QtQuick.Layouts
import qs.modules.bar

StyledPopup {
    id: root

    ColumnLayout {
        id: columnLayout
        anchors.centerIn: parent
        implicitWidth: Math.max(header.implicitWidth, gridLayout.implicitWidth)
        spacing: 8

        // Header
        ColumnLayout {
            id: header
            Layout.alignment: Qt.AlignHCenter
            spacing: 4

            RowLayout {
                visible: Weather.showVisibleCity
                Layout.alignment: Qt.AlignHCenter
                spacing: 6

                MaterialSymbol {
                    fill: 0
                    font.weight: Font.Medium
                    text: "location_on"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnSurfaceVariant
                }

                StyledText {
                    text: Weather.visibleCity
                    font {
                        weight: Font.Medium
                        pixelSize: Appearance.font.pixelSize.normal
                    }
                    color: Appearance.colors.colOnSurfaceVariant
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8

                MaterialSymbol {
                    text: Icons.getWeatherIcon(Weather.data?.wCode, Weather.isNightNow()) ?? "cloud"
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colOnSurfaceVariant
                }

                ColumnLayout {
                    spacing: 0

                    StyledText {
                        text: Weather.data.temp
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnSurfaceVariant
                    }

                    StyledText {
                        text: Weather.data.description
                        visible: text !== ""
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        color: Appearance.colors.colSubtext
                    }
                }
            }

            StyledText {
                id: temp
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnSurfaceVariant
                text: Translation.tr("Feels like %1 · %2").arg(Weather.data.tempFeelsLike).arg(Weather.data.wind)
            }
        }

        // Metrics grid
        GridLayout {
            id: gridLayout
            columns: 2
            rowSpacing: 5
            columnSpacing: 5
            uniformCellWidths: true

            WeatherCard {
                title: Translation.tr("UV Index")
                symbol: "wb_sunny"
                value: Weather.data.uv
            }
            WeatherCard {
                title: Translation.tr("Wind")
                symbol: "air"
                value: `(${Weather.data.windDir}) ${Weather.data.wind}`
            }
            WeatherCard {
                title: Translation.tr("Precipitation")
                symbol: "rainy_light"
                value: Weather.data.precip
            }
            WeatherCard {
                title: Translation.tr("Humidity")
                symbol: "humidity_low"
                value: Weather.data.humidity
            }
            WeatherCard {
                title: Translation.tr("Visibility")
                symbol: "visibility"
                value: Weather.data.visib
            }
            WeatherCard {
                title: Translation.tr("Pressure")
                symbol: "readiness_score"
                value: Weather.data.press
            }
            WeatherCard {
                title: Translation.tr("Sunrise")
                symbol: "wb_twilight"
                value: Weather.data.sunrise
            }
            WeatherCard {
                title: Translation.tr("Sunset")
                symbol: "bedtime"
                value: Weather.data.sunset
            }
        }

        // Footer actions
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8

            Rectangle {
                radius: 8
                color: refreshMouse.containsMouse
                    ? Appearance.colors.colLayer2
                    : Appearance.colors.colLayer1
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.08)
                implicitWidth: refreshRow.implicitWidth + 16
                implicitHeight: refreshRow.implicitHeight + 8

                RowLayout {
                    id: refreshRow
                    anchors.centerIn: parent
                    spacing: 4
                    MaterialSymbol {
                        text: Weather.hasRunningRequests() ? "progress_activity" : "refresh"
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                    StyledText {
                        text: Weather.hasRunningRequests() ? Translation.tr("Refreshing") : Translation.tr("Refresh")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                }

                MouseArea {
                    id: refreshMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Weather.forceRefresh()
                }
            }

            Rectangle {
                radius: 8
                color: dashMouse.containsMouse
                    ? Appearance.colors.colLayer2
                    : Appearance.colors.colLayer1
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.08)
                implicitWidth: dashRow.implicitWidth + 16
                implicitHeight: dashRow.implicitHeight + 8

                RowLayout {
                    id: dashRow
                    anchors.centerIn: parent
                    spacing: 4
                    MaterialSymbol {
                        text: "dashboard"
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                    StyledText {
                        text: Translation.tr("Open Dashboard")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                }

                MouseArea {
                    id: dashMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        GlobalStates.dashboardOpen = true
                        root.active = false
                    }
                }
            }
        }

        // Footer: last refresh
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Translation.tr("Last refresh: %1").arg(Weather.data.lastRefresh)
            font {
                weight: Font.Medium
                pixelSize: Appearance.font.pixelSize.smaller
            }
            color: Appearance.colors.colOnSurfaceVariant
        }
    }
}
