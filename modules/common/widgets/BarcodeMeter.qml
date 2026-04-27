import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    required property real value
    property string label: ""
    property color color: Appearance.mission.colActive
    property string variant: "block"
    property bool showLabel: true
    property bool showValue: true
    property int inlineTrackWidth: 48

    readonly property real _val: Math.min(1, Math.max(0, value))

    property real cautionThreshold: 0
    property real warningThreshold: 100
    readonly property bool _caution: cautionThreshold > 0
        && (_val * 100) >= cautionThreshold && !_warning
    readonly property bool _warning: (_val * 100) >= warningThreshold
    readonly property color _fillColor: _warning ? Appearance.mission.colCritical
        : _caution ? Appearance.colors.colError : root.color

    readonly property bool _isBlock: variant === "block"
    readonly property int _barWidth: _isBlock ? 2 : 2
    readonly property int _barSpacing: _isBlock ? 2 : 1
    readonly property int _pitch: _barWidth + _barSpacing
    readonly property int _trackHeight: _isBlock ? 16 : 10
    readonly property int _trackRadius: 2

    implicitHeight: _isBlock ? _blockLayout.implicitHeight : _inlineLayout.implicitHeight
    implicitWidth: _isBlock ? 200 : _inlineLayout.implicitWidth

    ColumnLayout {
        id: _blockLayout
        anchors.fill: parent
        visible: root._isBlock
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            visible: root.showLabel || root.showValue
            spacing: 4

            StyledText {
                visible: root.showLabel
                text: root.label
                font.pixelSize: 10
                font.weight: Font.DemiBold
                font.letterSpacing: 1.0
                font.family: Appearance.font.family.monospace
                font.capitalization: Font.AllUppercase
                color: Appearance.mission.colTextMuted
            }

            Item { Layout.fillWidth: true }

            StyledText {
                visible: root.showValue
                text: Math.round(root._val * 100) + "%"
                font.pixelSize: 10
                font.weight: Font.Bold
                font.family: Appearance.font.family.numbers
                color: root._fillColor
            }
        }

        Rectangle {
            id: blockTrack
            Layout.fillWidth: true
            Layout.preferredHeight: root._trackHeight
            radius: root._trackRadius
            color: Appearance.mission.colPanel
            clip: true

            Item {
                id: blockFill
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: root._val * parent.width

                Behavior on width {
                    enabled: Appearance.animationsEnabled
                    NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
                }

                Repeater {
                    model: blockTrack.width > 0 ? Math.ceil(blockTrack.width / root._pitch) : 0

                    Rectangle {
                        required property int index
                        x: index * root._pitch
                        y: 0
                        width: root._barWidth
                        height: blockTrack.height
                        color: root._fillColor

                        Behavior on color {
                            enabled: Appearance.animationsEnabled
                            ColorAnimation { duration: 250 }
                        }
                    }
                }
            }
        }
    }

    RowLayout {
        id: _inlineLayout
        anchors.fill: parent
        visible: !root._isBlock
        spacing: 4

        StyledText {
            visible: root.showLabel
            text: root.label
            font.pixelSize: 8
            font.weight: Font.DemiBold
            font.letterSpacing: 0.5
            font.family: Appearance.font.family.monospace
            font.capitalization: Font.AllUppercase
            color: Appearance.mission.colTextMuted
            Layout.preferredWidth: implicitWidth
        }

        Rectangle {
            id: inlineTrack
            Layout.preferredWidth: root.inlineTrackWidth
            Layout.preferredHeight: root._trackHeight
            radius: root._trackRadius
            color: Qt.rgba(Appearance.mission.colText.r,
                           Appearance.mission.colText.g,
                           Appearance.mission.colText.b, 0.04)
            clip: true

            Item {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: root._val * parent.width

                Behavior on width {
                    enabled: Appearance.animationsEnabled
                    NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
                }

                Repeater {
                    model: inlineTrack.width > 0 ? Math.ceil(inlineTrack.width / root._pitch) : 0

                    Rectangle {
                        required property int index
                        x: index * root._pitch
                        y: 0
                        width: root._barWidth
                        height: inlineTrack.height
                        color: root._fillColor
                    }
                }
            }
        }

        StyledText {
            visible: root.showValue
            text: Math.round(root._val * 100)
            font.pixelSize: 9
            font.weight: Font.Bold
            font.family: Appearance.font.family.numbers
            color: root._fillColor
            Layout.preferredWidth: implicitWidth
        }
    }
}
