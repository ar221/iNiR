import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.dashboard
import qs.services

// Three-column layout assembling all dashboard cards.
// Left: identity & controls. Center: Phase 3 placeholder. Right: calendar/weather/notifications.
Item {
    id: root

    readonly property int leftColumnWidth: Config.options?.dashboard?.layout?.leftColumnWidth ?? 260
    readonly property int rightColumnWidth: Config.options?.dashboard?.layout?.rightColumnWidth ?? 240
    readonly property bool sectionProfile: Config.options?.dashboard?.sections?.profile ?? true
    readonly property bool sectionSystemInfo: Config.options?.dashboard?.sections?.systemInfo ?? true
    readonly property bool sectionQuickToggles: Config.options?.dashboard?.sections?.quickToggles ?? true
    readonly property bool sectionMedia: Config.options?.dashboard?.sections?.media ?? true
    readonly property bool sectionPerformance: Config.options?.dashboard?.sections?.performance ?? true
    readonly property bool sectionCalendar: Config.options?.dashboard?.sections?.calendar ?? true
    readonly property bool sectionWeather: Config.options?.dashboard?.sections?.weather ?? true
    readonly property bool sectionNotifications: Config.options?.dashboard?.sections?.notifications ?? true

    RowLayout {
        anchors.fill: parent
        spacing: 20

        // ════════════════════════════════════════════
        // LEFT COLUMN — Identity & Controls
        // ════════════════════════════════════════════
        ColumnLayout {
            Layout.preferredWidth: root.leftColumnWidth
            Layout.fillHeight: true
            spacing: 12

            ProfileCard {
                Layout.fillWidth: true
                visible: root.sectionProfile
            }

            SystemInfoCard {
                Layout.fillWidth: true
                visible: root.sectionSystemInfo
            }

            QuickTogglesCard {
                Layout.fillWidth: true
                visible: root.sectionQuickToggles
            }

            MediaCard {
                Layout.fillWidth: true
                visible: root.sectionMedia
            }

            Item { Layout.fillHeight: true }
        }

        // ════════════════════════════════════════════
        // CENTER COLUMN — Performance & Activity (Phase 3 placeholder)
        // ════════════════════════════════════════════
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            // Phase 3: PerformanceBars will go here
            // Phase 3: NetworkSparklines will go here
            // Phase 4: ActivityConsole will go here

            // Placeholder card while center column content is pending
            DashboardCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.sectionPerformance

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 12

                        MaterialSymbol {
                            Layout.alignment: Qt.AlignHCenter
                            text: "monitoring"
                            iconSize: 48
                            color: Qt.rgba(1, 1, 1, 0.08)
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Performance metrics"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            color: Qt.rgba(1, 1, 1, 0.15)
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Bar charts, sparklines, and activity console\ncoming in Phase 3-4"
                            font.pixelSize: 11
                            color: Qt.rgba(1, 1, 1, 0.1)
                            horizontalAlignment: Text.AlignHCenter
                        }

                        // Quick resource summary in the meantime
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 12
                            spacing: 24

                            ColumnLayout {
                                spacing: 2
                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: Math.round(ResourceUsage.cpuUsage * 100) + "%"
                                    font.pixelSize: 18
                                    font.weight: Font.Bold
                                    font.family: Appearance.font.family.numbers
                                    color: Appearance.colors.colPrimary
                                }
                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "CPU"
                                    font.pixelSize: 9
                                    font.letterSpacing: 1.0
                                    color: Qt.rgba(1, 1, 1, 0.3)
                                }
                            }

                            ColumnLayout {
                                spacing: 2
                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: Math.round(ResourceUsage.gpuUsage * 100) + "%"
                                    font.pixelSize: 18
                                    font.weight: Font.Bold
                                    font.family: Appearance.font.family.numbers
                                    color: Appearance.colors.colSecondary
                                }
                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "GPU"
                                    font.pixelSize: 9
                                    font.letterSpacing: 1.0
                                    color: Qt.rgba(1, 1, 1, 0.3)
                                }
                            }

                            ColumnLayout {
                                spacing: 2
                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: Math.round(ResourceUsage.memoryUsedPercentage * 100) + "%"
                                    font.pixelSize: 18
                                    font.weight: Font.Bold
                                    font.family: Appearance.font.family.numbers
                                    color: Appearance.colors.colTertiary
                                }
                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "RAM"
                                    font.pixelSize: 9
                                    font.letterSpacing: 1.0
                                    color: Qt.rgba(1, 1, 1, 0.3)
                                }
                            }

                            ColumnLayout {
                                spacing: 2
                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: ResourceUsage.maxTemp + "°"
                                    font.pixelSize: 18
                                    font.weight: Font.Bold
                                    font.family: Appearance.font.family.numbers
                                    color: Appearance.colors.colError
                                }
                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "TEMP"
                                    font.pixelSize: 9
                                    font.letterSpacing: 1.0
                                    color: Qt.rgba(1, 1, 1, 0.3)
                                }
                            }
                        }
                    }
                }
            }
        }

        // ════════════════════════════════════════════
        // RIGHT COLUMN — Calendar, Weather, Notifications
        // ════════════════════════════════════════════
        ColumnLayout {
            Layout.preferredWidth: root.rightColumnWidth
            Layout.fillHeight: true
            spacing: 12

            CalendarCard {
                Layout.fillWidth: true
                visible: root.sectionCalendar
            }

            WeatherCard {
                Layout.fillWidth: true
                visible: root.sectionWeather
            }

            NotificationsCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.sectionNotifications
            }
        }
    }

    Component.onCompleted: {
        ResourceUsage.ensureRunning()
    }
}
