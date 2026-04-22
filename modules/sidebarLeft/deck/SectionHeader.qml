import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.functions

/**
 * SectionHeader — mission-control style section divider.
 *
 * Left accent stripe (2px colPrimary) + monospace all-caps label + gradient fade.
 * Retrofuturism aesthetic — reads like terminal section headers or instrument
 * panel labels.
 *
 * Currently used by AudioView, MediaView, and SystemView as the shared
 * Deck section marker.
 */
RowLayout {
    id: root
    required property string text
    readonly property string monoFamily: (Appearance.font && Appearance.font.family && Appearance.font.family.mono)
        ? Appearance.font.family.mono
        : "monospace"
    readonly property real sectionLetterSpacing: 1.25
    Layout.fillWidth: true
    spacing: 8

    // Left accent stripe — solid colPrimary bar, 2px wide
    Rectangle {
        width: 2
        height: 12
        color: Appearance.colors.colPrimary
    }

    // Monospace all-caps label
    Text {
        text: root.text
        font.pixelSize: 9
        font.weight: Font.DemiBold
        font.letterSpacing: root.sectionLetterSpacing
        font.family: root.monoFamily
        font.capitalization: Font.AllUppercase
        color: ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.55)
    }

    // Gradient fade trail — colPrimary → transparent
    Rectangle {
        Layout.fillWidth: true
        height: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.25) }
            GradientStop { position: 0.5; color: ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.08) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }
}
