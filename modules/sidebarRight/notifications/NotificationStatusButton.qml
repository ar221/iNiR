import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

GroupButton {
    id: button
    property string buttonIcon: ""
    property string buttonText: ""

    baseHeight: 36
    baseWidth: content.implicitWidth + 46
    clickedWidth: baseWidth + 6

    buttonRadius: Appearance.sidebar.radiusButton
    buttonRadiusPressed: Appearance.sidebar.radiusSmall
    colBackground: toggled ? Appearance.sidebar.colAccentSurface : Appearance.sidebar.colSubCard
    colBackgroundHover: toggled ? Appearance.sidebar.colAccentSurfaceHover : Appearance.sidebar.colSubCardHover
    colBackgroundActive: toggled ? Appearance.sidebar.colAccentSurfaceActive : Appearance.sidebar.colSubCardActive
    property color colText: toggled ? Appearance.sidebar.colOnAccent : Appearance.sidebar.colTextOnSubCard

    contentItem: Item {
        id: content
        anchors.fill: parent
        implicitWidth: contentRowLayout.implicitWidth
        implicitHeight: contentRowLayout.implicitHeight
        RowLayout {
            id: contentRowLayout
            anchors.centerIn: parent
            spacing: 5
            MaterialSymbol {
                visible: buttonIcon !== ""
                text: buttonIcon
                iconSize: Appearance.font.pixelSize.huge
                color: button.colText
            }
            StyledText {
                visible: buttonText !== ""
                text: buttonText
                font.pixelSize: Appearance.font.pixelSize.small
                color: button.colText
            }
        }
    }

}
