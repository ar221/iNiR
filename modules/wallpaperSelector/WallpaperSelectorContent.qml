import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects as GE
import Quickshell
import Quickshell.Io

MouseArea {
    id: root
    property int columns: 4
    property real previewCellAspectRatio: 4 / 3
    property bool useDarkMode: Appearance.m3colors.darkmode
    property string _lastThumbnailSizeName: ""

    // Multi-monitor support — capture focused monitor at open time
    property string _lockedTarget: ""
    property string _capturedMonitor: ""
    readonly property bool multiMonitorActive: Config.options?.background?.multiMonitor?.enable ?? false

    // ─── Wallpaper Engine mode ─────────────────────────────
    property bool weMode: false
    property var weWallpapers: []
    property string weCurrentId: ""
    property string weFilterText: ""

    readonly property var weFilteredWallpapers: {
        if (!weFilterText) return weWallpapers
        const q = weFilterText.toLowerCase()
        return weWallpapers.filter(w => w.title.toLowerCase().includes(q) || w.tags.toLowerCase().includes(q))
    }

    Process {
        id: weListProc
        property string _buffer: ""
        stdout: SplitParser {
            onRead: data => { weListProc._buffer += data }
        }
        onExited: (exitCode) => {
            if (exitCode === 0) {
                try {
                    root.weWallpapers = JSON.parse(weListProc._buffer)
                    const active = root.weWallpapers.find(w => w.active)
                    root.weCurrentId = active ? active.id : ""
                } catch(e) { root.weWallpapers = [] }
            }
            weListProc._buffer = ""
        }
    }

    function loadWEWallpapers() {
        weListProc._buffer = ""
        weListProc.command = ["we-wall", "--list-json"]
        weListProc.running = true
    }

    function applyWEWallpaper(wallpaperId) {
        Quickshell.execDetached(["we-wall", wallpaperId])
        GlobalStates.wallpaperSelectorOpen = false
    }

    function applyRandomWE() {
        Quickshell.execDetached(["we-wall"])
        GlobalStates.wallpaperSelectorOpen = false
    }

    function stopWEWallpaper() {
        Quickshell.execDetached(["we-wall", "--stop"])
        root.weCurrentId = ""
    }

    readonly property string selectedMonitor: {
        if (!multiMonitorActive) return ""
        if (_lockedTarget) return _lockedTarget
        return _capturedMonitor
    }

    Component.onCompleted: {
        // Read target monitor from GlobalStates (set before opening, no timing issues)
        const gsTarget = GlobalStates.wallpaperSelectorTargetMonitor ?? ""
        if (gsTarget && WallpaperListener.screenNames.includes(gsTarget)) {
            _lockedTarget = gsTarget
            return
        }
        // Fallback: check Config (for settings UI "Change" button via IPC)
        const configTarget = Config.options?.wallpaperSelector?.targetMonitor ?? ""
        if (configTarget && WallpaperListener.screenNames.includes(configTarget)) {
            _lockedTarget = configTarget
            return
        }
        // Last resort: capture focused monitor (may be stale if overlay already took focus)
        if (CompositorService.isNiri) {
            _capturedMonitor = NiriService.currentOutput ?? ""
        } else if (CompositorService.isHyprland) {
            _capturedMonitor = Hyprland.focusedMonitor?.name ?? ""
        }
    }

    function updateThumbnails() {
        const totalImageMargin = (Appearance.sizes.wallpaperSelectorItemMargins + Appearance.sizes.wallpaperSelectorItemPadding) * 2
        const thumbnailSizeName = Images.thumbnailSizeNameForDimensions(grid.cellWidth - totalImageMargin, grid.cellHeight - totalImageMargin)
        root._lastThumbnailSizeName = thumbnailSizeName
        Wallpapers.generateThumbnail(thumbnailSizeName)
    }

    Connections {
        target: Wallpapers
        function onDirectoryChanged() {
            root.updateThumbnails()
        }
    }

    Connections {
        target: Wallpapers.folderModel
        function onCountChanged() {
            if (!GlobalStates.wallpaperSelectorOpen) return;
            if (!root._lastThumbnailSizeName || root._lastThumbnailSizeName.length === 0) return;
            Wallpapers.generateThumbnail(root._lastThumbnailSizeName)
        }
    }

    function handleFilePasting(event) {
        const currentClipboardEntry = Cliphist.entries[0]
        if (/^\d+\tfile:\/\/\S+/.test(currentClipboardEntry)) {
            const url = StringUtils.cleanCliphistEntry(currentClipboardEntry);
            Wallpapers.setDirectory(FileUtils.trimFileProtocol(decodeURIComponent(url)));
            event.accepted = true;
        } else {
            event.accepted = false; // No image, let text pasting proceed
        }
    }

    function selectWallpaperPath(filePath) {
        if (filePath && filePath.length > 0) {
            const normalizedPath = FileUtils.trimFileProtocol(String(filePath))
            // Check Config first (set by settings.qml via IPC), then GlobalStates
            const configTarget = Config.options?.wallpaperSelector?.selectionTarget;
            let target = (configTarget && configTarget !== "main") ? configTarget : GlobalStates.wallpaperSelectionTarget;
            
            // Check if it's a video or GIF that needs thumbnail generation
            const lowerPath = normalizedPath.toLowerCase();
            const isVideo = lowerPath.endsWith(".mp4") || lowerPath.endsWith(".webm") || lowerPath.endsWith(".mkv") || lowerPath.endsWith(".avi") || lowerPath.endsWith(".mov");
            const isGif = lowerPath.endsWith(".gif");
            const needsThumbnail = isVideo || isGif;
            
            switch (target) {
                case "backdrop":
                    Config.setNestedValue("background.backdrop.useMainWallpaper", false);
                    Config.setNestedValue("background.backdrop.wallpaperPath", normalizedPath);
                    // Generate and set thumbnail for video/GIF
                    if (needsThumbnail) {
                        Wallpapers.generateThumbnail("large"); // Ensure generation is triggered
                        const thumbnailPath = Wallpapers.getExpectedThumbnailPath(normalizedPath, "large");
                        Config.setNestedValue("background.backdrop.thumbnailPath", thumbnailPath);
                    }
                    // If using backdrop for colors, regenerate theme colors
                    if (Config.options?.appearance?.wallpaperTheming?.useBackdropForColors) {
                        Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--noswitch"])
                    }
                    break;
                case "waffle":
                    Config.setNestedValue("waffles.background.useMainWallpaper", false);
                    Config.setNestedValue("waffles.background.wallpaperPath", normalizedPath);
                    // Generate and set thumbnail for video/GIF (used as fallback/preview)
                    if (needsThumbnail) {
                        Wallpapers.generateThumbnail("large");
                        const thumbnailPath = Wallpapers.getExpectedThumbnailPath(normalizedPath, "large");
                        Config.setNestedValue("waffles.background.thumbnailPath", thumbnailPath);
                    }
                    break;
                case "waffle-backdrop":
                    Config.setNestedValue("waffles.background.backdrop.useMainWallpaper", false);
                    Config.setNestedValue("waffles.background.backdrop.wallpaperPath", normalizedPath);
                    // Generate and set thumbnail for video/GIF
                    if (needsThumbnail) {
                        Wallpapers.generateThumbnail("large");
                        const thumbnailPath = Wallpapers.getExpectedThumbnailPath(normalizedPath, "large");
                        Config.setNestedValue("waffles.background.backdrop.thumbnailPath", thumbnailPath);
                    }
                    break;
                default: // "main"
                    Wallpapers.select(normalizedPath, root.useDarkMode, root.selectedMonitor);
                    break;
            }
            // Reset GlobalStates only (Config resets on its own via defaults)
            GlobalStates.wallpaperSelectionTarget = "main";
            filterField.text = "";
            GlobalStates.wallpaperSelectorOpen = false;
        }
    }

    acceptedButtons: Qt.LeftButton | Qt.BackButton | Qt.ForwardButton

    onClicked: mouse => {
        const localPos = mapToItem(wallpaperGridBackground, mouse.x, mouse.y);
        const outside = (localPos.x < 0 || localPos.x > wallpaperGridBackground.width
                || localPos.y < 0 || localPos.y > wallpaperGridBackground.height);
        if (outside) {
            GlobalStates.wallpaperSelectorOpen = false;
        } else {
            mouse.accepted = false;
        }
    }

    onPressed: event => {
        if (event.button === Qt.BackButton) {
            Wallpapers.navigateBack();
        } else if (event.button === Qt.ForwardButton) {
            Wallpapers.navigateForward();
        } else {
            event.accepted = false;
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            GlobalStates.wallpaperSelectorOpen = false;
            event.accepted = true;
        } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_V) { // Intercept Ctrl+V to handle "paste to go to" in pickers
            root.handleFilePasting(event);
        } else if (event.modifiers & Qt.AltModifier && event.key === Qt.Key_Up) {
            Wallpapers.navigateUp();
            event.accepted = true;
        } else if (event.modifiers & Qt.AltModifier && event.key === Qt.Key_Left) {
            Wallpapers.navigateBack();
            event.accepted = true;
        } else if (event.modifiers & Qt.AltModifier && event.key === Qt.Key_Right) {
            Wallpapers.navigateForward();
            event.accepted = true;
        } else if (event.key === Qt.Key_Left) {
            const g = root.weMode ? weGrid : grid
            g.moveSelection(-1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Right) {
            const g = root.weMode ? weGrid : grid
            g.moveSelection(1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            const g = root.weMode ? weGrid : grid
            g.moveSelection(-root.columns);
            event.accepted = true;
        } else if (event.key === Qt.Key_Down) {
            const g = root.weMode ? weGrid : grid
            g.moveSelection(root.columns);
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (root.weMode) {
                const w = root.weFilteredWallpapers[weGrid.currentIndex]
                if (w) root.applyWEWallpaper(w.id)
            } else {
                grid.activateCurrent();
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Backspace) {
            if (filterField.text.length > 0) {
                filterField.text = filterField.text.substring(0, filterField.text.length - 1);
            }
            filterField.forceActiveFocus();
            event.accepted = true;
        } else if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_L) {
            addressBar.focusBreadcrumb();
            event.accepted = true;
        } else if (event.key === Qt.Key_Slash) {
            filterField.forceActiveFocus();
            event.accepted = true;
        } else {
            if (event.text.length > 0) {
                filterField.text += event.text;
                filterField.cursorPosition = filterField.text.length;
                filterField.forceActiveFocus();
            }
            event.accepted = true;
        }
    }

    implicitHeight: mainLayout.implicitHeight
    implicitWidth: mainLayout.implicitWidth

    StyledRectangularShadow {
        target: wallpaperGridBackground
        visible: !Appearance.inirEverywhere
    }
    GlassBackground {
        id: wallpaperGridBackground
        anchors {
            fill: parent
            margins: Appearance.sizes.elevationMargin
        }
        focus: true
        Keys.forwardTo: [root]
        border.width: (Appearance.inirEverywhere || Appearance.auroraEverywhere) ? 1 : 1
        border.color: Appearance.angelEverywhere ? Appearance.angel.colCardBorder
            : Appearance.inirEverywhere ? Appearance.inir.colBorder 
            : Appearance.auroraEverywhere ? Appearance.aurora.colTooltipBorder : Appearance.colors.colLayer0Border
        fallbackColor: Appearance.colors.colLayer0
        inirColor: Appearance.inir.colLayer0
        auroraTransparency: Appearance.aurora.overlayTransparentize
        radius: Appearance.angelEverywhere ? Appearance.angel.roundingLarge
            : Appearance.inirEverywhere ? Appearance.inir.roundingLarge 
            : (Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1)

        property int calculatedRows: Math.ceil(grid.count / grid.columns)

        implicitWidth: gridColumnLayout.implicitWidth
        implicitHeight: gridColumnLayout.implicitHeight

        RowLayout {
            id: mainLayout
            anchors.fill: parent
            spacing: -4

            Rectangle {
                Layout.fillHeight: true
                Layout.margins: 4
                implicitWidth: quickDirColumnLayout.implicitWidth
                implicitHeight: quickDirColumnLayout.implicitHeight
                color: Appearance.angelEverywhere ? Appearance.angel.colGlassCard
                    : Appearance.inirEverywhere ? Appearance.inir.colLayer1
                    : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurface : Appearance.colors.colLayer1
                radius: wallpaperGridBackground.radius - Layout.margins

                ColumnLayout {
                    id: quickDirColumnLayout
                    anchors.fill: parent
                    spacing: 0

                    StyledText {
                        Layout.margins: 12
                        font {
                            pixelSize: Appearance.font.pixelSize.normal
                            weight: Font.Medium
                        }
                        text: Translation.tr("Pick a wallpaper")
                    }
                    ListView {
                        // Quick dirs
                        Layout.fillHeight: true
                        Layout.margins: 4
                        implicitWidth: 140
                        clip: true
                        model: [
                            { icon: "home", name: "Home", path: Directories.home }, 
                            { icon: "docs", name: "Documents", path: Directories.documents }, 
                            { icon: "download", name: "Downloads", path: Directories.downloads }, 
                            { icon: "image", name: "Pictures", path: Directories.pictures }, 
                            { icon: "movie", name: "Videos", path: Directories.videos }, 
                            { icon: "", name: "---", path: "INTENTIONALLY_INVALID_DIR" }, 
                            { icon: "wallpaper", name: "Wallpapers", path: `${Directories.pictures}/Wallpapers` },
                            ...((Config.options?.policies?.weeb ?? 0) === 1 ? [{ icon: "favorite", name: "Homework", path: `${Directories.pictures}/homework` }] : []),
                            { icon: "", name: "---", path: "INTENTIONALLY_INVALID_DIR" },
                            { icon: "animated_images", name: "WE", path: "__WE__" },
                        ]
                        delegate: RippleButton {
                            id: quickDirButton
                            required property var modelData
                            anchors {
                                left: parent.left
                                right: parent.right
                            }
                            onClicked: {
                                filterField.text = ""
                                if (quickDirButton.modelData.path === "__WE__") {
                                    root.weMode = true
                                    root.loadWEWallpapers()
                                } else {
                                    root.weMode = false
                                    Wallpapers.setDirectory(quickDirButton.modelData.path)
                                }
                            }
                            enabled: modelData.icon.length > 0
                            toggled: modelData.path === "__WE__" ? root.weMode : (!root.weMode && Wallpapers.directory === Qt.resolvedUrl(modelData.path))
                            colBackgroundToggled: Appearance.colors.colSecondaryContainer
                            colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                            colRippleToggled: Appearance.colors.colSecondaryContainerActive
                            buttonRadius: height / 2
                            implicitHeight: 38

                            contentItem: RowLayout {
                                MaterialSymbol {
                                    color: quickDirButton.toggled ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
                                    iconSize: Appearance.font.pixelSize.larger
                                    text: quickDirButton.modelData.icon
                                    fill: quickDirButton.toggled ? 1 : 0
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignLeft
                                    color: quickDirButton.toggled ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
                                    text: quickDirButton.modelData.name
                                }
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                id: gridColumnLayout
                Layout.fillWidth: true
                Layout.fillHeight: true

                AddressBar {
                    id: addressBar
                    visible: !root.weMode
                    Layout.margins: 4
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    directory: Wallpapers.effectiveDirectory
                    onNavigateToDirectory: path => {
                        Wallpapers.setDirectory(path.length == 0 ? "/" : path);
                    }
                    radius: wallpaperGridBackground.radius - Layout.margins
                }

                // WE mode header
                Rectangle {
                    visible: root.weMode
                    Layout.margins: 4
                    Layout.fillWidth: true
                    implicitHeight: visible ? weHeaderContent.implicitHeight + 16 : 0
                    color: Appearance.angelEverywhere ? Appearance.angel.colGlassCard
                        : Appearance.inirEverywhere ? Appearance.inir.colLayer1
                        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurface
                        : Appearance.colors.colLayer1
                    radius: wallpaperGridBackground.radius - Layout.margins

                    RowLayout {
                        id: weHeaderContent
                        anchors {
                            fill: parent
                            margins: 8
                        }
                        spacing: Appearance.sizes.spacingSmall

                        MaterialSymbol {
                            text: "animated_images"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colPrimary
                        }

                        StyledText {
                            text: Translation.tr("Wallpaper Engine") + ` (${root.weFilteredWallpapers.length})`
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colPrimary
                        }

                        Item { Layout.fillWidth: true }

                        StyledText {
                            visible: root.weCurrentId.length > 0
                            text: {
                                const active = root.weWallpapers.find(w => w.id === root.weCurrentId)
                                return active ? Translation.tr("Active: %1").arg(active.title) : ""
                            }
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnSurfaceVariant
                            elide: Text.ElideRight
                            Layout.maximumWidth: 300
                        }
                    }
                }

                // Multi-monitor indicator
                Rectangle {
                    visible: Config.options?.background?.multiMonitor?.enable ?? false
                    Layout.fillWidth: true
                    Layout.margins: 4
                    Layout.topMargin: 0
                    implicitHeight: visible ? monitorIndicatorText.implicitHeight + 16 : 0
                    color: Appearance.inirEverywhere ? Appearance.inir.colLayer1
                        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurface
                        : Appearance.colors.colLayer1
                    radius: wallpaperGridBackground.radius - Layout.margins
                    border.width: Appearance.inirEverywhere ? 1 : 0
                    border.color: Appearance.inirEverywhere ? Appearance.inir.colBorder : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Appearance.sizes.spacingSmall
                        spacing: Appearance.sizes.spacingSmall

                        MaterialSymbol {
                            text: "monitor"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colPrimary
                        }

                        StyledText {
                            id: monitorIndicatorText
                            Layout.fillWidth: true
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Medium
                            text: root.selectedMonitor ?
                                Translation.tr("Configuring monitor: %1").arg(root.selectedMonitor) :
                                Translation.tr("Multi-monitor mode active")
                            color: Appearance.colors.colPrimary
                        }
                    }
                }

                Item {
                    id: gridDisplayRegion
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    StyledIndeterminateProgressBar {
                        id: indeterminateProgressBar
                        visible: !root.weMode && Wallpapers.thumbnailGenerationRunning && value == 0
                        anchors {
                            bottom: parent.top
                            left: parent.left
                            right: parent.right
                            leftMargin: 4
                            rightMargin: 4
                        }
                    }

                    StyledProgressBar {
                        visible: !root.weMode && Wallpapers.thumbnailGenerationRunning && value > 0
                        value: Wallpapers.thumbnailGenerationProgress
                        anchors.fill: indeterminateProgressBar
                    }

                    GridView {
                        id: grid
                        visible: !root.weMode && Wallpapers.folderModel.count > 0

                        readonly property int columns: root.columns
                        readonly property int rows: Math.max(1, Math.ceil(count / columns))
                        property int currentIndex: 0

                        anchors.fill: parent
                        cellWidth: width / root.columns
                        cellHeight: cellWidth / root.previewCellAspectRatio
                        interactive: true
                        clip: true
                        keyNavigationWraps: true
                        boundsBehavior: Flickable.StopAtBounds
                        bottomMargin: extraOptions.implicitHeight
                        ScrollBar.vertical: StyledScrollBar {}

                        Component.onCompleted: {
                            root.updateThumbnails()
                        }

                        function moveSelection(delta) {
                            currentIndex = Math.max(0, Math.min(grid.model.count - 1, currentIndex + delta));
                            positionViewAtIndex(currentIndex, GridView.Contain);
                        }

                        function activateCurrent() {
                            const filePath = grid.model.get(currentIndex, "filePath")
                            const isDir = grid.model.get(currentIndex, "fileIsDir")
                            if (isDir) {
                                Wallpapers.setDirectory(filePath);
                            } else {
                                root.selectWallpaperPath(filePath);
                            }
                        }

                        model: Wallpapers.folderModel
                        onModelChanged: currentIndex = 0
                        delegate: WallpaperDirectoryItem {
                            required property int index
                            required property string filePath
                            required property string fileName
                            required property bool fileIsDir
                            required property url fileUrl
                            
                            fileModelData: ({
                                filePath: filePath,
                                fileName: fileName,
                                fileIsDir: fileIsDir,
                                fileUrl: fileUrl
                            })
                            width: grid.cellWidth
                            height: grid.cellHeight
                            colBackground: (index === grid?.currentIndex || containsMouse) ? Appearance.colors.colPrimary : (filePath === (Config.options?.background?.wallpaperPath ?? "")) ? Appearance.colors.colSecondaryContainer : ColorUtils.transparentize(Appearance.colors.colPrimaryContainer)
                            colText: (index === grid.currentIndex || containsMouse) ? Appearance.colors.colOnPrimary : (filePath === (Config.options?.background?.wallpaperPath ?? "")) ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer0

                            onEntered: {
                                grid.currentIndex = index;
                            }
                            
                            onActivated: {
                                if (fileIsDir) {
                                    Wallpapers.setDirectory(filePath);
                                } else {
                                    root.selectWallpaperPath(filePath);
                                }
                            }
                        }

                        layer.enabled: true
                        layer.effect: GE.OpacityMask {
                            maskSource: Rectangle {
                                width: gridDisplayRegion.width
                                height: gridDisplayRegion.height
                                radius: wallpaperGridBackground.radius
                            }
                        }
                    }

                    // ─── Wallpaper Engine grid ──────────────────────
                    GridView {
                        id: weGrid
                        visible: root.weMode
                        anchors.fill: parent
                        cellWidth: width / root.columns
                        cellHeight: cellWidth / root.previewCellAspectRatio
                        interactive: true
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        bottomMargin: extraOptions.implicitHeight
                        ScrollBar.vertical: StyledScrollBar {}

                        property int currentIndex: 0

                        function moveSelection(delta) {
                            currentIndex = Math.max(0, Math.min(model.length - 1, currentIndex + delta))
                            positionViewAtIndex(currentIndex, GridView.Contain)
                        }

                        model: root.weFilteredWallpapers

                        delegate: WEWallpaperItem {
                            required property int index
                            required property var modelData

                            weData: modelData
                            width: weGrid.cellWidth
                            height: weGrid.cellHeight
                            colBackground: (index === weGrid.currentIndex || containsMouse)
                                ? Appearance.colors.colPrimary
                                : (modelData.id === root.weCurrentId)
                                    ? Appearance.colors.colSecondaryContainer
                                    : ColorUtils.transparentize(Appearance.colors.colPrimaryContainer)
                            colText: (index === weGrid.currentIndex || containsMouse)
                                ? Appearance.colors.colOnPrimary
                                : (modelData.id === root.weCurrentId)
                                    ? Appearance.colors.colOnSecondaryContainer
                                    : Appearance.colors.colOnLayer0

                            onEntered: weGrid.currentIndex = index
                            onActivated: root.applyWEWallpaper(modelData.id)
                        }

                        layer.enabled: true
                        layer.effect: GE.OpacityMask {
                            maskSource: Rectangle {
                                width: gridDisplayRegion.width
                                height: gridDisplayRegion.height
                                radius: wallpaperGridBackground.radius
                            }
                        }
                    }

                    Toolbar {
                        id: extraOptions
                        anchors {
                            bottom: parent.bottom
                            horizontalCenter: parent.horizontalCenter
                            bottomMargin: 8
                        }
                        
                        // Calculate screen position for aurora blur
                        screenX: {
                            const mapped = extraOptions.mapToGlobal(0, 0)
                            return mapped.x
                        }
                        screenY: {
                            const mapped = extraOptions.mapToGlobal(0, 0)
                            return mapped.y
                        }

                        // ─── Normal mode buttons ────────────────
                        IconToolbarButton {
                            visible: !root.weMode
                            implicitWidth: height
                            onClicked: {
                                Wallpapers.openFallbackPicker(root.useDarkMode);
                                GlobalStates.wallpaperSelectorOpen = false;
                            }
                            altAction: () => {
                                Wallpapers.openFallbackPicker(root.useDarkMode);
                                GlobalStates.wallpaperSelectorOpen = false;
                                Config.setNestedValue("wallpaperSelector.useSystemFileDialog", true)
                            }
                            text: "open_in_new"
                            StyledToolTip {
                                text: Translation.tr("Use the system file picker instead\nRight-click to make this the default behavior")
                            }
                        }

                        IconToolbarButton {
                            visible: !root.weMode
                            implicitWidth: height
                            onClicked: {
                                Wallpapers.randomFromCurrentFolder();
                            }
                            text: "ifl"
                            StyledToolTip {
                                text: Translation.tr("Pick random from this folder")
                            }
                        }

                        IconToolbarButton {
                            visible: !root.weMode
                            implicitWidth: height
                            onClicked: root.useDarkMode = !root.useDarkMode
                            text: root.useDarkMode ? "dark_mode" : "light_mode"
                            StyledToolTip {
                                text: Translation.tr("Click to toggle light/dark mode\n(applied when wallpaper is chosen)")
                            }
                        }

                        // ─── WE mode buttons ────────────────────
                        IconToolbarButton {
                            visible: root.weMode
                            implicitWidth: height
                            onClicked: root.applyRandomWE()
                            text: "shuffle"
                            StyledToolTip {
                                text: Translation.tr("Random Wallpaper Engine wallpaper")
                            }
                        }

                        IconToolbarButton {
                            visible: root.weMode && root.weCurrentId.length > 0
                            implicitWidth: height
                            onClicked: root.stopWEWallpaper()
                            text: "stop_circle"
                            StyledToolTip {
                                text: Translation.tr("Stop Wallpaper Engine and restore normal wallpaper")
                            }
                        }

                        IconToolbarButton {
                            visible: root.weMode
                            implicitWidth: height
                            onClicked: root.loadWEWallpapers()
                            text: "refresh"
                            StyledToolTip {
                                text: Translation.tr("Reload Wallpaper Engine library")
                            }
                        }

                        ToolbarTextField {
                            id: filterField
                            placeholderText: focus ? Translation.tr("Search wallpapers") : Translation.tr("Hit \"/\" to search")

                            // Style
                            clip: true
                            font.pixelSize: Appearance.font.pixelSize.small

                            // Search
                            onTextChanged: {
                                if (root.weMode) {
                                    root.weFilterText = text
                                } else {
                                    Wallpapers.searchQuery = text;
                                }
                            }

                            Keys.onPressed: event => {
                                if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_V) { // Intercept Ctrl+V to handle "paste to go to" in pickers
                                    root.handleFilePasting(event);
                                    return;
                                }
                                else if (text.length !== 0) {
                                    // No filtering, just navigate grid
                                    if (event.key === Qt.Key_Down) {
                                        grid.moveSelection(grid.columns);
                                        event.accepted = true;
                                        return;
                                    }
                                    if (event.key === Qt.Key_Up) {
                                        grid.moveSelection(-grid.columns);
                                        event.accepted = true;
                                        return;
                                    }
                                }
                                event.accepted = false;
                            }
                        }

                        IconToolbarButton {
                            implicitWidth: height
                            onClicked: {
                                GlobalStates.wallpaperSelectorOpen = false;
                            }
                            text: "close"
                            StyledToolTip {
                                text: Translation.tr("Cancel wallpaper selection")
                            }
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: GlobalStates
        function onWallpaperSelectorOpenChanged() {
            if (GlobalStates.wallpaperSelectorOpen && monitorIsFocused) {
                filterField.forceActiveFocus();
            }
        }
    }

    Connections {
        target: Wallpapers
        function onChanged() {
            GlobalStates.wallpaperSelectorOpen = false;
        }
    }
}
