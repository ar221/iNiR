import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

ColumnLayout {
    id: root

    property var configEntry: ({})
    property var events: []
    property bool gcalAvailable: false
    property bool loading: false

    spacing: 8

    // Section header
    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        MaterialSymbol {
            text: "event"
            iconSize: 16
            color: Appearance.colors.colSubtext
        }

        StyledText {
            Layout.fillWidth: true
            text: "Today's Events"
            font.pixelSize: Appearance.font.pixelSize.small
            font.weight: Font.DemiBold
            color: Appearance.colors.colOnLayer0
        }

        // Refresh button
        RippleButton {
            implicitWidth: 22; implicitHeight: 22
            buttonRadius: 11
            visible: root.gcalAvailable
            colBackground: "transparent"
            colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.85)
            onClicked: fetchEvents()
            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                text: "refresh"
                iconSize: 14
                color: Appearance.colors.colSubtext
            }
        }
    }

    // Check if gcalcli exists
    Process {
        id: gcalCheck
        command: ["/usr/bin/which", "gcalcli"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                root.gcalAvailable = data.trim().length > 0
                if (root.gcalAvailable) fetchEvents()
            }
        }
    }

    Component.onCompleted: gcalCheck.running = true

    // Fetch events
    Process {
        id: gcalFetch
        command: ["/usr/bin/bash", "-lc",
            "gcalcli agenda --nocolor --tsv $(date +%Y-%m-%dT00:00) $(date +%Y-%m-%dT23:59) 2>/dev/null"
        ]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                root.loading = false
                const lines = data.trim().split("\n")
                const parsed = []
                for (const line of lines) {
                    if (line.trim() === "") continue
                    const parts = line.split("\t")
                    if (parts.length >= 4) {
                        const startDate = parts[0]
                        const startTime = parts[1]
                        const endDate = parts[2]
                        const endTime = parts[3]
                        const title = parts.slice(4).join(" ").trim()
                        if (title) {
                            parsed.push({
                                time: startTime || "All day",
                                endTime: endTime || "",
                                title: title
                            })
                        }
                    }
                }
                root.events = parsed
            }
        }
    }

    function fetchEvents() {
        root.loading = true
        gcalFetch.running = true
    }

    // Refresh every 5 minutes
    Timer {
        running: root.visible && root.gcalAvailable
        interval: 300000
        repeat: true
        onTriggered: fetchEvents()
    }

    // Events list or placeholder
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        // Not configured message
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: noGcalCol.implicitHeight + 16
            visible: !root.gcalAvailable && !root.loading
            radius: Appearance.rounding.small
            color: ColorUtils.transparentize(Appearance.colors.colSurfaceContainer, 0.4)

            ColumnLayout {
                id: noGcalCol
                anchors.centerIn: parent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 12
                spacing: 4

                StyledText {
                    Layout.fillWidth: true
                    text: "Google Calendar not connected"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                    horizontalAlignment: Text.AlignHCenter
                }

                StyledText {
                    Layout.fillWidth: true
                    text: "Install gcalcli to see events"
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: ColorUtils.transparentize(Appearance.colors.colSubtext, 0.4)
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // Loading indicator
        StyledText {
            visible: root.loading
            text: "Loading events..."
            font.pixelSize: Appearance.font.pixelSize.smallest
            color: Appearance.colors.colSubtext
        }

        // No events today
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            visible: root.gcalAvailable && !root.loading && root.events.length === 0
            radius: Appearance.rounding.small
            color: ColorUtils.transparentize(Appearance.colors.colSurfaceContainer, 0.4)

            StyledText {
                anchors.centerIn: parent
                text: "No events today"
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colSubtext
            }
        }

        // Event items
        Repeater {
            model: root.events

            Rectangle {
                id: eventItem
                required property var modelData
                required property int index
                Layout.fillWidth: true
                Layout.preferredHeight: eventRow.implicitHeight + 10
                radius: Appearance.rounding.small
                color: ColorUtils.transparentize(Appearance.colors.colSurfaceContainer, 0.4)

                RowLayout {
                    id: eventRow
                    anchors.fill: parent
                    anchors.margins: 5
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8

                    // Time accent bar
                    Rectangle {
                        Layout.preferredWidth: 3
                        Layout.fillHeight: true
                        radius: 1.5
                        color: index === 0 ? Appearance.colors.colPrimary
                             : index === 1 ? Appearance.colors.colSecondary
                             : Appearance.colors.colTertiary
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        StyledText {
                            Layout.fillWidth: true
                            text: eventItem.modelData.title
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer0
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        StyledText {
                            text: {
                                const t = eventItem.modelData.time
                                if (eventItem.modelData.endTime)
                                    return t + " - " + eventItem.modelData.endTime
                                return t
                            }
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
            }
        }
    }
}
