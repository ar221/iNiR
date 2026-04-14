import qs
import qs.services
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import Quickshell
import QtQuick.Effects
import Qt5Compat.GraphicalEffects as GE

// SidebarBackground — parameterized theme-aware background for sidebar content.
// Absorbs: ColorQuantizer, wallpaper-blended colors, theme color/border/radius,
// blurred wallpaper Image + MultiEffect, angel glow + partial borders.
// Bug fixes: left sidebar now gets inirEverywhere color branch, angelEverywhere
// in layer.enabled, and normalized blurMax (was 64, now 100).
Item {
    id: root

    // ── Required properties ──────────────────────────────────────
    required property string side           // "left" or "right"
    required property var panelScreen       // PanelWindow screen
    required property int screenWidth
    required property int screenHeight

    // ── Optional properties ──────────────────────────────────────
    property int sidebarWidth: Appearance.sizes.sidebarWidth
    property int sidebarPadding: 12

    // ── Exposed theme flags (children bind to these) ─────────────
    readonly property bool angelEverywhere: Appearance.angelEverywhere
    readonly property bool auroraEverywhere: Appearance.auroraEverywhere
    readonly property bool inirEverywhere: Appearance.inirEverywhere
    readonly property bool gameModeMinimal: Appearance.gameModeMinimal
    readonly property bool cardStyle: Config.options?.sidebar?.cardStyle ?? false

    // ── Exposed computed colors (CompactSidebar uses these) ──────
    readonly property QtObject blendedColors: _bg.blendedColors
    readonly property color wallpaperDominantColor: _bg.wallpaperDominantColor
    readonly property real backgroundRadius: _bg.radius

    // ── Content goes inside the background Rectangle ─────────────
    default property alias content: _bg.data

    implicitHeight: _bg.implicitHeight
    implicitWidth: _bg.implicitWidth

    StyledRectangularShadow {
        target: _bg
        visible: !root.inirEverywhere && !root.gameModeMinimal
    }

    Rectangle {
        id: _bg
        anchors.fill: parent
        implicitHeight: parent.height - Appearance.sizes.hyprlandGapsOut * 2
        implicitWidth: root.sidebarWidth - Appearance.sizes.hyprlandGapsOut * 2

        readonly property string wallpaperUrl: {
            const _dep1 = WallpaperListener.multiMonitorEnabled
            const _dep2 = WallpaperListener.effectivePerMonitor
            const _dep3 = Wallpapers.effectiveWallpaperUrl
            return WallpaperListener.wallpaperUrlForScreen(root.panelScreen)
        }

        ColorQuantizer {
            id: _quantizer
            source: (root.auroraEverywhere || root.angelEverywhere) ? _bg.wallpaperUrl : ""
            depth: 0
            rescaleSize: 10
        }

        readonly property color wallpaperDominantColor: _quantizer?.colors?.[0] ?? Appearance.colors.colPrimary
        readonly property QtObject blendedColors: AdaptedMaterialScheme {
            color: ColorUtils.mix(_bg.wallpaperDominantColor, Appearance.colors.colPrimaryContainer, 0.8)
                   || Appearance.m3colors.m3secondaryContainer
        }

        color: root.gameModeMinimal ? "transparent"
             : root.inirEverywhere ? (root.cardStyle ? Appearance.inir.colLayer1 : Appearance.inir.colLayer0)
             : root.auroraEverywhere ? ColorUtils.applyAlpha((_bg.blendedColors?.colLayer0 ?? Appearance.colors.colLayer0), 1)
             : (root.cardStyle ? Appearance.colors.colLayer1 : Appearance.colors.colLayer0)

        border.width: root.gameModeMinimal ? 0 : (root.angelEverywhere ? Appearance.angel.panelBorderWidth : 1)
        border.color: root.angelEverywhere ? Appearance.angel.colPanelBorder
                    : root.inirEverywhere ? Appearance.inir.colBorder
                    : Appearance.colors.colLayer0Border

        radius: root.angelEverywhere ? Appearance.angel.roundingNormal
              : root.inirEverywhere ? (root.cardStyle ? Appearance.inir.roundingLarge : Appearance.inir.roundingNormal)
              : root.cardStyle ? Appearance.rounding.normal
              : (Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1)

        clip: true

        layer.enabled: (root.angelEverywhere || root.auroraEverywhere) && !root.gameModeMinimal
        layer.effect: GE.OpacityMask {
            maskSource: Rectangle {
                width: _bg.width; height: _bg.height; radius: _bg.radius
            }
        }

        // ── Blurred wallpaper (aurora/angel themes) ──────────────
        Image {
            id: _blurredWallpaper
            // Position: align wallpaper so sidebar region shows the correct crop
            x: root.side === "right"
                ? -(root.screenWidth - _bg.width - Appearance.sizes.hyprlandGapsOut)
                : -Appearance.sizes.hyprlandGapsOut
            y: -Appearance.sizes.hyprlandGapsOut
            width: root.screenWidth
            height: root.screenHeight
            visible: root.auroraEverywhere && !root.inirEverywhere && !root.gameModeMinimal
            source: _bg.wallpaperUrl
            fillMode: Image.PreserveAspectCrop
            cache: true
            asynchronous: true
            sourceSize.width: root.screenWidth
            sourceSize.height: root.screenHeight

            layer.enabled: Appearance.effectsEnabled && root.auroraEverywhere && !root.inirEverywhere
            layer.effect: MultiEffect {
                source: _blurredWallpaper
                anchors.fill: source
                saturation: root.angelEverywhere
                    ? (Appearance.angel.blurSaturation * Appearance.angel.colorStrength)
                    : (Appearance.effectsEnabled ? 0.2 : 0)
                blurEnabled: Appearance.effectsEnabled
                blurMax: 100
                blur: Appearance.effectsEnabled
                    ? (root.angelEverywhere ? Appearance.angel.blurIntensity : 1) : 0
            }

            Rectangle {
                anchors.fill: parent
                color: root.angelEverywhere
                    ? ColorUtils.transparentize((_bg.blendedColors?.colLayer0 ?? Appearance.colors.colLayer0Base),
                                               Appearance.angel.overlayOpacity * Appearance.angel.panelTransparentize)
                    : ColorUtils.transparentize((_bg.blendedColors?.colLayer0 ?? Appearance.colors.colLayer0Base),
                                               Appearance.aurora.overlayTransparentize)
            }
        }

        // ── Angel inset glow — top edge ──────────────────────────
        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: Appearance.angel.insetGlowHeight
            visible: root.angelEverywhere
            color: Appearance.angel.colInsetGlow
            z: 10
        }

        // ── Angel partial border ─────────────────────────────────
        AngelPartialBorder {
            targetRadius: _bg.radius
            z: 10
        }
    }
}
