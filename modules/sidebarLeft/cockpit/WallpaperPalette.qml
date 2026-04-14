pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

/**
 * WallpaperPalette — cockpit bottom slot.
 *
 * Session E: full implementation replacing the stub.
 *   - 2×4 grid of thumbnails (most-recent 8, newest top-left)
 *   - Tap thumbnail → Wallpapers.apply(path), active-ring on current
 *   - Palette row: 5 Material You swatches (primary/secondary/tertiary/
 *     surfaceContainer/error) + expand trigger
 *   - Chip click copies hex to Quickshell.clipboardText (no subprocess)
 *   - Signature move: left-to-right ripple on Wallpapers.changed()
 *   - No card chrome, no plate, no scrim — sits on AmbientBackground
 *   - Content-sized height (152px nominal at 106×59 cells)
 */
Item {
    id: root

    // ── Layout ───────────────────────────────────────────────────────────────
    Layout.fillWidth: true
    Layout.preferredHeight: implicitHeight
    Layout.minimumHeight: implicitHeight

    // ── Signal ───────────────────────────────────────────────────────────────
    signal expandRequested()

    // ── Thumbnail path list (most-recent 8, newest-first) ────────────────────
    readonly property var _paths: {
        const all = Wallpapers.wallpapers
        if (all.length === 0) return []
        if (all.length <= 8) return all.slice().reverse()
        return all.slice(-8).reverse()
    }
    readonly property int _count: _paths.length

    // ── Palette chip model ────────────────────────────────────────────────────
    readonly property var _chips: [
        { key: "primary",   color: Appearance.colors.colPrimary },
        { key: "secondary", color: Appearance.colors.colSecondary },
        { key: "tertiary",  color: Appearance.colors.colTertiary },
        { key: "surface",   color: Appearance.colors.colSurfaceContainer },
        { key: "error",     color: Appearance.colors.colError }
    ]

    // ── Chip item refs for signature-move ripple ──────────────────────────────
    property var _chipItems: []

    // ── Signature move: ripple on wallpaper change ────────────────────────────
    Connections {
        target: Wallpapers
        function onChanged() {
            if (!Appearance.animationsEnabled) return
            paletteRippleAnim.start()
        }
    }

    // Choreographed ripple on wallpaper change — bare 75ms/OutQuad values are
    // intentional for the micro-animation timing; do NOT migrate to elementMoveFast.
    ParallelAnimation {
        id: paletteRippleAnim
        SequentialAnimation {
            PauseAnimation { duration: 0 }
            NumberAnimation { target: root._chipItems[0] ?? null; property: "_rippleScale"; from: 1.0; to: 1.15; duration: 75; easing.type: Easing.OutQuad }
            NumberAnimation { target: root._chipItems[0] ?? null; property: "_rippleScale"; from: 1.15; to: 1.0; duration: 75; easing.type: Easing.OutQuad }
        }
        SequentialAnimation {
            PauseAnimation { duration: 40 }
            NumberAnimation { target: root._chipItems[1] ?? null; property: "_rippleScale"; from: 1.0; to: 1.15; duration: 75; easing.type: Easing.OutQuad }
            NumberAnimation { target: root._chipItems[1] ?? null; property: "_rippleScale"; from: 1.15; to: 1.0; duration: 75; easing.type: Easing.OutQuad }
        }
        SequentialAnimation {
            PauseAnimation { duration: 80 }
            NumberAnimation { target: root._chipItems[2] ?? null; property: "_rippleScale"; from: 1.0; to: 1.15; duration: 75; easing.type: Easing.OutQuad }
            NumberAnimation { target: root._chipItems[2] ?? null; property: "_rippleScale"; from: 1.15; to: 1.0; duration: 75; easing.type: Easing.OutQuad }
        }
        SequentialAnimation {
            PauseAnimation { duration: 120 }
            NumberAnimation { target: root._chipItems[3] ?? null; property: "_rippleScale"; from: 1.0; to: 1.15; duration: 75; easing.type: Easing.OutQuad }
            NumberAnimation { target: root._chipItems[3] ?? null; property: "_rippleScale"; from: 1.15; to: 1.0; duration: 75; easing.type: Easing.OutQuad }
        }
        SequentialAnimation {
            PauseAnimation { duration: 160 }
            NumberAnimation { target: root._chipItems[4] ?? null; property: "_rippleScale"; from: 1.0; to: 1.15; duration: 75; easing.type: Easing.OutQuad }
            NumberAnimation { target: root._chipItems[4] ?? null; property: "_rippleScale"; from: 1.15; to: 1.0; duration: 75; easing.type: Easing.OutQuad }
        }
    }

    // ── Inline components ────────────────────────────────────────────────────

    component ThumbCell: Item {
        id: cell
        required property int index
        readonly property string _path: (cell.index < root._count) ? root._paths[cell.index] : ""
        readonly property bool _filled: _path.length > 0
        readonly property bool _isActive: _filled && Wallpapers.isCurrentWallpaperPath(_path, "main")

        Layout.fillWidth: true
        Layout.preferredHeight: 59
        implicitHeight: 59

        property bool _hovered: false
        scale: _hovered ? 1.03 : 1.0
        Behavior on scale {
            enabled: Appearance.animationsEnabled
            NumberAnimation {
                duration: Appearance.animation.elementMoveEnter.duration
                easing.type: Appearance.animation.elementMoveEnter.type
                easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
            }
        }

        // Empty placeholder — shown when cache not yet populated or fewer than 8 files
        Rectangle {
            anchors.fill: parent
            radius: Appearance.rounding.small
            color: ColorUtils.transparentize(Appearance.colors.colSurfaceContainerLow, 0.5)
            visible: !cell._filled
        }

        // Real thumbnail — async, fades in when ready
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
                        radius: Appearance.rounding.small
                    }
                }
            }
        }

        // Active-wallpaper ring — 2px primary border, transitions on state change
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            radius: Appearance.rounding.small
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

    component PaletteChip: Item {
        id: chip
        required property int chipIndex
        readonly property var   _def: root._chips[chip.chipIndex]
        readonly property color _color: _def.color
        readonly property string _key: _def.key

        Layout.preferredWidth: 18
        Layout.preferredHeight: 18
        Layout.alignment: Qt.AlignVCenter

        // Three scale axes — multiplicative composition
        property real _hoverScale:  1.0
        property real _clickScale:  1.0
        property real _rippleScale: 1.0
        scale: _hoverScale * _clickScale * _rippleScale

        Behavior on _hoverScale {
            enabled: Appearance.animationsEnabled
            NumberAnimation {
                duration: Appearance.animation.elementMoveEnter.duration
                easing.type: Appearance.animation.elementMoveEnter.type
                easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: Appearance.rounding.small
            color: chip._color
            border.width: 1
            border.color: ColorUtils.mix(chip._color, Appearance.colors.colOnLayer1, 0.8)
            Behavior on color {
                enabled: Appearance.animationsEnabled
                ColorAnimation {
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Appearance.animation.elementMoveFast.type
                    easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: chip._hoverScale = 1.15
            onExited:  chip._hoverScale = 1.0
            onClicked: {
                Quickshell.clipboardText = chip._hexString()
                clickFlash.restart()
            }
        }

        // Lowercase #rrggbb — strip alpha defensively (Qt can emit #aarrggbb)
        function _hexString(): string {
            const c = chip._color
            const r = Math.round(c.r * 255).toString(16).padStart(2, "0")
            const g = Math.round(c.g * 255).toString(16).padStart(2, "0")
            const b = Math.round(c.b * 255).toString(16).padStart(2, "0")
            return "#" + r + g + b
        }

        // Click flash — 1.0 → 1.3 → 1.0 over 200ms, confirms clipboard write
        SequentialAnimation {
            id: clickFlash
            NumberAnimation {
                target: chip; property: "_clickScale"; from: 1.0; to: 1.3
                duration: 80; easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: chip; property: "_clickScale"; from: 1.3; to: 1.0
                duration: 120; easing.type: Easing.OutQuad
            }
        }

        StyledToolTip {
            text: chip._hexString() + "  ·  " + chip._key
        }
    }

    component ExpandTrigger: Item {
        id: trigger
        Layout.preferredWidth: 20
        Layout.preferredHeight: 20
        Layout.alignment: Qt.AlignVCenter

        property bool _hovered: false
        scale: _hovered ? 1.1 : 1.0
        Behavior on scale {
            enabled: Appearance.animationsEnabled
            NumberAnimation {
                duration: Appearance.animation.elementMoveEnter.duration
                easing.type: Appearance.animation.elementMoveEnter.type
                easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
            }
        }

        MaterialSymbol {
            anchors.centerIn: parent
            text: "arrow_forward"
            iconSize: 18
            color: trigger._hovered
                ? Appearance.colors.colOnLayer1
                : Appearance.colors.colOnLayer1Inactive
            Behavior on color {
                enabled: Appearance.animationsEnabled
                ColorAnimation {
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Appearance.animation.elementMoveFast.type
                    easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: trigger._hovered = true
            onExited:  trigger._hovered = false
            onClicked: {
                console.log("expand wallpaper browse")
                root.expandRequested()
            }
        }

        StyledToolTip { text: qsTr("Browse wallpapers") }
    }

    // ── Layout tree ──────────────────────────────────────────────────────────

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 8

        // Thumbnail grid — 2 rows × 4 columns, 106×59 cells, 6px gaps
        GridLayout {
            Layout.fillWidth: true
            columns: 4
            rowSpacing: 6
            columnSpacing: 6

            Repeater {
                model: 8
                delegate: ThumbCell { index: model.index }
            }
        }

        // Palette row — chips left, expand trigger right
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: 5
                delegate: PaletteChip { chipIndex: model.index }
                onItemAdded: (index, item) => {
                    const copy = root._chipItems.slice()
                    copy[index] = item
                    root._chipItems = copy
                }
            }

            Item { Layout.fillWidth: true }   // filler pushes trigger right

            ExpandTrigger {}
        }
    }
}
