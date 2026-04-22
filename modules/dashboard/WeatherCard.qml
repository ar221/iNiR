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

    visible: Weather.readyForDisplay

    // Heat-gradient: cool → warm → hot across palette.
    // Maps parsed integer temp (°C/°F) from 0°C (colSubtext) to 40°C+ (colError).
    // Shared by current hero, hourly strip, and 7-day high/low.
    function tempColor(tempRaw) {
        const n = typeof tempRaw === "number" ? tempRaw : parseInt(tempRaw)
        if (isNaN(n)) return Appearance.colors.colSubtext
        const ceil = Weather.useUSCS ? 104 : 40   // 40°C = 104°F
        const t = Math.min(1, Math.max(0, n / ceil))
        return ColorUtils.mix(Appearance.colors.colError, Appearance.colors.colSubtext, 1 - t)
    }

    // ── Temperature + icon hero row ──
    RowLayout {
        Layout.fillWidth: true
        spacing: 14

        MaterialSymbol {
            text: Icons.getWeatherIcon(Weather.data?.wCode, Weather.isNightNow()) ?? "cloud"
            iconSize: 36
            color: Appearance.colors.colSubtext
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                text: Weather.data?.temp ?? "--°C"
                font.pixelSize: 28
                font.weight: Font.Bold
                font.family: Appearance.font.family.monospace
                color: root.tempColor(parseInt(Weather.data?.temp ?? "0"))
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
            MaterialSymbol { text: "air"; iconSize: 14; color: Appearance.colors.colSubtext }
            StyledText {
                text: (Weather.data?.windSpeed ?? "--") + " km/h"
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colSubtext
            }
        }

        // Humidity
        RowLayout {
            spacing: 4
            MaterialSymbol { text: "humidity_percentage"; iconSize: 14; color: Appearance.colors.colSubtext }
            StyledText {
                text: Weather.data?.humidity ?? "--"
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colSubtext
            }
        }

        // City
        RowLayout {
            spacing: 4
            MaterialSymbol { text: "location_on"; iconSize: 14; color: Appearance.colors.colSubtext }
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

    // ── Hourly strip — next 12 hours ──
    // Hidden until data arrives; no flash on cold start.
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6
        visible: Weather.hourly.length > 0

        // Divider
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Qt.rgba(1, 1, 1, 0.04)
        }

        // Row of hour cells — 12 hours, evenly spaced
        Row {
            id: hourlyRow
            Layout.fillWidth: true
            spacing: 0

            Repeater {
                id: hourlyRepeater
                model: Weather.hourly.length

                // Each cell: hour label, condition icon, temp
                // Access model via Weather.hourly[index] to avoid required property crash
                Item {
                    property var entry: index < Weather.hourly.length ? Weather.hourly[index] : null

                    width: hourlyRow.width / Math.max(1, Weather.hourly.length)
                    implicitHeight: hCell.implicitHeight

                    ColumnLayout {
                        id: hCell
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 3

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: entry?.time ?? ""
                            font.pixelSize: Appearance.font.pixelSize.smallest - 1
                            color: Appearance.colors.colSubtext
                            opacity: 0.7
                        }

                        MaterialSymbol {
                            Layout.alignment: Qt.AlignHCenter
                            text: Icons.getWeatherIcon(entry?.wCode, !(entry?.isDay ?? true)) ?? "cloud"
                            iconSize: 14
                            color: Appearance.colors.colSubtext
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: entry?.temp ?? ""
                            font.pixelSize: Appearance.font.pixelSize.smallest - 1
                            font.family: Appearance.font.family.monospace
                            color: root.tempColor(entry?.tempRaw ?? 0)
                        }
                    }
                }
            }
        }
    }

    // ── 7-day forecast row ──
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6
        visible: Weather.daily.length > 0

        // Divider
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Qt.rgba(1, 1, 1, 0.04)
        }

        Row {
            id: dailyRow
            Layout.fillWidth: true
            spacing: 0

            Repeater {
                id: dailyRepeater
                model: Weather.daily.length

                Item {
                    property var entry: index < Weather.daily.length ? Weather.daily[index] : null

                    width: dailyRow.width / Math.max(1, Weather.daily.length)
                    implicitHeight: dCell.implicitHeight

                    ColumnLayout {
                        id: dCell
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 3

                        // Day label
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: entry?.day ?? ""
                            font.pixelSize: Appearance.font.pixelSize.smallest - 1
                            font.weight: (entry?.day ?? "") === "Today" ? Font.DemiBold : Font.Normal
                            color: (entry?.day ?? "") === "Today"
                                ? Appearance.colors.colOnLayer1
                                : Appearance.colors.colSubtext
                            opacity: (entry?.day ?? "") === "Today" ? 1 : 0.7
                        }

                        // Condition icon — always daytime variant for daily summary
                        MaterialSymbol {
                            Layout.alignment: Qt.AlignHCenter
                            text: Icons.getWeatherIcon(entry?.wCode, false) ?? "cloud"
                            iconSize: 14
                            color: Appearance.colors.colSubtext
                        }

                        // High temp
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: entry?.tempMax ?? ""
                            font.pixelSize: Appearance.font.pixelSize.smallest - 1
                            font.family: Appearance.font.family.monospace
                            color: root.tempColor(entry?.tempMaxRaw ?? 0)
                        }

                        // Low temp — dimmed so high reads first
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: entry?.tempMin ?? ""
                            font.pixelSize: Appearance.font.pixelSize.smallest - 1
                            font.family: Appearance.font.family.monospace
                            color: root.tempColor(entry?.tempMinRaw ?? 0)
                            opacity: 0.55
                        }

                        // Precipitation chance — only shown when ≥30%
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            visible: (entry?.precipChance ?? 0) >= 30
                            text: (entry?.precipChance ?? 0) + "%"
                            font.pixelSize: Appearance.font.pixelSize.smallest - 2
                            color: Appearance.colors.colTertiary
                            opacity: 0.8
                        }
                    }
                }
            }
        }
    }
}
