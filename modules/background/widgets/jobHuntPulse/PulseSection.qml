pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

// One section of the Job Hunt Pulse widget.
// Provides a Courier Console section header (colored 3px leading bar +
// uppercase label + count chip + meta string) and a default-property slot
// for row content below.
Item {
    id: root

    property string label: ""
    property int    count: 0
    property string meta: ""
    property color  accent: Appearance.colors.colPrimary

    // Whether the count chip should render. (Hide for sections where the count
    // doesn't carry meaning, e.g. NEXT.)
    property bool showCount: true

    // Default-property slot — rows go below the header
    default property alias content: contentContainer.data

    implicitWidth: sectionColumn.implicitWidth
    implicitHeight: sectionColumn.implicitHeight

    ColumnLayout {
        id: sectionColumn
        anchors.fill: parent
        spacing: 8

        // — Header row —
        Item {
            Layout.fillWidth: true
            implicitHeight: headerRow.implicitHeight

            // 3px colored leading bar
            Rectangle {
                id: leadingBar
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 3
                height: parent.implicitHeight - 2
                radius: 2
                color: root.accent
            }

            RowLayout {
                id: headerRow
                anchors.left: leadingBar.right
                anchors.leftMargin: 7
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                StyledText {
                    text: root.label.toUpperCase()
                    font.family: Appearance.font.family.monospace
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: Font.Bold
                    font.letterSpacing: 1.5
                    color: Appearance.colors.colOnLayer0
                }

                StyledText {
                    visible: root.showCount
                    text: root.count.toString()
                    font.family: Appearance.font.family.monospace
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: Font.Bold
                    color: root.accent
                }

                Item { Layout.fillWidth: true }

                StyledText {
                    text: root.meta
                    font.family: Appearance.font.family.monospace
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    font.letterSpacing: 1.2
                    color: Appearance.colors.colSubtext
                }
            }
        }

        // — Content slot —
        Item {
            id: contentContainer
            Layout.fillWidth: true
            implicitHeight: childrenRect.height
        }
    }
}
