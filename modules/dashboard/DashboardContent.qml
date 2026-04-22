import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.dashboard
import qs.services

// Three-column layout assembling all dashboard cards.
// Left: identity & controls. Center: performance + activity console. Right: calendar/weather/notifications.
Item {
    id: root

    property bool _resourceLeased: false
    property bool _weatherLeased: false

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
    readonly property bool sectionActivityConsole: Config.options?.dashboard?.activityConsole?.enable ?? true

    RowLayout {
        anchors.fill: parent
        spacing: 20

        // ════════════════════════════════════════════
        // LEFT COLUMN — Identity & Controls (scrollable)
        // ════════════════════════════════════════════
        Flickable {
            Layout.preferredWidth: root.leftColumnWidth
            Layout.fillHeight: true
            contentHeight: leftColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: leftColumn
                width: parent.width
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
                    // Section toggle only — playing/idle state handled internally by MediaCard.
                    visible: root.sectionMedia
                }
            }
        }

        // ════════════════════════════════════════════
        // CENTER COLUMN — Performance, Network & Activity
        // ════════════════════════════════════════════
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            PerformanceBarsCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 270
                visible: root.sectionPerformance
            }

            NetworkSparklinesCard {
                Layout.fillWidth: true
                visible: root.sectionPerformance
            }

            ActivityConsoleCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.sectionActivityConsole
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

    function _syncResourceLease() {
        const active = root.visible && GlobalStates.dashboardOpen
        if (active && !root._resourceLeased) {
            ResourceUsage.acquire()
            root._resourceLeased = true
        } else if (!active && root._resourceLeased) {
            ResourceUsage.release()
            root._resourceLeased = false
        }
    }

    function _syncWeatherLease() {
        const active = root.visible
            && GlobalStates.dashboardOpen
            && root.sectionWeather
            && Weather.enabled
        if (active && !root._weatherLeased) {
            Weather.acquire()
            root._weatherLeased = true
        } else if (!active && root._weatherLeased) {
            Weather.release()
            root._weatherLeased = false
        }
    }

    Component.onCompleted: {
        root._syncResourceLease()
        root._syncWeatherLease()
    }
    Component.onDestruction: {
        if (root._resourceLeased) {
            ResourceUsage.release()
            root._resourceLeased = false
        }
        if (root._weatherLeased) {
            Weather.release()
            root._weatherLeased = false
        }
    }

    onVisibleChanged: {
        root._syncResourceLease()
        root._syncWeatherLease()
    }

    onSectionWeatherChanged: root._syncWeatherLease()

    Connections {
        target: GlobalStates
        function onDashboardOpenChanged() {
            root._syncResourceLease()
            root._syncWeatherLease()
        }
    }

    Connections {
        target: Weather
        function onEnabledChanged() {
            root._syncWeatherLease()
        }
    }
}
