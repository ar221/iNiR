import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks

StyledToolTip {
    id: root

    property Component realContentComponent: Component {
        WText {
            text: root.text
            font: root.font
            anchors.centerIn: parent
        }
    }
    font {
        family: Looks.font.family.ui
        pixelSize: Looks.font.pixelSize.normal
        weight: Looks.font.weight.regular
    }
    verticalPadding: 8
    horizontalPadding: 10

    delay: 400

    contentComponent: Component {
        WToolTipContent {
            realContentComponent: root.realContentComponent
            horizontalPadding: root.horizontalPadding
            verticalPadding: root.verticalPadding
        }
    }
}
