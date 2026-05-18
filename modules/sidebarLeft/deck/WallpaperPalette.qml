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

    // Prime the freedesktop thumbnail cache for the wallpapers folder on first
    // mount. generateThumbnail() is debounced (300ms) and the underlying script
    // skips files that already have a cached PNG, so re-mounts are cheap. Without
    // this, cells stay invisible for 1–2s on cold cache because ThumbnailImage
    // only fades in on Image.Ready. Matches QuickConfig.qml:479 precedent.
    Component.onCompleted: Wallpapers.generateThumbnail("large")

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

    // Live list of mounted PaletteSwatch items, populated by the chip
    // Repeater's onItemAdded. Read by paletteRippleAnim. Null-safe targets
    // (see §7 of the spec) cover the hot-reload race where the ripple
    // fires before all six delegates have mounted.
    property var _chipItems: []

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

        // Always-on base layer. Paints under the thumbnail so cells never go
        // invisible while ThumbnailImage waits for Image.Ready (otherwise cold
        // freedesktop cache → 1–2s of empty cells, see INI-14 followup). When
        // the thumb fades in, the opaque image covers this rect exactly (same
        // 3px radius via OpacityMask). Stays as the permanent fill for empty
        // cells when the folder has <8 wallpapers.
        Rectangle {
            anchors.fill: parent
            radius: 3
            color: ColorUtils.transparentize(Appearance.colors.colLayer1, 0.4)
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

    // ── PaletteSwatch ──────────────────────────────────────────────────
    // Index-driven so the ripple (INI-20) can address each chip by
    // _chipItems[index]. Carries a _rippleScale hook composed multiplicatively
    // with the existing 1.4 hover lift. Behavior on color cross-fades on
    // matugen regen so palette swaps feel seeded, not snapped.
    component PaletteSwatch : Rectangle {
        id: swatch
        required property int swatchIndex

        readonly property var _palette: [
            Appearance.m3colors.m3primary,
            Appearance.m3colors.m3secondary,
            Appearance.m3colors.m3tertiary,
            Appearance.m3colors.m3surfaceContainer,
            Appearance.m3colors.m3error,
            Appearance.m3colors.m3outline
        ]
        readonly property color swatchColor: _palette[swatchIndex] ?? Appearance.m3colors.m3outline

        // Ripple hook — driven by paletteRippleAnim in INI-20. Default 1.0
        // keeps hover-only behaviour identical to pre-INI-19 chip.
        property real _rippleScale: 1.0

        Layout.fillWidth: true
        implicitHeight: 18
        radius: 2
        color: swatch.swatchColor
        clip: false

        Behavior on color {
            enabled: Appearance.animationsEnabled
            ColorAnimation {
                duration: Appearance.animation.elementMoveFast.duration
                easing.type: Appearance.animation.elementMoveFast.type
                easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
            }
        }

        transform: Scale {
            origin.x: 0
            origin.y: swatch.height
            xScale: (mouseArea.containsMouse ? 1.4 : 1.0) * swatch._rippleScale
            yScale: (mouseArea.containsMouse ? 1.4 : 1.0) * swatch._rippleScale
            Behavior on yScale {
                enabled: Appearance.animationsEnabled
                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
            }
            Behavior on xScale {
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

    // ── Hairline divider — Courier "two related blocks, formally separated" ─
    // Hard 1px colLayer1 separator. NOT a SectionHeader fade (different idiom).
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Appearance.colors.colLayer1
    }

    // ── Tier B: 6 matugen swatches ──────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: 2

        Repeater {
            model: 6
            delegate: PaletteSwatch {
                required property int index
                swatchIndex: index
            }
            // Note: with ComponentBehavior:Bound, the delegate root must
            // declare `required property int index` to receive the model role.
            onItemAdded: (idx, item) => {
                const copy = root._chipItems.slice()
                copy[idx] = item
                root._chipItems = copy
            }
        }
    }

    // ── Signature ripple — dispatch receipt on Wallpapers.changed() ────
    // Six SequentialAnimation siblings inside ParallelAnimation, 35ms
    // stagger. Each chip pulses _rippleScale 1.0 → 1.18 → 1.0 over 150ms
    // (75ms OutQuad each leg). Total 325ms end-to-end, completes within
    // matugen's 200–400ms regen window so the colour cross-fade overlaps
    // the ripple tail and resolves into the new palette.
    Connections {
        target: Wallpapers
        function onChanged() {
            if (!Appearance.animationsEnabled) return
            paletteRippleAnim.restart()
        }
    }

    ParallelAnimation {
        id: paletteRippleAnim

        SequentialAnimation {
            PauseAnimation { duration: 0 }
            NumberAnimation { target: root._chipItems[0] ?? null; property: "_rippleScale"; from: 1.0; to: 1.18; duration: 75; easing.type: Easing.OutQuad }
            NumberAnimation { target: root._chipItems[0] ?? null; property: "_rippleScale"; from: 1.18; to: 1.0; duration: 75; easing.type: Easing.OutQuad }
        }
        SequentialAnimation {
            PauseAnimation { duration: 35 }
            NumberAnimation { target: root._chipItems[1] ?? null; property: "_rippleScale"; from: 1.0; to: 1.18; duration: 75; easing.type: Easing.OutQuad }
            NumberAnimation { target: root._chipItems[1] ?? null; property: "_rippleScale"; from: 1.18; to: 1.0; duration: 75; easing.type: Easing.OutQuad }
        }
        SequentialAnimation {
            PauseAnimation { duration: 70 }
            NumberAnimation { target: root._chipItems[2] ?? null; property: "_rippleScale"; from: 1.0; to: 1.18; duration: 75; easing.type: Easing.OutQuad }
            NumberAnimation { target: root._chipItems[2] ?? null; property: "_rippleScale"; from: 1.18; to: 1.0; duration: 75; easing.type: Easing.OutQuad }
        }
        SequentialAnimation {
            PauseAnimation { duration: 105 }
            NumberAnimation { target: root._chipItems[3] ?? null; property: "_rippleScale"; from: 1.0; to: 1.18; duration: 75; easing.type: Easing.OutQuad }
            NumberAnimation { target: root._chipItems[3] ?? null; property: "_rippleScale"; from: 1.18; to: 1.0; duration: 75; easing.type: Easing.OutQuad }
        }
        SequentialAnimation {
            PauseAnimation { duration: 140 }
            NumberAnimation { target: root._chipItems[4] ?? null; property: "_rippleScale"; from: 1.0; to: 1.18; duration: 75; easing.type: Easing.OutQuad }
            NumberAnimation { target: root._chipItems[4] ?? null; property: "_rippleScale"; from: 1.18; to: 1.0; duration: 75; easing.type: Easing.OutQuad }
        }
        SequentialAnimation {
            PauseAnimation { duration: 175 }
            NumberAnimation { target: root._chipItems[5] ?? null; property: "_rippleScale"; from: 1.0; to: 1.18; duration: 75; easing.type: Easing.OutQuad }
            NumberAnimation { target: root._chipItems[5] ?? null; property: "_rippleScale"; from: 1.18; to: 1.0; duration: 75; easing.type: Easing.OutQuad }
        }
    }
}
