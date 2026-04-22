import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects as GE
import Quickshell.Io
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.common.functions
import qs.modules.background.widgets
import qs.modules.background.widgets.systemMonitor
import qs.services
import "root:"

AbstractBackgroundWidget {
    id: root

    configEntryName: "systemRings"

    readonly property var ringsConfig: configEntry
    readonly property bool showGpu: ringsConfig.showGpu ?? true
    readonly property real cardOpacity: ringsConfig.cardOpacity ?? 0.85
    readonly property point screenPos: root.mapToItem(null, 0, 0)
    readonly property int ringCount: showGpu && ResourceUsage.vramTotal > 1 ? 4 : 3

    implicitWidth: ringCount * 80 + (ringCount - 1) * 16 + 40
    implicitHeight: cardContent.implicitHeight + cardContent.anchors.margins * 2

    Component.onCompleted: ResourceUsage.acquire()
    Component.onDestruction: ResourceUsage.release()

    Timer {
        running: root.visible
        interval: 10000
        repeat: true
        onTriggered: ResourceUsage.ensureRunning()
    }

    // Drop shadow
    StyledRectangularShadow {
        target: cardBackground
        visible: !Appearance.inirEverywhere && !Appearance.auroraEverywhere
    }

    // Glass card background
    Rectangle {
        id: cardBackground
        anchors.fill: parent
        radius: Appearance.rounding.large
        color: "transparent"
        clip: true

        GlassBackground {
            anchors.fill: parent
            radius: parent.radius
            screenX: root.screenPos.x
            screenY: root.screenPos.y
            fallbackColor: ColorUtils.transparentize(
                Appearance.colors.colLayer0,
                1.0 - root.cardOpacity
            )
        }

        Rectangle {
            anchors.fill: parent
            visible: !Appearance.auroraEverywhere && !Appearance.angelEverywhere
            radius: parent.radius
            color: ColorUtils.transparentize(
                Appearance.colors.colLayer0,
                1.0 - root.cardOpacity
            )
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.width: 1
            border.color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.88)
        }

        // Inset depth — top edge gradient
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 1
            height: 6
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.7) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }

    // Click to launch btop (disabled in edit mode to allow dragging)
    MouseArea {
        anchors.fill: parent
        cursorShape: GlobalStates.widgetEditMode ? Qt.ArrowCursor : Qt.PointingHandCursor
        enabled: !GlobalStates.widgetEditMode
        onClicked: btopLauncher.running = true
    }

    Process {
        id: btopLauncher
        command: ["/usr/bin/kitty", "-e", "btop"]
    }

    // Content
    ColumnLayout {
        id: cardContent
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        // Header
        StyledText {
            Layout.alignment: Qt.AlignLeft
            text: "SYSTEM"
            font {
                pixelSize: Appearance.font.pixelSize.smallest
                weight: Font.DemiBold
                letterSpacing: 2.0
                capitalization: Font.AllUppercase
            }
            color: Appearance.colors.colSubtext
        }

        // Rings row
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 16

            CircularProgressRing {
                Layout.alignment: Qt.AlignTop
                value: ResourceUsage.cpuUsage
                ringColor: Appearance.colors.colPrimary
                icon: "settings"
                label: "CPU"
                valueText: Math.round(ResourceUsage.cpuUsage * 100) + "%"
                history: ResourceUsage.cpuUsageHistory
            }

            CircularProgressRing {
                Layout.alignment: Qt.AlignTop
                value: ResourceUsage.memoryUsedPercentage
                ringColor: Appearance.colors.colSecondary
                icon: "grid_view"
                label: "RAM"
                valueText: Math.round(ResourceUsage.memoryUsedPercentage * 100) + "%"
                history: ResourceUsage.memoryUsageHistory
            }

            CircularProgressRing {
                Layout.alignment: Qt.AlignTop
                value: ResourceUsage.cpuTemp > 0 ? Math.min(ResourceUsage.cpuTemp / 100, 1.0) : 0
                ringColor: Appearance.colors.colTertiary
                icon: "thermostat"
                label: "TEMP"
                valueText: ResourceUsage.cpuTemp > 0 ? ResourceUsage.cpuTemp + "\u00B0C" : "--"
            }

            CircularProgressRing {
                Layout.alignment: Qt.AlignTop
                visible: root.showGpu && ResourceUsage.vramTotal > 1
                value: ResourceUsage.vramUsedPercentage
                ringColor: Appearance.m3colors.m3error
                icon: "memory"
                label: "VRAM"
                valueText: {
                    const gb = ResourceUsage.vramUsed / (1024 * 1024 * 1024)
                    return gb.toFixed(1) + " GB"
                }
                history: ResourceUsage.gpuUsageHistory
            }
        }
    }
}
