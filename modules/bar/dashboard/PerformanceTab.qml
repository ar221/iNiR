import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

Item {
    id: root
    implicitWidth: mainLayout.implicitWidth
    implicitHeight: mainLayout.implicitHeight

    Component.onCompleted: ResourceUsage.ensureRunning()

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // Top row: CPU + GPU hero cards
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 3
            spacing: 10

            HeroCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                title: "CPU"
                icon: "memory"
                value: ResourceUsage.cpuUsage
                accentColor: Appearance.colors.colPrimary
                detail: ResourceUsage.cpuTemp > 0 ? (ResourceUsage.cpuTemp + "\u00B0C") : ""
                history: ResourceUsage.cpuUsageHistory
            }

            HeroCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                title: "GPU"
                icon: "developer_board"
                value: ResourceUsage.gpuUsage
                accentColor: Appearance.colors.colTertiary
                detail: ResourceUsage.gpuTemp > 0 ? (ResourceUsage.gpuTemp + "\u00B0C") : ""
                history: ResourceUsage.gpuUsageHistory
            }
        }

        // Bottom row: Memory gauge + Storage gauge + Temp card
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 2
            spacing: 10

            GaugeCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                title: "Memory"
                icon: "memory_alt"
                value: ResourceUsage.memoryUsedPercentage
                accentColor: Appearance.colors.colSecondary
                detail: ResourceUsage.kbToGbString(ResourceUsage.memoryUsed) + " / " + ResourceUsage.kbToGbString(ResourceUsage.memoryTotal)
            }

            GaugeCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                title: "Storage"
                icon: "hard_drive"
                value: ResourceUsage.diskUsedPercentage
                accentColor: Appearance.colors.colPrimary
                detail: {
                    const usedGb = (ResourceUsage.diskUsed / (1024 * 1024)).toFixed(0)
                    const totalGb = (ResourceUsage.diskTotal / (1024 * 1024)).toFixed(0)
                    return usedGb + " / " + totalGb + " GB"
                }
            }

            // Network sparkline card
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Appearance.rounding.small
                color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.4)
                border.width: 1
                border.color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.92)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        MaterialSymbol { text: "network_check"; iconSize: 18; color: Appearance.colors.colPrimary }
                        StyledText { text: "Network"; font.pixelSize: Appearance.font.pixelSize.small; font.weight: Font.DemiBold; color: Appearance.colors.colOnLayer0 }
                    }

                    NetworkSparkline {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                }
            }

            TempCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }

    // ── HeroCard (CPU, GPU) ──────────────────────────────────────────────

    component HeroCard: Rectangle {
        id: heroRoot
        property string title: ""
        property string icon: ""
        property real value: 0
        property color accentColor: Appearance.colors.colPrimary
        property string detail: ""
        property list<real> history: []

        radius: Appearance.rounding.small
        color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.4)
        border.width: 1
        border.color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.92)
        clip: true

        // Usage history graph (behind everything)
        Graph {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: parent.height * 0.6
            values: heroRoot.history
            color: heroRoot.accentColor
            fillOpacity: 0.12
            alignment: Graph.Alignment.Right
        }

        // Animated fill bar rising from bottom
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: heroFillAnim.value * parent.height
            radius: heroRoot.radius
            color: Qt.alpha(heroRoot.accentColor, 0.15)

            // Subtle gradient overlay at the top edge of the fill
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 2
                color: Qt.alpha(heroRoot.accentColor, 0.3)
            }

            property real value: heroRoot.value
            Behavior on value {
                NumberAnimation { id: heroFillAnim; duration: 800; easing.type: Easing.OutCubic; property: "value" }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 4

            // Header row
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                MaterialSymbol {
                    text: heroRoot.icon
                    iconSize: 18
                    color: heroRoot.accentColor
                }
                StyledText {
                    text: heroRoot.title
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer0
                }
            }

            // Center: large percentage
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                StyledText {
                    anchors.centerIn: parent
                    text: Math.round(heroRoot.value * 100) + "%"
                    font.pixelSize: Appearance.font.pixelSize.larger * 1.6
                    font.weight: Font.Bold
                    font.family: Appearance.font.family.numbers
                    color: Appearance.colors.colOnLayer0
                }
            }

            // Detail line (temperature)
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                visible: heroRoot.detail !== ""
                text: heroRoot.detail
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colSubtext
            }
        }
    }

    // ── GaugeCard (Memory, Storage) ──────────────────────────────────────

    component GaugeCard: Rectangle {
        id: gaugeRoot
        property string title: ""
        property string icon: ""
        property real value: 0
        property color accentColor: Appearance.colors.colPrimary
        property string detail: ""

        radius: Appearance.rounding.small
        color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.4)
        border.width: 1
        border.color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.92)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 4

            // Arc gauge area
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 70

                Canvas {
                    id: arcCanvas
                    anchors.centerIn: parent
                    width: 110
                    height: 65

                    property real animValue: gaugeRoot.value
                    Behavior on animValue {
                        NumberAnimation { duration: 800; easing.type: Easing.OutCubic }
                    }

                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.reset()
                        const cx = width / 2
                        const cy = height - 5
                        const r = 45
                        const startAngle = Math.PI
                        const endAngle = 0

                        // Track
                        ctx.beginPath()
                        ctx.arc(cx, cy, r, startAngle, endAngle)
                        ctx.lineWidth = 10
                        ctx.strokeStyle = Qt.alpha(gaugeRoot.accentColor, 0.2).toString()
                        ctx.lineCap = "round"
                        ctx.stroke()

                        // Value arc
                        if (arcCanvas.animValue > 0.005) {
                            ctx.beginPath()
                            ctx.arc(cx, cy, r, startAngle, startAngle + arcCanvas.animValue * Math.PI)
                            ctx.lineWidth = 10
                            ctx.strokeStyle = gaugeRoot.accentColor.toString()
                            ctx.lineCap = "round"
                            ctx.stroke()
                        }
                    }

                    onAnimValueChanged: requestPaint()

                    // Percentage text inside the arc
                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 14
                        text: Math.round(gaugeRoot.value * 100) + "%"
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Bold
                        font.family: Appearance.font.family.numbers
                        color: Appearance.colors.colOnLayer0
                    }
                }
            }

            // Label
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: gaugeRoot.title
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer0
            }

            // Detail (used/total)
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                visible: gaugeRoot.detail !== ""
                text: gaugeRoot.detail
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colSubtext
            }
        }
    }

    // ── TempCard (compact temperature) ───────────────────────────────────

    component TempCard: Rectangle {
        id: tempRoot

        readonly property color tempColor: {
            const maxT = Math.max(ResourceUsage.cpuTemp, ResourceUsage.gpuTemp)
            if (maxT > 80) return Appearance.colors.colError
            if (maxT > 65) return Appearance.colors.colTertiary
            return Appearance.colors.colPrimary
        }

        radius: Appearance.rounding.small
        color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.4)
        border.width: 1
        border.color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.92)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 6

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                MaterialSymbol {
                    text: "thermostat"
                    iconSize: 18
                    color: tempRoot.tempColor
                }
                StyledText {
                    text: "Temp"
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer0
                }
            }

            // Center content
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    // CPU temp (main)
                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 2

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: ResourceUsage.cpuTemp > 0 ? (ResourceUsage.cpuTemp + "\u00B0") : "--"
                            font.pixelSize: Appearance.font.pixelSize.larger * 1.3
                            font.weight: Font.Bold
                            font.family: Appearance.font.family.numbers
                            color: tempRoot.tempColor
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: "CPU"
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            color: Appearance.colors.colSubtext
                        }
                    }

                    // Divider
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 30
                        Layout.preferredHeight: 1
                        color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.85)
                        visible: ResourceUsage.gpuTemp > 0
                    }

                    // GPU temp (secondary)
                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 2
                        visible: ResourceUsage.gpuTemp > 0

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: ResourceUsage.gpuTemp + "\u00B0"
                            font.pixelSize: Appearance.font.pixelSize.large
                            font.weight: Font.DemiBold
                            font.family: Appearance.font.family.numbers
                            color: Appearance.colors.colSubtext
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: "GPU"
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
            }
        }
    }
}
