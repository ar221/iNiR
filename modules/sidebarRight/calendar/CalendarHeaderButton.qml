import qs.modules.common
import qs.modules.common.widgets
import QtQuick

RippleButton {
    id: button
    property string buttonText: ""
    property string tooltipText: ""
    property bool forceCircle: false

    implicitHeight: 30
    implicitWidth: forceCircle ? implicitHeight : (contentItem.implicitWidth + 10 * 2)
    Behavior on implicitWidth {
        SmoothedAnimation {
            velocity: Appearance.animation.elementMove.velocity
        }
    }

    background.anchors.fill: button
    buttonRadius: forceCircle ? Appearance.sidebar.radiusButton : Appearance.sidebar.radiusSmall
    colBackground: Appearance.sidebar.colSubCard
    colBackgroundHover: Appearance.sidebar.colSubCardHover
    colRipple: Appearance.sidebar.colSubCardActive

    contentItem: StyledText {
        text: buttonText
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: Appearance.font.pixelSize.larger
        color: Appearance.sidebar.colTextOnSubCard
    }

    StyledToolTip {
        text: tooltipText
        extraVisibleCondition: tooltipText.length > 0
    }
}
