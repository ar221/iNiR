pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
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

    // ── ThumbCell ──────────────────────────────────────────────────────
    // Square-edged (3px) thumbnail with hover scale + click-to-apply.
    // Empty slots render as muted placeholder rects so the grid never collapses.
    component ThumbCell : Item {
        id: cell
        required property int index
        readonly property string _path: (cell.index < root._count) ? root._paths[cell.index] : ""
        readonly property bool _filled: _path.length > 0
        readonly property bool _isActive: _filled && Wallpapers.isCurrentWallpaperPath(_path, "main")

        Layout.fillWidth: true
        Layout.preferredHeight: 60
        implicitHeight: 60

        property bool _hovered: false

        // Bottom-anchored hover lift via Scale transform — doesn't shove neighbours.
        transform: Scale {
            origin.x: cell.width / 2
            origin.y: cell.height
            xScale: cell._hovered ? 1.03 : 1.0
            yScale: cell._hovered ? 1.03 : 1.0
            Behavior on xScale {
                enabled: Appearance.animationsEnabled
                NumberAnimation {
                    duration: Appearance.animation.elementMoveEnter.duration
                    easing.type: Appearance.animation.elementMoveEnter.type
                    easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
                }
            }
            Behavior on yScale {
                enabled: Appearance.animationsEnabled
                NumberAnimation {
                    duration: Appearance.animation.elementMoveEnter.duration
                    easing.type: Appearance.animation.elementMoveEnter.type
                    easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
                }
            }
        }

        // Empty placeholder — cache cold or folder has <8 files.
        Rectangle {
            anchors.fill: parent
            radius: 3
            color: ColorUtils.transparentize(Appearance.colors.colLayer1, 0.4)
            visible: !cell._filled
        }

        // Real thumbnail — Loader gates so empty cells skip ThumbnailImage entirely.
        Loader {
            anchors.fill: parent
            active: cell._filled
            sourceComponent: ThumbnailImage {
                sourcePath: cell._path
                generateThumbnail: true
                cache: true
                asynchronous: true
                fillMode: Image.PreserveAspectCrop
                clip: true
                sourceSize.width: 256
                sourceSize.height: 256

                layer.enabled: Appearance.effectsEnabled
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: cell.width
                        height: cell.height
                        radius: 3
                    }
                }
            }
        }

        // Active-wallpaper ring — operational accent, NOT m3primary.
        // Matches shell-wide convention (QuickWallpaperItem, WallpaperConfig,
        // NavigationRail). border.width animates to keep the ring migration
        // legible when wallpaper changes.
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            radius: 3
            border.width: cell._isActive ? 2 : 0
            border.color: Appearance.colors.colPrimary
            Behavior on border.width {
                enabled: Appearance.animationsEnabled
                NumberAnimation {
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Appearance.animation.elementMoveFast.type
                    easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: cell._filled ? Qt.PointingHandCursor : Qt.ArrowCursor
            enabled: cell._filled
            onEntered: cell._hovered = true
            onExited:  cell._hovered = false
            onClicked: Wallpapers.apply(cell._path)
        }
    }

    // ── Tier A: 2×4 recent-wallpaper grid ──────────────────────────────
    GridLayout {
        Layout.fillWidth: true
        columns: 4
        rowSpacing: 4
        columnSpacing: 4

        Repeater {
            model: 8
            delegate: ThumbCell {}
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
