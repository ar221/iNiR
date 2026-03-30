import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects as GE
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.common.functions
import qs.modules.background.widgets
import qs.services

AbstractBackgroundWidget {
    id: root

    configEntryName: "systemMonitor"

    readonly property var monitorConfig: configEntry
    readonly property real cardWidth: monitorConfig.cardWidth ?? 380
    readonly property real minCardWidth: 300
    readonly property real maxCardWidth: 600
    readonly property point screenPos: root.mapToItem(null, 0, 0)

    implicitWidth: cardWidth
    implicitHeight: cardContent.implicitHeight + cardContent.anchors.margins * 2

    Component.onCompleted: ResourceUsage.ensureRunning()
    Component.onDestruction: ResourceUsage.stop()

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
                1.0 - (root.monitorConfig.cardOpacity ?? 0.85)
            )
        }

        Rectangle {
            anchors.fill: parent
            visible: !Appearance.auroraEverywhere && !Appearance.angelEverywhere
            radius: parent.radius
            color: ColorUtils.transparentize(
                Appearance.colors.colLayer0,
                1.0 - (root.monitorConfig.cardOpacity ?? 0.85)
            )
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.width: 1
            border.color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.88)
        }
    }

    // Resize handle
    MouseArea {
        id: resizeHandle
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: 20
        height: 20
        cursorShape: Qt.SizeFDiagCursor
        z: 10

        property real startX: 0
        property real startWidth: 0

        onPressed: mouse => {
            startX = mouse.x + resizeHandle.x
            startWidth = root.cardWidth
        }

        onPositionChanged: mouse => {
            if (pressed) {
                const delta = (mouse.x + resizeHandle.x) - startX
                const newWidth = Math.max(root.minCardWidth, Math.min(root.maxCardWidth, startWidth + delta))
                root.monitorConfig.cardWidth = newWidth
            }
        }

        Repeater {
            model: 3
            Rectangle {
                required property int index
                width: 2; height: 2; radius: 1
                x: 14 - 6 + index * 3
                y: 14 - 6 + (2 - index) * 3
                color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.6)
                visible: resizeHandle.containsMouse || resizeHandle.pressed
            }
        }
    }

    // Content
    ColumnLayout {
        id: cardContent
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        // ── Profile ──
        ProfileSection {
            Layout.fillWidth: true
            visible: root.monitorConfig.showProfile ?? true
            configEntry: root.monitorConfig
        }

        // ── Separator ──
        SectionSeparator {
            visible: (root.monitorConfig.showProfile ?? true)
                && (root.monitorConfig.showCalendar ?? true)
        }

        // ── Calendar (includes clock + day name) ──
        CalendarSection {
            Layout.fillWidth: true
            visible: root.monitorConfig.showCalendar ?? true
            configEntry: root.monitorConfig
        }

        // ── Calendar Events ──
        CalendarEventsSection {
            Layout.fillWidth: true
            visible: root.monitorConfig.showEvents ?? true
            configEntry: root.monitorConfig
        }

        // ── Separator ──
        SectionSeparator {
            visible: ((root.monitorConfig.showCalendar ?? true) || (root.monitorConfig.showEvents ?? true))
                && (root.monitorConfig.showWeather ?? true)
        }

        // ── Weather ──
        WeatherSection {
            Layout.fillWidth: true
            visible: (root.monitorConfig.showWeather ?? true) && Weather.enabled
            configEntry: root.monitorConfig
        }

        // ── Separator ──
        SectionSeparator {
            visible: {
                const above = ((root.monitorConfig.showWeather ?? true) && Weather.enabled)
                const below = root.monitorConfig.showSystem ?? true
                return above && below
            }
        }

        // ── System rings ──
        SystemSection {
            Layout.alignment: Qt.AlignHCenter
            visible: root.monitorConfig.showSystem ?? true
            configEntry: root.monitorConfig
        }

        // ── Separator ──
        SectionSeparator {
            visible: (root.monitorConfig.showSystem ?? true) && (root.monitorConfig.showStorage ?? true)
        }

        // ── Storage bars ──
        StorageSection {
            Layout.fillWidth: true
            visible: root.monitorConfig.showStorage ?? true
            configEntry: root.monitorConfig
        }

        // ── Separator ──
        SectionSeparator {
            visible: ((root.monitorConfig.showStorage ?? true) || (root.monitorConfig.showSystem ?? true))
                && (root.monitorConfig.showMedia ?? true)
        }

        // ── Media player ──
        MediaSection {
            Layout.fillWidth: true
            visible: root.monitorConfig.showMedia ?? true
            configEntry: root.monitorConfig
        }

        // ── Separator ──
        SectionSeparator {
            visible: (root.monitorConfig.showMedia ?? true)
                && (root.monitorConfig.showNetwork ?? true)
        }

        // ── Network ──
        NetworkSection {
            Layout.fillWidth: true
            visible: root.monitorConfig.showNetwork ?? true
            configEntry: root.monitorConfig
        }

        // Footer removed — was getting cut off and not adding value
    }

    // Reusable separator component
    component SectionSeparator: Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.88)
    }
}
