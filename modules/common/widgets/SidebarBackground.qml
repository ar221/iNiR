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

    // ── Audio trail border (opt-in per sidebar side) ─────────────
    // Set audioTrail: true on the left sidebar to show the orbiting
    // accent light when audio is playing.
    property bool audioTrail: false

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

        // ── Audio trail border ────────────────────────────────────
        // A rotating accent-colored light streak that traces the sidebar
        // perimeter when audio is playing. Fades in/out on playback state.
        // Disabled in gameModeMinimal, when effects or animations are off.
        Item {
            id: audioTrailContainer
            anchors.fill: parent
            z: 11   // above AngelPartialBorder

            // Gate: opt-in + effects + not game-mode-minimal + animations enabled
            readonly property bool _trailEnabled: root.audioTrail
                && !root.gameModeMinimal
                && Appearance.effectsEnabled
                && Appearance.animationsEnabled

            readonly property bool _playing: MprisController.isPlaying

            opacity: (_trailEnabled && _playing) ? 1.0 : 0.0
            Behavior on opacity {
                NumberAnimation {
                    duration: 380
                    easing.type: Easing.OutCubic
                }
            }

            // The ring border width for the trail.
            readonly property int trailBorderWidth: 3

            // ── Conical gradient — fills the container ────────────────
            // Arc occupies roughly 20% of the circle (72° peak → transparent).
            // The remaining ~80% is fully transparent — giving a clean
            // single-streak "light chasing the edge" look.
            GE.ConicalGradient {
                id: _conicalGrad
                anchors.fill: parent
                // No `source` — fill entire area, OpacityMask on container carves the ring
                angle: 0    // driven by NumberAnimation below

                gradient: Gradient {
                    // Bright head — accent at ~70% opacity
                    GradientStop {
                        position: 0.0
                        color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.3)
                    }
                    // Fade out over ~20% of circumference (72°)
                    GradientStop {
                        position: 0.12
                        color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.72)
                    }
                    GradientStop {
                        position: 0.22
                        color: "transparent"
                    }
                    // Remainder: fully transparent
                    GradientStop {
                        position: 0.23
                        color: "transparent"
                    }
                    GradientStop {
                        position: 1.0
                        color: "transparent"
                    }
                }

                NumberAnimation on angle {
                    from: 0
                    to: 360
                    duration: 3500
                    loops: Animation.Infinite
                    running: audioTrailContainer.opacity > 0
                }
            }

            // ── OpacityMask: carves out the center so only the ring shows ─
            // The mask is a hollow ring: outer = full rect, inner cutout via
            // a smaller Rectangle subtracted by painting the ring border only.
            // We use a layered Rectangle with only border.color set so the
            // mask is white at the border edges and transparent inside/outside.
            layer.enabled: true
            layer.effect: GE.OpacityMask {
                maskSource: Item {
                    width: audioTrailContainer.width
                    height: audioTrailContainer.height

                    // Outer fill = opaque white (mask allows gradient through here)
                    // We draw only the border ring and leave the interior transparent.
                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        radius: _bg.radius
                        border.width: audioTrailContainer.trailBorderWidth
                        border.color: "white"
                        layer.enabled: true
                    }
                }
            }
        }
    }
}
