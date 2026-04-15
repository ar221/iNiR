pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets

// PaletteExtractBar — 6 Material You swatches from current wallpaper palette.
// Hover scales the swatch up; click copies hex to clipboard.
RowLayout {
    id: root
    spacing: 2
    implicitHeight: 18

    component PaletteSwatch : Rectangle {
        id: swatch
        required property color swatchColor
        required property string label

        Layout.fillWidth: true
        implicitHeight: 18
        radius: 2
        color: swatch.swatchColor
        clip: false

        transform: Scale {
            origin.x: 0
            origin.y: swatch.height
            yScale: mouseArea.containsMouse ? 1.4 : 1.0
            Behavior on yScale {
                enabled: Appearance.animationsEnabled
                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                Quickshell.clipboardText = swatch.swatchColor.toString().toUpperCase()
            }

            // No tooltip — just click to copy hex
        }
    }

    PaletteSwatch { swatchColor: Appearance.m3colors.m3primary;           label: "Primary" }
    PaletteSwatch { swatchColor: Appearance.m3colors.m3secondary;         label: "Secondary" }
    PaletteSwatch { swatchColor: Appearance.m3colors.m3tertiary;          label: "Tertiary" }
    PaletteSwatch { swatchColor: Appearance.m3colors.m3surfaceContainer;  label: "Surface" }
    PaletteSwatch { swatchColor: Appearance.m3colors.m3error;             label: "Error" }
    PaletteSwatch { swatchColor: Appearance.m3colors.m3outline;           label: "Outline" }
}
