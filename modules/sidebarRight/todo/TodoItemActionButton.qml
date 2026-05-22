import qs.modules.common
import qs.modules.common.widgets
import QtQuick

RippleButton {
    id: button
    property string buttonText: ""
    property string tooltipText: ""

    implicitHeight: 30
    implicitWidth: implicitHeight

    Behavior on implicitWidth {
        SmoothedAnimation {
            velocity: Appearance.animation.elementMove.velocity
        }
    }

    buttonRadius: Appearance.sidebar.radiusSmall
    colBackground: "transparent"
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
