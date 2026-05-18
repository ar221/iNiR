pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.services

// WallpaperPalette — two-tier wallpaper dispatch packet for the Wallhaven view.
//
// Tier A (top): 2×4 grid of the 8 most-recent wallpapers (newest first).
// Tier B (bottom): 6 matugen swatches the system is currently running.
// Hairline divider between. Sits on AmbientBackground directly — no card/plate.
//
// Hover scales a swatch up; click copies hex to clipboard.
ColumnLayout {
    id: root
    spacing: 6
    Layout.fillWidth: true

    // ── Data ────────────────────────────────────────────────────────────
    // Newest-first slice of the cached wallpapers list. Wallpapers.wallpapers
    // is sorted oldest-first via FolderListModel.Time ascending, so reverse the
    // tail to get "recent rotation" semantics.
    readonly property var _paths: {
        const all = Wallpapers.wallpapers
        if (!all || all.length === 0) return []
        if (all.length <= 8) return all.slice().reverse()
        return all.slice(-8).reverse()
    }
    readonly property int _count: _paths.length

    // ── Tier A: 2×4 recent-wallpaper grid (placeholders for INI-16) ─────
    GridLayout {
        Layout.fillWidth: true
        columns: 4
        rowSpacing: 4
        columnSpacing: 4

        Repeater {
            model: 8
            delegate: Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                implicitHeight: 60

                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                }
            }
        }
    }

    // ── Tier B: 6 matugen swatches ──────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: 2

        component PaletteSwatch : Rectangle {
            id: swatch
            required property color swatchColor
            required property string label

            Layout.fillWidth: true
            implicitHeight: 18
            radius: 2
            color: swatch.swatchColor
            clip: false

            transform: Scale {
                origin.x: 0
                origin.y: swatch.height
                yScale: mouseArea.containsMouse ? 1.4 : 1.0
                Behavior on yScale {
                    enabled: Appearance.animationsEnabled
                    NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Quickshell.clipboardText = swatch.swatchColor.toString().toUpperCase()
                }
            }
        }

        PaletteSwatch { swatchColor: Appearance.m3colors.m3primary;           label: "Primary" }
        PaletteSwatch { swatchColor: Appearance.m3colors.m3secondary;         label: "Secondary" }
        PaletteSwatch { swatchColor: Appearance.m3colors.m3tertiary;          label: "Tertiary" }
        PaletteSwatch { swatchColor: Appearance.m3colors.m3surfaceContainer;  label: "Surface" }
        PaletteSwatch { swatchColor: Appearance.m3colors.m3error;             label: "Error" }
        PaletteSwatch { swatchColor: Appearance.m3colors.m3outline;           label: "Outline" }
    }
}
