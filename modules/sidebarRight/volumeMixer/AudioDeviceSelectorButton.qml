import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

RippleButton {
    id: button
    required property bool input

    buttonRadius: Appearance.sidebar.radiusSmall
    colBackground: Appearance.sidebar.colSubCard
    colBackgroundHover: Appearance.sidebar.colSubCardHover
    colRipple: Appearance.sidebar.colSubCardActive

    implicitHeight: contentItem.implicitHeight + 6 * 2
    implicitWidth: contentItem.implicitWidth + 6 * 2

    contentItem: RowLayout {
        anchors.fill: parent
        anchors.margins: 5
        spacing: 5

        MaterialSymbol {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: false
            Layout.leftMargin: 5
            color: Appearance.sidebar.colTextOnSubCard
            iconSize: Appearance.font.pixelSize.hugeass
            text: input ? "mic_external_on" : "media_output"
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.rightMargin: 5
            spacing: 0
            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                font.pixelSize: Appearance.font.pixelSize.normal
                text: input ? Translation.tr("Input") : Translation.tr("Output")
                color: Appearance.sidebar.colTextOnSubCard
            }
            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                font.pixelSize: Appearance.font.pixelSize.smaller
                text: (input ? Audio.source?.description : Audio.defaultSink?.description) ?? Translation.tr("Unknown")
                color: Appearance.sidebar.colTextSecondary
                animateChange: true
            }
        }
    }
}
