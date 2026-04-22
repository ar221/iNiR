import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.dashboard
import qs.services

// Dashboard card showing download and upload sparklines.
DashboardCard {
    id: root
    headerText: "Network"

    Component.onCompleted: NetworkUsage.ensureRunning()
    Component.onDestruction: NetworkUsage.stop()

    Sparkline {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 50
        dataPoints: NetworkUsage.downloadHistory
        lineColor: Appearance.colors.colPrimary
        currentSpeed: NetworkUsage.downloadSpeed
        maxSpeed: NetworkUsage.maxSpeed
        speedStr: NetworkUsage.downloadSpeedStr
        label: "DL"
    }

    Sparkline {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 50
        dataPoints: NetworkUsage.uploadHistory
        lineColor: Appearance.colors.colTertiary
        currentSpeed: NetworkUsage.uploadSpeed
        maxSpeed: NetworkUsage.maxSpeed
        speedStr: NetworkUsage.uploadSpeedStr
        label: "UL"
    }
}
