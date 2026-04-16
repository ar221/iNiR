pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.dashboard
import qs.services

DashboardCard {
    id: root
    headerText: "Notifications"

    // ── Scrollable notification list ──
    ListView {
        id: notifListView
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 100
        clip: true
        spacing: 6
        model: Notifications.list

        delegate: Rectangle {
            id: notifDelegate
            required property var modelData
            required property int index
            width: notifListView.width
            implicitHeight: notifRow.implicitHeight + 16
            radius: 8
            color: Qt.rgba(1, 1, 1, 0.015)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.03)

            RowLayout {
                id: notifRow
                anchors.fill: parent
                anchors.margins: 8
                spacing: 10

                // App icon
                Rectangle {
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: 6
                    color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.88)
                    Layout.alignment: Qt.AlignTop

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: {
                            // Map common app names to icons
                            const appName = (notifDelegate.modelData.appName ?? "").toLowerCase()
                            if (appName.includes("discord")) return "forum"
                            if (appName.includes("firefox")) return "language"
                            if (appName.includes("telegram")) return "send"
                            if (appName.includes("spotify")) return "music_note"
                            return "notifications"
                        }
                        iconSize: 16
                        color: Appearance.colors.colPrimary
                    }
                }

                // Notification text
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        StyledText {
                            Layout.fillWidth: true
                            text: notifDelegate.modelData.summary ?? notifDelegate.modelData.appName ?? "Notification"
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnLayer0
                            elide: Text.ElideRight
                        }

                        // Relative timestamp
                        StyledText {
                            text: {
                                const now = Date.now()
                                const elapsed = now - (notifDelegate.modelData.time ?? now)
                                const seconds = Math.floor(elapsed / 1000)
                                if (seconds < 60) return "now"
                                const minutes = Math.floor(seconds / 60)
                                if (minutes < 60) return minutes + "m"
                                const hours = Math.floor(minutes / 60)
                                if (hours < 24) return hours + "h"
                                return Math.floor(hours / 24) + "d"
                            }
                            font.pixelSize: 10
                            color: Qt.rgba(1, 1, 1, 0.2)
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: notifDelegate.modelData.body ?? ""
                        font.pixelSize: 10
                        color: Qt.rgba(1, 1, 1, 0.35)
                        elide: Text.ElideRight
                        maximumLineCount: 2
                        wrapMode: Text.WordWrap
                        visible: text !== ""
                    }
                }
            }
        }

        // Empty state
        Item {
            anchors.fill: parent
            visible: Notifications.list.length === 0

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8

                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    text: "notifications_none"
                    iconSize: 32
                    color: Qt.rgba(1, 1, 1, 0.15)
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "All caught up"
                    font.pixelSize: 11
                    color: Qt.rgba(1, 1, 1, 0.2)
                }
            }
        }
    }
}
