import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.functions

/**
 * SectionHeader — fused gradient divider + small-caps label.
 *
 * Replaces the DeckDivider + DeckLabel pair pattern with a single tighter
 * unit. Gradient line above, label below. Uses theme tokens (colPrimary)
 * so accents shift with wallpaper palette — cohesive with post-Polish-Pass
 * standard.
 *
 * Currently used by AudioView; MediaView/SystemView still use the legacy
 * DeckDivider + DeckLabel pair. Migrate those in a separate pass if/when
 * desired.
 */
ColumnLayout {
    id: root
    required property string text
    Layout.fillWidth: true
    spacing: 4

    // Gradient break — colPrimary (matugen accent) → fade to transparent.
    Rectangle {
        Layout.fillWidth: true
        height: 2
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Appearance.colors.colPrimary }
            GradientStop { position: 0.4; color: ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.15) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // Small-caps label — same typography spec as the legacy DeckLabel
    // (size 8, bold, letter-spacing 2.5, 40% on colOnSurfaceVariant) but
    // without the trailing "─ line ─" rectangle (the gradient above is
    // enough to establish the section break).
    Text {
        text: root.text
        font.pixelSize: 8
        font.bold: true
        font.letterSpacing: 2.5
        font.capitalization: Font.AllUppercase
        color: ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.4)
    }
}
