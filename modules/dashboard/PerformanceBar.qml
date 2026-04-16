import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

// Single vertical bar component for performance visualization.
// value: 0-1 fill level. Color shifts from lowColor (idle) to highColor (critical).
Item {
    id: root

    property real value: 0
    property string label: ""
    property color lowColor: Appearance.colors.colPrimary
    property color highColor: Appearance.colors.colError

    // Tracks previous value for spike-pulse detection
    property real _previousValue: 0

    implicitWidth: 28
    implicitHeight: 160

    ColumnLayout {
        anchors.fill: parent
        spacing: 4

        // Value readout
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Math.round(root.value * 100) + "%"
            font.pixelSize: 14
            font.weight: Font.Bold
            font.family: Appearance.font.family.numbers
            // Dim at idle, fully visible at load — mix(onLayer0, dim, value) → value=1 → onLayer0
            color: ColorUtils.mix(Appearance.colors.colOnLayer0, Qt.rgba(1, 1, 1, 0.4), root.value)
        }

        // Bar container
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 120

            // Spike glow — flashes when value jumps > 0.15
            Rectangle {
                id: spikeGlow
                anchors {
                    left: barBg.left; leftMargin: -8
                    right: barBg.right; rightMargin: -8
                    top: barBg.top; topMargin: -8
                    bottom: barBg.bottom; bottomMargin: -8
                }
                radius: barBg.radius + 8
                // Same hue as the fill, 25% opacity when fully visible
                color: ColorUtils.mix(root.highColor, root.lowColor, root.value)
                opacity: 0

                SequentialAnimation {
                    id: pulseAnim
                    NumberAnimation {
                        target: spikeGlow
                        property: "opacity"
                        to: 0.25
                        duration: Appearance.animationsEnabled ? 100 : 0
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: spikeGlow
                        property: "opacity"
                        to: 0
                        duration: Appearance.animationsEnabled ? 400 : 0
                        easing.type: Easing.InCubic
                    }
                }
            }

            // Bar background
            Rectangle {
                id: barBg
                anchors.fill: parent
                color: Qt.rgba(1, 1, 1, 0.03)
                radius: 4

                // Fill bar, anchored to bottom
                Rectangle {
                    id: fillBar
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                    height: root.value * barBg.height
                    radius: barBg.radius
                    // value=0 → lowColor (cool), value=1 → highColor (hot)
                    color: ColorUtils.mix(root.highColor, root.lowColor, 1.0 - root.value)

                    Behavior on height {
                        enabled: Appearance.animationsEnabled
                        NumberAnimation {
                            duration: 250
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on color {
                        enabled: Appearance.animationsEnabled
                        ColorAnimation { duration: 250 }
                    }
                }
            }
        }

        // Label
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: root.label
            font.pixelSize: 9
            font.letterSpacing: 1.0
            font.family: Appearance.font.family.numbers
            color: Qt.rgba(1, 1, 1, 0.4)
        }
    }

    // Spike pulse detection
    onValueChanged: {
        if (Math.abs(root.value - root._previousValue) > 0.15) {
            pulseAnim.restart()
        }
        root._previousValue = root.value
    }
}
