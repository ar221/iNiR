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

    // Dedup at view layer: keep only the most recent entry per (appName, summary) pair.
    // Notifications.list is already sorted newest-first by insertion order; iterate
    // and skip any entry whose (appName, summary) key has already been seen.
    readonly property var dedupedList: {
        const seen = {}
        const out = []
        for (let i = 0; i < Notifications.list.length; ++i) {
            const n = Notifications.list[i]
            const key = (n.appName ?? "") + "\x00" + (n.summary ?? "")
            if (!seen[key]) {
                seen[key] = true
                out.push(n)
            }
        }
        return out
    }

    function primaryActionFor(notification) {
        const actions = notification?.actions ?? []
        if (!actions || actions.length === 0) return null
        const preferred = actions.find(a => {
            const t = String(a?.text ?? "").toLowerCase()
            return t.includes("open") || t.includes("view") || t.includes("show") || t.includes("reply")
        })
        return preferred ?? actions[0]
    }

    function triggerPrimary(notification) {
        if (!notification) return
        const action = primaryActionFor(notification)
        if (action && action.identifier) {
            Notifications.attemptInvokeAction(notification.notificationId, action.identifier)
            return
        }
        Notifications.focusOrLaunchApp(notification.appIcon, notification.appName)
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Item { Layout.fillWidth: true }

        Rectangle {
            Layout.preferredHeight: 24
            Layout.preferredWidth: 70
            radius: 6
            color: Qt.rgba(1, 1, 1, 0.05)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.10)

            StyledText {
                anchors.centerIn: parent
                text: "Mark read"
                font.pixelSize: 10
                color: Qt.rgba(1, 1, 1, 0.75)
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Notifications.markAllRead()
            }
        }

        Rectangle {
            Layout.preferredHeight: 24
            Layout.preferredWidth: 62
            radius: 6
            color: Qt.rgba(Appearance.colors.colError.r, Appearance.colors.colError.g, Appearance.colors.colError.b, 0.12)
            border.width: 1
            border.color: Qt.rgba(Appearance.colors.colError.r, Appearance.colors.colError.g, Appearance.colors.colError.b, 0.28)

            StyledText {
                anchors.centerIn: parent
                text: "Clear all"
                font.pixelSize: 10
                color: Qt.rgba(1, 1, 1, 0.82)
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Notifications.discardAllNotifications()
            }
        }
    }

    // ── Scrollable notification list ──
    ListView {
        id: notifListView
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 100
        clip: true
        spacing: 8
        model: root.dedupedList

        delegate: Rectangle {
            id: notifDelegate
            required property var modelData
            required property int index

            property bool hovered: false
            property bool pendingDismiss: false
            readonly property real swipeThreshold: width * 0.28
            readonly property var primaryAction: root.primaryActionFor(modelData)

            width: notifListView.width
            implicitHeight: notifRow.implicitHeight + 20
            radius: 10
            color: Qt.rgba(1, 1, 1, hovered ? 0.045 : 0.02)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, hovered ? 0.12 : 0.06)
            opacity: 1.0 - Math.min(0.45, Math.abs(x) / Math.max(width, 1) * 0.6)

            onModelDataChanged: {
                x = 0
                pendingDismiss = false
            }

            Behavior on color { ColorAnimation { duration: 90 } }
            Behavior on border.color { ColorAnimation { duration: 90 } }
            Behavior on x {
                enabled: !swipeHandler.active
                NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
            }

            Timer {
                id: dismissTimer
                interval: 120
                repeat: false
                onTriggered: Notifications.discardNotification(notifDelegate.modelData.notificationId)
            }

            DragHandler {
                id: swipeHandler
                target: notifDelegate
                xAxis.enabled: true
                yAxis.enabled: false

                onActiveChanged: {
                    if (!active && !notifDelegate.pendingDismiss) {
                        if (Math.abs(notifDelegate.x) >= notifDelegate.swipeThreshold) {
                            notifDelegate.pendingDismiss = true
                            notifDelegate.x = notifDelegate.x > 0 ? notifDelegate.width : -notifDelegate.width
                            dismissTimer.start()
                        } else {
                            notifDelegate.x = 0
                        }
                    }
                }
            }

            HoverHandler {
                onHoveredChanged: notifDelegate.hovered = hovered
                cursorShape: Qt.PointingHandCursor
            }

            RowLayout {
                id: notifRow
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Rectangle {
                    implicitWidth: 34
                    implicitHeight: 34
                    radius: 7
                    color: Qt.rgba(1, 1, 1, 0.08)
                    Layout.alignment: Qt.AlignTop

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: {
                            const appName = (notifDelegate.modelData.appName ?? "").toLowerCase()
                            if (appName.includes("discord")) return "forum"
                            if (appName.includes("firefox")) return "language"
                            if (appName.includes("telegram")) return "send"
                            if (appName.includes("spotify")) return "music_note"
                            return "notifications"
                        }
                        iconSize: 18
                        color: Qt.rgba(1, 1, 1, 0.52)
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        StyledText {
                            Layout.fillWidth: true
                            text: notifDelegate.modelData.summary ?? notifDelegate.modelData.appName ?? "Notification"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnLayer0
                            elide: Text.ElideRight
                        }

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
                            font.pixelSize: 11
                            color: Qt.rgba(1, 1, 1, 0.36)
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: notifDelegate.modelData.body ?? ""
                        font.pixelSize: 11
                        color: Qt.rgba(1, 1, 1, 0.56)
                        elide: Text.ElideRight
                        maximumLineCount: 3
                        wrapMode: Text.WordWrap
                        visible: text !== ""
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Rectangle {
                            visible: notifDelegate.primaryAction !== null
                            Layout.preferredHeight: 22
                            Layout.preferredWidth: 72
                            radius: 6
                            color: Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b, 0.18)
                            border.width: 1
                            border.color: Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b, 0.36)

                            StyledText {
                                anchors.centerIn: parent
                                text: notifDelegate.primaryAction?.text ?? "Open"
                                font.pixelSize: 10
                                color: Qt.rgba(1, 1, 1, 0.9)
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (notifDelegate.primaryAction?.identifier)
                                        Notifications.attemptInvokeAction(notifDelegate.modelData.notificationId, notifDelegate.primaryAction.identifier)
                                }
                            }
                        }

                        Rectangle {
                            Layout.preferredHeight: 22
                            Layout.preferredWidth: 58
                            radius: 6
                            color: Qt.rgba(1, 1, 1, 0.07)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.14)

                            StyledText {
                                anchors.centerIn: parent
                                text: "Open"
                                font.pixelSize: 10
                                color: Qt.rgba(1, 1, 1, 0.82)
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Notifications.focusOrLaunchApp(notifDelegate.modelData.appIcon, notifDelegate.modelData.appName)
                            }
                        }

                        Rectangle {
                            Layout.preferredHeight: 22
                            Layout.preferredWidth: 64
                            radius: 6
                            color: Qt.rgba(Appearance.colors.colError.r, Appearance.colors.colError.g, Appearance.colors.colError.b, 0.14)
                            border.width: 1
                            border.color: Qt.rgba(Appearance.colors.colError.r, Appearance.colors.colError.g, Appearance.colors.colError.b, 0.30)

                            StyledText {
                                anchors.centerIn: parent
                                text: "Dismiss"
                                font.pixelSize: 10
                                color: Qt.rgba(1, 1, 1, 0.88)
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Notifications.discardNotification(notifDelegate.modelData.notificationId)
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }
                }
            }
        }

        // Empty state
        Item {
            anchors.fill: parent
            visible: root.dedupedList.length === 0

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
