import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects as GE
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

RowLayout {
    id: root

    property var configEntry: ({})

    spacing: 14

    // Avatar
    Rectangle {
        id: avatarContainer
        Layout.preferredWidth: 52
        Layout.preferredHeight: 52
        radius: 26
        color: Appearance.colors.colPrimaryContainer
        clip: true

        Image {
            id: avatarImage
            anchors.fill: parent
            source: root.configEntry.avatarPath ?? ""
            fillMode: Image.PreserveAspectCrop
            visible: false
            asynchronous: true
        }

        GE.OpacityMask {
            anchors.fill: parent
            source: avatarImage
            maskSource: Rectangle {
                width: avatarContainer.width
                height: avatarContainer.height
                radius: avatarContainer.radius
            }
            visible: avatarImage.status === Image.Ready
        }

        MaterialSymbol {
            anchors.centerIn: parent
            text: "person"
            iconSize: 28
            color: Appearance.colors.colOnPrimaryContainer
            visible: avatarImage.status !== Image.Ready
        }
    }

    // Greeting + uptime
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        StyledText {
            property string greeting: {
                const h = new Date().getHours()
                if (h < 6) return "Good night"
                if (h < 12) return "Good morning"
                if (h < 18) return "Good afternoon"
                return "Good evening"
            }
            text: greeting + ", " + (root.configEntry.greetingName ?? "User")
            font.pixelSize: Appearance.font.pixelSize.larger
            font.family: Appearance.font.family.title
            font.weight: Font.DemiBold
            color: Appearance.colors.colOnLayer0
        }

        RowLayout {
            spacing: 6
            MaterialSymbol {
                text: "schedule"
                iconSize: 14
                color: Appearance.colors.colSubtext
            }
            StyledText {
                text: "Uptime: " + DateTime.uptime
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colSubtext
            }
        }
    }
}
