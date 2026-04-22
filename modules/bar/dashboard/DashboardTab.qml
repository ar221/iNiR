pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

Item {
    id: root

    property bool weatherLeaseActive: false
    property bool _weatherLeased: false

    implicitWidth: mainGrid.implicitWidth + 20
    implicitHeight: mainGrid.implicitHeight + 20

    readonly property var locale: Qt.locale()
    readonly property date today: DateTime.clock.date
    property int focusedMonth: root.today.getMonth()
    property int focusedYear: root.today.getFullYear()

    // System info
    property string osName: "..."
    property string wmName: "..."
    property string uptimeStr: DateTime.uptime

    Process {
        id: osProc
        command: ["/usr/bin/bash", "-c", "grep -oP '(?<=^NAME=).+' /etc/os-release | tr -d '\"'"]
        stdout: SplitParser { splitMarker: ""; onRead: data => { root.osName = data.trim() || "Linux" } }
    }
    Process {
        id: wmProc
        command: ["/usr/bin/bash", "-c", "echo $XDG_CURRENT_DESKTOP"]
        stdout: SplitParser { splitMarker: ""; onRead: data => { root.wmName = data.trim() || "niri" } }
    }
    Component.onCompleted: {
        osProc.running = true
        wmProc.running = true
        ResourceUsage.acquire()
        root._syncWeatherLease()
    }
    Component.onDestruction: {
        ResourceUsage.release()
        if (root._weatherLeased) {
            Weather.release()
            root._weatherLeased = false
        }
    }

    function _syncWeatherLease() {
        const active = root.weatherLeaseActive && Weather.enabled
        if (active && !root._weatherLeased) {
            Weather.acquire()
            root._weatherLeased = true
        } else if (!active && root._weatherLeased) {
            Weather.release()
            root._weatherLeased = false
        }
    }

    onWeatherLeaseActiveChanged: root._syncWeatherLease()

    Connections {
        target: Weather
        function onEnabledChanged() {
            root._syncWeatherLease()
        }
    }

    // ── Card background helper ──
    readonly property color cardBg: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.4)
    readonly property color cardBorder: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.92)

    GridLayout {
        id: mainGrid
        anchors.fill: parent
        anchors.margins: 10
        columns: 6
        rows: 2
        columnSpacing: 8
        rowSpacing: 8

        // ════════════════════════════════════════════
        // Row 0, Col 0-1: Weather card
        // ════════════════════════════════════════════
        Rectangle {
            Layout.row: 0; Layout.column: 0; Layout.columnSpan: 2
            Layout.fillWidth: true; Layout.fillHeight: true
            radius: Appearance.rounding.small
            color: root.cardBg; border.width: 1; border.color: root.cardBorder
            visible: Weather.readyForDisplay

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 6

                RowLayout {
                    spacing: 10
                    MaterialSymbol {
                        text: Icons.getWeatherIcon(Weather.data?.wCode, Weather.isNightNow()) ?? "cloud"
                        iconSize: 36
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: Weather.data?.temp ?? "--\u00b0C"
                        font.pixelSize: Appearance.font.pixelSize.larger
                        font.weight: Font.Bold
                        font.family: Appearance.font.family.numbers
                        color: Appearance.colors.colOnLayer0
                    }
                }

                StyledText {
                    text: "Feels like " + (Weather.data?.tempFeelsLike ?? "--") + "  \u00b7  " + (Weather.data?.city ?? "")
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                RowLayout {
                    spacing: 12

                    RowLayout {
                        spacing: 4
                        MaterialSymbol { text: "humidity_percentage"; iconSize: 14; color: Appearance.colors.colSecondary }
                        StyledText {
                            text: Weather.data?.humidity ?? "--"
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            color: Appearance.colors.colSubtext
                        }
                    }

                    RowLayout {
                        spacing: 4
                        MaterialSymbol { text: "air"; iconSize: 14; color: Appearance.colors.colSecondary }
                        StyledText {
                            text: (Weather.data?.windSpeed ?? "--") + " km/h"
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            color: Appearance.colors.colSubtext
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }

        // Invisible spacer when weather is hidden so grid doesn't collapse
        Item {
            Layout.row: 0; Layout.column: 0; Layout.columnSpan: 2
            Layout.fillWidth: true; Layout.fillHeight: true
            visible: !Weather.readyForDisplay
        }

        // ════════════════════════════════════════════
        // Row 0, Col 2-4: User profile card
        // ════════════════════════════════════════════
        Rectangle {
            Layout.row: 0; Layout.column: 2; Layout.columnSpan: 3
            Layout.fillWidth: true; Layout.fillHeight: true
            radius: Appearance.rounding.small
            color: root.cardBg; border.width: 1; border.color: root.cardBorder

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 14

                // Profile picture
                Rectangle {
                    width: 48; height: 48; radius: Appearance.rounding.full
                    color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.8)
                    clip: true

                    Image {
                        id: profileImg
                        anchors.fill: parent
                        source: "file:///home/ayaz/.face"
                        fillMode: Image.PreserveAspectCrop
                        visible: status === Image.Ready
                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        visible: profileImg.status !== Image.Ready
                        text: "person"
                        iconSize: 28
                        color: Appearance.colors.colPrimary
                    }
                }

                // Info lines
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    RowLayout {
                        spacing: 6
                        MaterialSymbol { text: "computer"; iconSize: 14; color: Appearance.colors.colPrimary }
                        StyledText {
                            text: ": " + root.osName
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnLayer0
                        }
                    }
                    RowLayout {
                        spacing: 6
                        MaterialSymbol { text: "desktop_windows"; iconSize: 14; color: Appearance.colors.colSecondary }
                        StyledText {
                            text: ": " + root.wmName
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnLayer0
                        }
                    }
                    RowLayout {
                        spacing: 6
                        MaterialSymbol { text: "schedule"; iconSize: 14; color: Appearance.colors.colTertiary }
                        StyledText {
                            text: ": up " + root.uptimeStr
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnLayer0
                        }
                    }
                }
            }
        }

        // ════════════════════════════════════════════
        // Row 1, Col 0: DateTime stacked clock
        // ════════════════════════════════════════════
        Rectangle {
            Layout.row: 1; Layout.column: 0; Layout.columnSpan: 1
            Layout.fillWidth: true; Layout.fillHeight: true
            radius: Appearance.rounding.small
            color: root.cardBg; border.width: 1; border.color: root.cardBorder

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 0

                StyledText {
                    text: {
                        const h = root.today.getHours()
                        const h12 = h % 12 || 12
                        return h12.toString().padStart(2, "0")
                    }
                    font.pixelSize: 42
                    font.family: Appearance.font.family.numbers
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnLayer0
                    Layout.alignment: Qt.AlignHCenter
                }

                StyledText {
                    text: "\u00b7\u00b7\u00b7"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: -4
                    Layout.bottomMargin: -4
                }

                StyledText {
                    text: root.today.getMinutes().toString().padStart(2, "0")
                    font.pixelSize: 42
                    font.family: Appearance.font.family.numbers
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnLayer0
                    Layout.alignment: Qt.AlignHCenter
                }

                StyledText {
                    text: root.today.getHours() >= 12 ? "PM" : "AM"
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colSubtext
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        // ════════════════════════════════════════════
        // Row 1, Col 1-3: Calendar
        // ════════════════════════════════════════════
        Rectangle {
            Layout.row: 1; Layout.column: 1; Layout.columnSpan: 3
            Layout.fillWidth: true; Layout.fillHeight: true
            radius: Appearance.rounding.small
            color: root.cardBg; border.width: 1; border.color: root.cardBorder

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 4

                // Month/year nav
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    RippleButton {
                        implicitWidth: 24; implicitHeight: 24; buttonRadius: 12
                        colBackground: "transparent"
                        colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.85)
                        onClicked: { root.focusedMonth--; if (root.focusedMonth < 0) { root.focusedMonth = 11; root.focusedYear-- } }
                        contentItem: MaterialSymbol { anchors.centerIn: parent; text: "chevron_left"; iconSize: 14; color: Appearance.colors.colPrimary }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: {
                            const d = new Date(root.focusedYear, root.focusedMonth, 1)
                            return d.toLocaleDateString(root.locale, "MMMM yyyy")
                        }
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer0
                    }

                    RippleButton {
                        implicitWidth: 24; implicitHeight: 24; buttonRadius: 12
                        colBackground: "transparent"
                        colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.85)
                        onClicked: { root.focusedMonth++; if (root.focusedMonth > 11) { root.focusedMonth = 0; root.focusedYear++ } }
                        contentItem: MaterialSymbol { anchors.centerIn: parent; text: "chevron_right"; iconSize: 14; color: Appearance.colors.colPrimary }
                    }
                }

                // Day headers
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Repeater {
                        model: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                        StyledText {
                            required property string modelData
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colSubtext
                        }
                    }
                }

                // Day grid
                GridLayout {
                    Layout.fillWidth: true
                    columns: 7
                    rowSpacing: 2
                    columnSpacing: 0

                    Repeater {
                        model: root.calendarDays()

                        Item {
                            id: dayCell
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 26

                            Rectangle {
                                anchors.centerIn: parent
                                width: 24; height: 24; radius: Appearance.rounding.full
                                color: dayCell.modelData.isToday ? Appearance.colors.colPrimary : "transparent"
                            }

                            StyledText {
                                anchors.centerIn: parent
                                text: dayCell.modelData.day
                                font.pixelSize: Appearance.font.pixelSize.smallest
                                font.weight: dayCell.modelData.isToday ? Font.Bold : Font.Normal
                                color: dayCell.modelData.isToday ? Appearance.colors.colOnPrimary
                                     : dayCell.modelData.isCurrentMonth ? Appearance.colors.colOnLayer0
                                     : ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.6)
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }

        // ════════════════════════════════════════════
        // Row 1, Col 4: Resource bars (vertical, bottom-to-top)
        // ════════════════════════════════════════════
        Rectangle {
            Layout.row: 1; Layout.column: 4; Layout.columnSpan: 1
            Layout.fillWidth: true; Layout.fillHeight: true
            radius: Appearance.rounding.small
            color: root.cardBg; border.width: 1; border.color: root.cardBorder

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Repeater {
                    model: [
                        { icon: "memory_alt", value: ResourceUsage.cpuUsage, col: Appearance.colors.colPrimary },
                        { icon: "memory", value: ResourceUsage.memoryUsedPercentage, col: Appearance.colors.colSecondary },
                        { icon: "graphic_eq", value: ResourceUsage.gpuUsage, col: Appearance.colors.colTertiary }
                    ]

                    ColumnLayout {
                        id: barDelegate
                        required property var modelData
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        spacing: 6

                        // Vertical bar track
                        Item {
                            Layout.fillHeight: true
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: 14

                            // Track background
                            Rectangle {
                                anchors.fill: parent
                                radius: Appearance.rounding.normal
                                color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.9)
                            }

                            // Filled portion (bottom to top)
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width
                                height: parent.height * barDelegate.modelData.value
                                radius: Appearance.rounding.normal
                                color: barDelegate.modelData.col

                                Behavior on height {
                                    NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
                                }
                            }
                        }

                        // Icon below bar
                        MaterialSymbol {
                            Layout.alignment: Qt.AlignHCenter
                            text: barDelegate.modelData.icon
                            iconSize: 16
                            color: barDelegate.modelData.col
                        }
                    }
                }
            }
        }

        // ════════════════════════════════════════════
        // Row 0-1, Col 5: Media mini-player
        // ════════════════════════════════════════════
        Rectangle {
            Layout.row: 0; Layout.column: 5; Layout.rowSpan: 2
            Layout.preferredWidth: 110
            Layout.fillHeight: true
            radius: Appearance.rounding.small
            color: root.cardBg; border.width: 1; border.color: root.cardBorder

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                Item { Layout.fillHeight: true }

                // Album art
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 80; height: 80
                    radius: Appearance.rounding.small
                    color: ColorUtils.transparentize(Appearance.colors.colSurfaceContainer, 0.5)
                    clip: true

                    Image {
                        id: albumArt
                        anchors.fill: parent
                        source: MprisController.activePlayer?.trackArtUrl ?? ""
                        fillMode: Image.PreserveAspectCrop
                        visible: status === Image.Ready
                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        visible: albumArt.status !== Image.Ready
                        text: "album"
                        iconSize: 36
                        color: Appearance.colors.colSubtext
                    }
                }

                // Track title
                StyledText {
                    Layout.fillWidth: true
                    text: MprisController.activePlayer?.trackTitle ?? "No media"
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnLayer0
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                }

                // Artist
                StyledText {
                    Layout.fillWidth: true
                    text: MprisController.activePlayer?.trackArtist ?? ""
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                    visible: text !== ""
                }

                // Controls
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4

                    RippleButton {
                        implicitWidth: 26; implicitHeight: 26; buttonRadius: 13
                        colBackground: "transparent"
                        colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.85)
                        onClicked: MprisController.activePlayer?.previous()
                        contentItem: MaterialSymbol { anchors.centerIn: parent; text: "skip_previous"; iconSize: 16; color: Appearance.colors.colOnLayer0 }
                    }
                    RippleButton {
                        implicitWidth: 30; implicitHeight: 30; buttonRadius: 15
                        colBackground: "transparent"
                        colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.85)
                        onClicked: MprisController.activePlayer?.togglePlaying()
                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            text: MprisController.activePlayer?.isPlaying ? "pause" : "play_arrow"
                            iconSize: 20
                            color: Appearance.colors.colOnLayer0
                        }
                    }
                    RippleButton {
                        implicitWidth: 26; implicitHeight: 26; buttonRadius: 13
                        colBackground: "transparent"
                        colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.85)
                        onClicked: MprisController.activePlayer?.next()
                        contentItem: MaterialSymbol { anchors.centerIn: parent; text: "skip_next"; iconSize: 16; color: Appearance.colors.colOnLayer0 }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }
    }

    // Calendar day generation
    function calendarDays() {
        const year = root.focusedYear
        const month = root.focusedMonth
        const firstDay = new Date(year, month, 1).getDay()
        const daysInMonth = new Date(year, month + 1, 0).getDate()
        const daysInPrevMonth = new Date(year, month, 0).getDate()

        const now = new Date()
        const todayDay = now.getDate()
        const todayMonth = now.getMonth()
        const todayYear = now.getFullYear()

        const days = []

        // Previous month days
        for (let i = firstDay - 1; i >= 0; i--) {
            days.push({ day: daysInPrevMonth - i, isCurrentMonth: false, isToday: false })
        }

        // Current month days
        for (let d = 1; d <= daysInMonth; d++) {
            days.push({
                day: d,
                isCurrentMonth: true,
                isToday: d === todayDay && month === todayMonth && year === todayYear
            })
        }

        // Next month days to fill 6 rows
        const remaining = 42 - days.length
        for (let d = 1; d <= remaining; d++) {
            days.push({ day: d, isCurrentMonth: false, isToday: false })
        }

        return days
    }
}
