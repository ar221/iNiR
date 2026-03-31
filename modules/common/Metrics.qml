pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

/**
 * Centralized dimensional abstraction — routes spacing, rounding, font sizing,
 * and animation durations through configurable scale factors.
 *
 * Inspired by nucleus-shell's Metrics pattern, adapted for iNiR.
 *
 * Appearance reads from Metrics for its scale factors. Components can reference
 * Metrics directly for spacing tokens or continue using Appearance (which delegates here).
 *
 * Config keys (all under appearance.metrics):
 *   spacingScale:   0.75 – 1.5  (default 1.0)
 *   roundingScale:  0.0  – 2.0  (default 1.0, multiplied with theme's own scale)
 *   fontScale:      0.8  – 1.3  (default 1.0)
 *   durationScale:  0.5  – 2.0  (default 1.0, 0 = instant)
 */
Singleton {
    id: root

    // ─── SCALE FACTORS ───
    // User-configurable overrides. Theme metadata (e.g. roundingScale from presets)
    // is applied separately in Appearance; these multiply on top.
    // Direct bindings to MetricsConfig's dedicated JsonAdapter for proper reactivity.
    readonly property real spacingScale: MetricsConfig.options.spacingScale
    readonly property real roundingScale: MetricsConfig.options.roundingScale
    readonly property real fontScale: MetricsConfig.options.fontScale
    readonly property real durationScale: MetricsConfig.options.durationScale

    // ─── SPACING TOKENS ───
    // Named spacing values scaled by spacingScale. Use these for consistent margins/padding.
    readonly property real spacingTiny: Math.round(4 * spacingScale)
    readonly property real spacingSmall: Math.round(8 * spacingScale)
    readonly property real spacingMedium: Math.round(12 * spacingScale)
    readonly property real spacingLarge: Math.round(16 * spacingScale)
    readonly property real spacingXLarge: Math.round(24 * spacingScale)
    readonly property real spacingXXLarge: Math.round(32 * spacingScale)

    // ─── DURATION TIERS ───
    // Named animation durations, pre-scaled. Use with calcEffectiveDuration() in Appearance
    // for GameMode/animation-disabled support. These are raw scaled values.
    readonly property int durationSupershort: Math.round(100 * durationScale)
    readonly property int durationShort: Math.round(200 * durationScale)
    readonly property int durationNormal: Math.round(400 * durationScale)
    readonly property int durationLong: Math.round(600 * durationScale)
    readonly property int durationExtraLong: Math.round(1000 * durationScale)
}
