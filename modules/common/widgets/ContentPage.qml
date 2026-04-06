import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

StyledFlickable {
    id: root
    property real bottomContentPadding: 100
    // Metadatos opcionales para páginas de Settings
    property int settingsPageIndex: -1
    property string settingsPageName: ""
    property string settingsPageIcon: ""

    default property alias data: contentColumn.data

    clip: true
    contentHeight: outerColumn.implicitHeight + root.bottomContentPadding
    implicitWidth: outerColumn.implicitWidth

    // Responsive horizontal margins: more breathing room on wider containers
    readonly property real _horizontalMargin: {
        const w = root.width
        if (w > 1200) return 48
        if (w > 900) return 32
        if (w > 600) return 24
        return 16
    }

    ColumnLayout {
        id: outerColumn
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: 20
            bottomMargin: 20
            leftMargin: root._horizontalMargin
            rightMargin: root._horizontalMargin
        }
        spacing: 0

        // Page header — icon + title
        RowLayout {
            visible: root.settingsPageName.length > 0
            Layout.fillWidth: true
            Layout.bottomMargin: SettingsMaterialPreset.pageSpacing + 4
            spacing: 12

            MaterialSymbol {
                visible: root.settingsPageIcon.length > 0
                text: root.settingsPageIcon
                iconSize: Appearance.font.pixelSize.title * 1.3
                color: Appearance.m3colors.m3primary
                Layout.alignment: Qt.AlignVCenter
            }

            StyledText {
                text: root.settingsPageName
                font {
                    family: Appearance.font.family.title
                    pixelSize: Appearance.font.pixelSize.title
                    weight: Font.Medium
                    variableAxes: Appearance.font.variableAxes.title
                }
                color: Appearance.colors.colOnLayer0
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
            }
        }

        ColumnLayout {
            id: contentColumn
            Layout.fillWidth: true
            spacing: SettingsMaterialPreset.pageSpacing
        }
    }
}
