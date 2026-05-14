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
    readonly property real baseButtonSize: baseIconSize + (root.railVertical ? 2 : 8)

    Layout.fillHeight: !vertical
    Layout.fillWidth: vertical

    implicitWidth: baseButtonSize
    implicitHeight: baseButtonSize
    buttonRadius: root.railVertical ? 2
        : Appearance.angelEverywhere ? Appearance.angel.roundingSmall
        : Appearance.inirEverywhere ? Appearance.inir.roundingSmall : Appearance.rounding.normal

    // Background: fully transparent for angel (no boxes visible), only glass on hover
    colBackground: root.railVertical ? "#0f1317"
        : Appearance.angelEverywhere ? "transparent" : "transparent"

    // Hover colors for dock (Layer0 context)
    colBackgroundHover: root.railVertical ? "#171d22"
        : Appearance.angelEverywhere ? Appearance.angel.colGlassCard
        : Appearance.inirEverywhere ? Appearance.inir.colLayer1Hover
        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurface
        : Appearance.colors.colLayer0Hover
    colBackgroundToggled: root.railVertical ? "#151b20" : Appearance.colors.colPrimary
    colBackgroundToggledHover: root.railVertical ? "#1b2329" : Appearance.colors.colPrimaryHover
    colRipple: root.railVertical ? "#222b32"
        : Appearance.angelEverywhere ? Appearance.angel.colGlassCardActive
        : Appearance.inirEverywhere ? Appearance.inir.colLayer1Active
        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurfaceActive
        : Appearance.colors.colLayer0Active
    rippleEnabled: !root.railVertical

    background.implicitHeight: baseButtonSize
    background.implicitWidth: baseButtonSize
}
