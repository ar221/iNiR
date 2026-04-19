import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.common.widgets.widgetCanvas
import qs.modules.background.widgets
import qs.services

AbstractBackgroundWidget {
    id: root

    configEntryName: "fileExplorer"

    readonly property var feCfg: configEntry
    readonly property real fontScale: feCfg?.fontScale ?? 1.0
    readonly property real widgetWidth: feCfg?.widgetWidth ?? 220
    readonly property real widgetHeight: feCfg?.widgetHeight ?? 320
    readonly property var bookmarks: feCfg?.bookmarks ?? []
    readonly property string fileManager: feCfg?.fileManager ?? "dolphin"
    readonly property string terminal: feCfg?.terminal ?? "kitty"
    readonly property bool showHiddenFiles: feCfg?.showHiddenFiles ?? false

    // navigationStack: empty = bookmarks view; non-empty = folder view at last element
    property var navigationStack: []

    // Resize live tracking — separate from config-backed widgetWidth/widgetHeight
    // to avoid breaking the declarative binding during drag
    property real _liveWidth: root.widgetWidth
    property real _liveHeight: root.widgetHeight
    property real _resizeStartW: 0
    property real _resizeStartH: 0

    // Drive live dimensions: use _liveWidth during drag, widgetWidth otherwise.
    // _liveWidth is reset to widgetWidth when config changes (drag end writes back).
    implicitWidth: root._liveWidth
    implicitHeight: root._liveHeight

    onWidgetWidthChanged: root._liveWidth = root.widgetWidth
    onWidgetHeightChanged: root._liveHeight = root.widgetHeight

    // Widget card background
    Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.normal
        color: Appearance.colors.colLayer1
        opacity: 0.85
        border.color: Qt.rgba(
            Appearance.colors.colOutline.r,
            Appearance.colors.colOutline.g,
            Appearance.colors.colOutline.b,
            0.3
        )
        border.width: 1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 0
        spacing: 0

        // Header
        Item {
            Layout.fillWidth: true
            implicitHeight: headerRow.implicitHeight + 10

            RowLayout {
                id: headerRow
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: 12
                    rightMargin: 12
                }
                spacing: 8

                // Accent dot
                Rectangle {
                    id: accentDot
                    width: 6
                    height: 6
                    radius: 3
                    color: Appearance.colors.colPrimary
                    layer.enabled: Appearance.effectsEnabled
                    layer.effect: DropShadow {
                        transparentBorder: true
                        color: Qt.rgba(
                            Appearance.colors.colPrimary.r,
                            Appearance.colors.colPrimary.g,
                            Appearance.colors.colPrimary.b,
                            0.7
                        )
                        spread: 0.2
                        radius: 6
                        samples: 13
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Files")
                    font.pixelSize: Appearance.font.pixelSize.small * root.fontScale
                    font.letterSpacing: 1.5
                    color: Appearance.colors.colOnSurface
                    font.capitalization: Font.AllUppercase
                }
            }

            // Bottom separator
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Qt.rgba(
                    Appearance.colors.colOutline.r,
                    Appearance.colors.colOutline.g,
                    Appearance.colors.colOutline.b,
                    0.2
                )
            }
        }

        // Content area — swaps between bookmarks and folder view
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Bookmarks view
            BookmarksView {
                anchors.fill: parent
                anchors.margins: 4
                visible: root.navigationStack.length === 0
                bookmarks: root.bookmarks
                fontScale: root.fontScale
                onBookmarkClicked: function(path) {
                    root.navigationStack = [path]
                }
            }

            // Folder view
            FolderView {
                anchors.fill: parent
                visible: root.navigationStack.length > 0
                currentPath: root.navigationStack.length > 0
                    ? root.navigationStack[root.navigationStack.length - 1]
                    : ""
                fontScale: root.fontScale
                fileManager: root.fileManager
                terminal: root.terminal
                showHiddenFiles: root.showHiddenFiles
                onNavigateInto: function(path) {
                    root.navigationStack = [...root.navigationStack, path]
                }
                onNavigateUp: {
                    if (root.navigationStack.length <= 1) {
                        root.navigationStack = []
                    } else {
                        root.navigationStack = root.navigationStack.slice(0, -1)
                    }
                }
            }
        }
    }

    // Resize grip — bottom-right corner, edit-mode only
    Item {
        id: resizeGrip
        visible: GlobalStates.widgetEditMode
        width: 20
        height: 20
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        z: 1000

        HoverHandler {
            id: gripHover
            cursorShape: Qt.SizeFDiagCursor
        }

        // Corner tick marks (diagonal hatching)
        Canvas {
            anchors.fill: parent
            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                const alpha = gripHover.hovered ? 0.7 : 0.35;
                ctx.strokeStyle = Qt.rgba(
                    Appearance.colors.colOutline.r,
                    Appearance.colors.colOutline.g,
                    Appearance.colors.colOutline.b,
                    alpha
                );
                ctx.lineWidth = 1.5;
                ctx.lineCap = "round";
                // Three diagonal lines, bottom-right aligned
                const offsets = [4, 8, 12];
                for (const o of offsets) {
                    ctx.beginPath();
                    ctx.moveTo(width - o, height);
                    ctx.lineTo(width, height - o);
                    ctx.stroke();
                }
            }
            // Repaint when hover state changes
            Connections {
                target: gripHover
                function onHoveredChanged() { resizeCanvas.requestPaint() }
            }
            id: resizeCanvas
        }

        DragHandler {
            id: resizeDrag
            target: null
            grabPermissions: PointerHandler.CanTakeOverFromHandlersOfDifferentType

            onActiveChanged: {
                if (active) {
                    // Snapshot current rendered size
                    root._resizeStartW = root.width;
                    root._resizeStartH = root.height;
                } else {
                    // Persist on drag end — write to configEntry so widgetWidth/Height
                    // fire onChanged and re-sync _liveWidth/_liveHeight
                    if (root.feCfg) {
                        root.feCfg.widgetWidth = root._liveWidth;
                        root.feCfg.widgetHeight = root._liveHeight;
                    }
                }
            }

            onTranslationChanged: {
                if (!active) return;
                const minW = 160, maxW = 400;
                const minH = 200, maxH = 600;
                root._liveWidth = Math.max(minW, Math.min(maxW, root._resizeStartW + translation.x));
                root._liveHeight = Math.max(minH, Math.min(maxH, root._resizeStartH + translation.y));
            }
        }
    }
}
