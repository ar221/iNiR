import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick

GroupButton {
    id: button
    property string buttonIcon
    baseWidth: 40
    baseHeight: 40
    clickedWidth: baseWidth + 20
    toggled: false
    buttonRadius: Appearance.sidebar.radiusButton
    buttonRadiusPressed: Appearance.sidebar.radiusButtonPressed
    colBackground: Appearance.sidebar.colSubCard
    colBackgroundHover: Appearance.sidebar.colSubCardHover
    colBackgroundToggled: Appearance.sidebar.colAccentSurface
    colBackgroundToggledHover: Appearance.sidebar.colAccentSurfaceHover

    contentItem: Item {
        // Item fills the button area, icon is centered inside
        MaterialSymbol {
            anchors.centerIn: parent
            iconSize: 22
            fill: button.toggled ? 1 : 0
            color: button.toggled ? Appearance.sidebar.colOnAccent : Appearance.sidebar.colText
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: button.buttonIcon

            Behavior on color {
                animation: ColorAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
            }
        }
    }
}
