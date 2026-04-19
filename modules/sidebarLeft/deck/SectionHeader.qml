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
 * Currently used by AudioView; MediaView/SystemView still use the legacy
 * DeckDivider + DeckLabel pair. Migrate those in a separate pass if/when
 * desired.
 */
RowLayout {
    id: root
    required property string text
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
        font.weight: Font.Bold
        font.letterSpacing: 1.5
        font.family: Appearance.font.family.mono
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
