pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

// One Courier Console dispatch-board cell: a monospace uppercase header,
// a content slot, and a 1px divider on the trailing edge.
Item {
    id: root

    // Monospace header text, rendered uppercase
    property string label: ""
    // Draw the trailing-edge divider — false for the last visible cell
    property bool showDivider: true

    // Content slot — children land in the content container below the header
    default property alias content: contentContainer.data

    implicitHeight: cellColumn.implicitHeight + cellColumn.anchors.margins * 2

    ColumnLayout {
        id: cellColumn
        anchors.fill: parent
        anchors.margins: 12
        anchors.rightMargin: root.showDivider ? 13 : 12
        spacing: 6

        // ── Section header ──
        StyledText {
            Layout.fillWidth: true
            text: root.label.toUpperCase()
            font.family: Appearance.font.family.monospace
            font.pixelSize: Appearance.font.pixelSize.smallest
            font.weight: Font.DemiBold
            color: Appearance.colors.colSubtext
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        // ── Content slot ──
        Item {
            id: contentContainer
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitHeight: childrenRect.height
        }
    }

    // ── Trailing-edge divider ──
    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: 8
        anchors.bottomMargin: 8
        width: 1
        visible: root.showDivider
        color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.88)
    }
}
