import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    property string label: ""
    property bool isFolder: false
    property real fontScale: 1.0
    // accentIndex: when >= 0, cycles through the accent palette (used in BookmarksView).
    // When -1 (default), uses colPrimary for folders and colSurfaceContainerHighest for files.
    property int accentIndex: -1

    signal activated()

    // Accent palette — mono-amber Courier/Apollo collapse: all bookmarks use mission accent.
    // accentIndex >= 0 path (BookmarksView) → colAccent bg + colText fg for all entries.
    // accentIndex -1 (FolderView) → colAccent for folders, colSurfaceRaised for files.
    readonly property color _pillBg: {
        if (root.accentIndex >= 0) {
            return Appearance.mission.colAccent;
        }
        return root.isFolder
            ? Appearance.mission.colAccent
            : Appearance.mission.colSurfaceRaised;
    }
    readonly property color _pillFg: {
        if (root.accentIndex >= 0) {
            return Appearance.mission.colText;
        }
        return root.isFolder
            ? Appearance.mission.colText
            : Appearance.mission.colTextSecondary;
    }

    implicitHeight: rowLayout.implicitHeight + 8
    implicitWidth: rowLayout.implicitWidth

    HoverHandler {
        id: hoverHandler
    }

    Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.unsharpen
        color: hoverHandler.hovered
            ? Appearance.mission.colSurfaceHover
            : "transparent"
    }

    RowLayout {
        id: rowLayout
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: 8
            rightMargin: 8
        }
        spacing: 8

        // Icon pill
        Item {
            Layout.alignment: Qt.AlignVCenter
            width: 24
            height: 24

            // Pop-scale on hover — only the pill, not the whole row
            transform: Scale {
                id: pillScale
                origin.x: 12
                origin.y: 12
                xScale: hoverHandler.hovered ? 1.15 : 1.0
                yScale: hoverHandler.hovered ? 1.15 : 1.0
                Behavior on xScale {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutBack
                    }
                }
                Behavior on yScale {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutBack
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: Appearance.rounding.unsharpen
                color: root._pillBg
            }

            MaterialSymbol {
                anchors.centerIn: parent
                text: root.isFolder
                    ? (hoverHandler.hovered ? "folder_open" : "folder")
                    : "draft"
                iconSize: 14 * root.fontScale
                color: root._pillFg
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: root.label
            font.pixelSize: Appearance.font.pixelSize.small * root.fontScale
            color: root.isFolder
                ? Appearance.mission.colText
                : Appearance.mission.colTextSecondary
            elide: Text.ElideRight
        }

        MaterialSymbol {
            Layout.alignment: Qt.AlignVCenter
            visible: root.isFolder
            text: "chevron_right"
            iconSize: Appearance.font.pixelSize.small * root.fontScale
            color: Appearance.mission.colTextMuted
            opacity: hoverHandler.hovered ? 0.8 : 0.3
            Behavior on opacity {
                NumberAnimation { duration: Appearance.animation.elementMoveFast.duration }
            }
        }
    }

    TapHandler {
        onTapped: root.activated()
    }
}
