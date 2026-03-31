import QtQuick
import QtQuick.Effects
import qs.modules.common

/**
 * Icon tinting component — desaturates and color-adjusts an icon source
 * to blend with the current theme. Uses a single-pass MultiEffect instead
 * of the older Desaturate + ColorOverlay chain.
 *
 * Renders the tinted version on top of the source. When inactive, costs nothing
 * (Loader not loaded).
 *
 * Usage:
 *   IconImage { id: myIcon; source: "..." }
 *   Tint {
 *       active: Config.options?.dock?.monochromeIcons ?? false
 *       anchors.fill: myIcon
 *       source: myIcon
 *   }
 */
Item {
    id: root

    // === API ===
    property bool active: false
    property Item source

    // Tuning knobs — defaults match nucleus-shell's values
    property real saturation: -1.0       // -1.0 = fully desaturated
    property real contrast: 0.10
    property real brightness: -0.08
    property color tintColor: "transparent" // Optional: overlay a theme color (transparent = no overlay)
    property real tintOpacity: 0.15      // How strong the color overlay is

    readonly property bool effectActive: root.active && root.source && Appearance.effectsEnabled

    visible: effectActive

    Loader {
        id: loader
        active: root.effectActive
        anchors.fill: parent

        sourceComponent: MultiEffect {
            source: root.source
            anchors.fill: parent
            saturation: root.saturation
            contrast: root.contrast
            brightness: root.brightness
        }
    }

    // Optional color tint overlay (e.g. to shift toward primary color)
    Loader {
        active: loader.active && root.tintColor !== Qt.rgba(0,0,0,0) && root.tintOpacity > 0
        anchors.fill: parent
        sourceComponent: Rectangle {
            color: root.tintColor
            opacity: root.tintOpacity
        }
    }
}
