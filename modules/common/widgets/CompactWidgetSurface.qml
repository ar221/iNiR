import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick

// CompactWidgetSurface — theme-aware card container for compact sidebar widgets.
// Replaces 7 identical StyledRectangularShadow + Rectangle + Loader blocks.
// Requires a parent with: inirEverywhere, auroraEverywhere, angelEverywhere, colDarkSurface.
Item {
    id: root
    anchors.fill: parent

    // ── Required: the widget to render inside the card ───────────
    required property Component widget

    // ── Theme context — bind from parent background (bg.xxx) ─────
    required property bool inirEverywhere
    required property bool auroraEverywhere
    required property bool angelEverywhere
    required property color colDarkSurface

    StyledRectangularShadow {
        target: surface
        visible: !root.inirEverywhere && !root.auroraEverywhere && !root.angelEverywhere
        blur: 0.35 * Appearance.sizes.elevationMargin
    }

    Rectangle {
        id: surface
        anchors.fill: parent
        anchors.margins: 8
        radius: root.angelEverywhere ? Appearance.angel.roundingNormal
            : root.inirEverywhere ? Appearance.inir.roundingNormal
            : Appearance.rounding.normal
        color: root.angelEverywhere ? Appearance.angel.colGlassCard
            : root.inirEverywhere ? Appearance.inir.colLayer1
            : root.colDarkSurface
        border.width: root.angelEverywhere ? Appearance.angel.cardBorderWidth : 1
        border.color: root.angelEverywhere ? ColorUtils.transparentize(Appearance.angel.colCardBorder, 0.22)
            : root.inirEverywhere ? Appearance.inir.colBorder
            : root.auroraEverywhere ? ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.78)
            : ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.72)
        clip: true

        Loader {
            anchors.fill: parent
            anchors.margins: 6
            sourceComponent: root.widget
        }
    }
}
