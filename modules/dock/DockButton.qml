import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts

RippleButton {
    id: root
    property bool vertical: false
    property string dockPosition: "bottom"
    readonly property bool railVertical: (Config.options?.dock?.style === "rail") && root.vertical && (root.dockPosition === "left" || root.dockPosition === "right")

    readonly property real baseIconSize: root.railVertical ? (Config.options?.dock?.railIconSize ?? 32) : (Config.options?.dock?.iconSize ?? 56)
    readonly property real baseButtonSize: baseIconSize + (root.railVertical ? 6 : 8)

    Layout.fillHeight: !vertical
    Layout.fillWidth: vertical

    implicitWidth: baseButtonSize
    implicitHeight: baseButtonSize
    buttonRadius: root.railVertical ? 6
        : Appearance.angelEverywhere ? Appearance.angel.roundingSmall
        : Appearance.inirEverywhere ? Appearance.inir.roundingSmall : Appearance.rounding.normal

    // Background: fully transparent for angel (no boxes visible), only glass on hover
    colBackground: Appearance.angelEverywhere ? "transparent" : "transparent"

    // Hover colors for dock (Layer0 context)
    colBackgroundHover: Appearance.angelEverywhere ? Appearance.angel.colGlassCard
        : Appearance.inirEverywhere ? Appearance.inir.colLayer1Hover
        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurface
        : Appearance.colors.colLayer0Hover
    colRipple: Appearance.angelEverywhere ? Appearance.angel.colGlassCardActive
        : Appearance.inirEverywhere ? Appearance.inir.colLayer1Active
        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurfaceActive
        : Appearance.colors.colLayer0Active

    background.implicitHeight: baseButtonSize
    background.implicitWidth: baseButtonSize
}
