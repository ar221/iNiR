import qs.modules.common
import qs.modules.common.widgets
import qs.services
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    clip: true

    Component.onCompleted: Notifications.ensureInitialized()

    NotificationListView { // Scrollable window
        id: listview
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: statusRow.top
        anchors.bottomMargin: 5

        clip: true
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: listview.width
                height: listview.height
                radius: 0
            }
        }

        popup: false
    }

    // Placeholder when list is empty
    PagePlaceholder {
        shown: Notifications.list.length === 0
        icon: "notifications_active"
        description: Translation.tr("Nothing")
        shape: MaterialShape.Shape.Ghostish
        descriptionHorizontalAlignment: Text.AlignHCenter
    }

    Item {
        id: statusRow
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: statusRowLayout.implicitHeight + 12

        // Top separator line
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            height: 1
            color: Appearance.inirEverywhere ? Appearance.inir.colBorder
                : Appearance.angelEverywhere ? Appearance.angel.colBorder
                : ColorUtils.transparentize(Appearance.colors.colOutline, 0.8)
        }

        RowLayout {
            id: statusRowLayout
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            anchors.topMargin: 8
            anchors.bottomMargin: 4
            spacing: 8

            NotificationStatusButton {
                Layout.fillWidth: false
                buttonIcon: Notifications.silent ? "notifications_off" : "notifications_paused"
                toggled: Notifications.silent
                onClicked: () => {
                    Notifications.silent = !Notifications.silent;
                }
            }

            Item { Layout.fillWidth: true }

            // Notification count badge
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: countRow.implicitWidth + 16
                implicitHeight: 26
                radius: 13
                color: Notifications.list.length > 0
                    ? ColorUtils.transparentize(Appearance.m3colors.m3primary, 0.85)
                    : "transparent"

                RowLayout {
                    id: countRow
                    anchors.centerIn: parent
                    spacing: 4
                    MaterialSymbol {
                        text: "notifications"
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colSubtext
                    }
                    StyledText {
                        text: Notifications.list.length
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer2
                    }
                }
            }

            Item { Layout.fillWidth: true }

            NotificationStatusButton {
                Layout.fillWidth: false
                buttonIcon: "delete_sweep"
                onClicked: () => {
                    Notifications.discardAllNotifications()
                }
            }
        }
    }
}