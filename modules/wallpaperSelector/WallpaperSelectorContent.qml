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
    readonly property real _dpr: root.window ? root.window.devicePixelRatio : 1

    // Multi-monitor support — capture focused monitor at open time
    property string _lockedTarget: ""
    property string _capturedMonitor: ""
    readonly property bool multiMonitorActive: Config.options?.background?.multiMonitor?.enable ?? false

    readonly property string selectedMonitor: {
        if (!multiMonitorActive) return ""
        if (_lockedTarget) return _lockedTarget
        return _capturedMonitor
    }
    readonly property string currentSelectionTarget: Wallpapers.currentSelectionTarget()
    readonly property string currentSelectionPath: Wallpapers.currentWallpaperPathForTarget(currentSelectionTarget, selectedMonitor)

    // ─── Color filter system ─────────────────────────────
    property string _colorFilter: "" // empty = no filter, or bucket name like "blue"
    property var _colorCache: ({}) // { "/path/file.jpg": { hue, sat, lum, bucket } }
    property bool _colorAnalysisRunning: false
    readonly property string _colorCachePath: {
        const xdg = Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")
        return xdg + "/quickshell/wallpaper-colors.json"
    }
    readonly property string _colorAnalysisScript: `${FileUtils.trimFileProtocol(Directories.scriptPath)}/colors/analyze-wallpaper-colors.py`

    readonly property var _colorBuckets: [
        { name: "red",     color: "#E53935" },
        { name: "orange",  color: "#FB8C00" },
        { name: "yellow",  color: "#FDD835" },
        { name: "lime",    color: "#7CB342" },
        { name: "green",   color: "#43A047" },
        { name: "teal",    color: "#00897B" },
        { name: "cyan",    color: "#00ACC1" },
        { name: "blue",    color: "#1E88E5" },
        { name: "indigo",  color: "#5E35B1" },
        { name: "violet",  color: "#8E24AA" },
        { name: "pink",    color: "#D81B60" },
        { name: "neutral", color: "#78909C" },
    ]

    function _loadColorCache() {
        _colorLoadProc._buf = ""
        _colorLoadProc.command = ["cat", root._colorCachePath]
        _colorLoadProc.running = true
    }

    function _runColorAnalysis() {
        if (root._colorAnalysisRunning) return
        const dir = Wallpapers.effectiveDirectory
        if (!dir) return
        root._colorAnalysisRunning = true
        _colorAnalyzeProc.command = ["python3", root._colorAnalysisScript, dir, "--json-output"]
        _colorAnalyzeProc.running = true
    }

    function _bucketCount(bucketName: string): int {
        const dir = Wallpapers.effectiveDirectory
        let count = 0
        for (const path in root._colorCache) {
            if (path.startsWith(dir + "/") && root._colorCache[path].bucket === bucketName)
                count++
        }
        return count
    }

    function _rebuildFilteredModel() {
        _filteredModel.clear()
        if (root._colorFilter.length === 0) return
        const src = Wallpapers.folderModel
        const total = src.count
        for (let i = 0; i < total; i++) {
            const filePath = src.get(i, "filePath")
            const fileIsDir = src.get(i, "fileIsDir")
            // Always include directories so navigation still works
            if (fileIsDir) {
                _filteredModel.append({
                    filePath: String(filePath),
                    fileName: String(src.get(i, "fileName")),
                    fileIsDir: true,
                    fileUrl: String(src.get(i, "fileUrl") || src.get(i, "fileURL") || "")
                })
                continue
            }
            const entry = root._colorCache[filePath]
            if (entry && entry.bucket === root._colorFilter) {
                _filteredModel.append({
                    filePath: String(filePath),
                    fileName: String(src.get(i, "fileName")),
                    fileIsDir: false,
                    fileUrl: String(src.get(i, "fileUrl") || src.get(i, "fileURL") || "")
                })
            }
        }
    }

    ListModel { id: _filteredModel }

    // ─── Wallpaper Engine mode ─────────────────────────────
    property bool _weMode: false
    property var weWallpapers: []
    property string weCurrentId: ""
    property bool _weLoaded: false

    Process {
        id: _weListProc
        property string _buf: ""
        stdout: SplitParser {
            onRead: data => { _weListProc._buf += data }
        }
        onExited: (exitCode) => {
            if (exitCode === 0 && _weListProc._buf.length > 0) {
                try {
                    root.weWallpapers = JSON.parse(_weListProc._buf)
                    const active = root.weWallpapers.find(w => w.active)
                    root.weCurrentId = active ? active.id : ""
                    root._weLoaded = true
                } catch(e) { root.weWallpapers = [] }
            }
            _weListProc._buf = ""
        }
    }

    function loadWEWallpapers() {
        _weListProc._buf = ""
        _weListProc.command = ["we-wall", "--list-json"]
        _weListProc.running = true
    }

    function applyWEWallpaper(wallpaperId) {
        Quickshell.execDetached(["we-wall", wallpaperId])
        GlobalStates.wallpaperSelectorOpen = false
    }

    function stopWEWallpaper() {
        Quickshell.execDetached(["we-wall", "--stop"])
        root.weCurrentId = ""
    }

    Process {
        id: _colorLoadProc
        property string _buf: ""
        stdout: SplitParser {
            onRead: data => { _colorLoadProc._buf += data }
        }
        onExited: (exitCode) => {
            if (exitCode === 0 && _colorLoadProc._buf.length > 0) {
                try {
                    root._colorCache = JSON.parse(_colorLoadProc._buf)
                } catch(e) { root._colorCache = {} }
            }
            _colorLoadProc._buf = ""
            if (root._colorFilter.length > 0) root._rebuildFilteredModel()
        }
    }

    Process {
        id: _colorAnalyzeProc
        property string _buf: ""
        stdout: SplitParser {
            onRead: data => {
                if (data.startsWith("PROGRESS ")) return
                _colorAnalyzeProc._buf += data
            }
        }
        onExited: (exitCode) => {
            root._colorAnalysisRunning = false
            if (exitCode === 0 && _colorAnalyzeProc._buf.length > 0) {
                try {
                    const newData = JSON.parse(_colorAnalyzeProc._buf)
                    root._colorCache = Object.assign({}, root._colorCache, newData)
                } catch(e) { /* parse error, ignore */ }
            }
            _colorAnalyzeProc._buf = ""
            if (root._colorFilter.length > 0) root._rebuildFilteredModel()
        }
    }

    Timer {
        id: _colorAnalysisDebounce
        interval: 1000
        onTriggered: root._runColorAnalysis()
    }

    Timer {
        id: _filterRebuildDebounce
        interval: 150
        onTriggered: root._rebuildFilteredModel()
    }

    Connections {
        target: Wallpapers
        function onFolderChanged() {
            _colorAnalysisDebounce.restart()
            if (root._colorFilter.length > 0) _filterRebuildDebounce.restart()
        }
    }

    Connections {
        target: Wallpapers.folderModel
        function onCountChanged() {
            if (root._colorFilter.length > 0) _filterRebuildDebounce.restart()
        }
    }

    // Trigger rebuild whenever _colorFilter changes (via property observer)
    Item {
        id: _colorFilterObserver
        property string tracked: root._colorFilter
        onTrackedChanged: root._rebuildFilteredModel()
    }

    function syncDirectoryToCurrentSelection() {
        const currentPath = FileUtils.trimFileProtocol(String(root.currentSelectionPath ?? ""))
        const currentDir = FileUtils.parentDirectory(currentPath)
        if (currentDir && currentDir.length > 0)
            Wallpapers.setDirectory(currentDir)
    }

    Component.onCompleted: {
        // Read target monitor from GlobalStates (set before opening, no timing issues)
        const gsTarget = GlobalStates.wallpaperSelectorTargetMonitor ?? ""
        if (gsTarget && WallpaperListener.screenNames.includes(gsTarget)) {
            _lockedTarget = gsTarget
        } else {
            // Fallback: check Config (for settings UI "Change" button via IPC)
            const configTarget = Config.options?.wallpaperSelector?.targetMonitor ?? ""
            if (configTarget && WallpaperListener.screenNames.includes(configTarget)) {
                _lockedTarget = configTarget
            } else if (CompositorService.isNiri) {
                // Last resort: capture focused monitor (may be stale if overlay already took focus)
                _capturedMonitor = NiriService.currentOutput ?? ""
            } else if (CompositorService.isHyprland) {
                _capturedMonitor = Hyprland.focusedMonitor?.name ?? ""
            }
        }
        root._loadColorCache()
        Qt.callLater(() => {
            Wallpapers.searchQuery = ""
            root.syncDirectoryToCurrentSelection()
            root.updateThumbnails()
            _colorAnalysisDebounce.restart()
        })
    }

    function updateThumbnails() {
        const totalImageMargin = (Appearance.sizes.wallpaperSelectorItemMargins + Appearance.sizes.wallpaperSelectorItemPadding) * 2
        let thumbnailSizeName = Images.thumbnailSizeNameForDimensions(
            Math.round((grid.cellWidth - totalImageMargin) * root._dpr),
            Math.round((grid.cellHeight - totalImageMargin) * root._dpr)
        )
        // Force at least x-large (512px) for crisp grid thumbnails
        if (thumbnailSizeName === "normal" || thumbnailSizeName === "large")
            thumbnailSizeName = "x-large"
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
            Wallpapers.applySelectionTarget(normalizedPath, Wallpapers.currentSelectionTarget(), root.useDarkMode, root.selectedMonitor);
            Config.setNestedValue("wallpaperSelector.selectionTarget", "main")
            Config.setNestedValue("wallpaperSelector.targetMonitor", "")
            GlobalStates.wallpaperSelectionTarget = "main";
            GlobalStates.wallpaperSelectorTargetMonitor = "";
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
            grid.moveSelection(-1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Right) {
            grid.moveSelection(1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            grid.moveSelection(-grid.columns);
            event.accepted = true;
        } else if (event.key === Qt.Key_Down) {
            grid.moveSelection(grid.columns);
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            grid.activateCurrent();
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
                        ]
                        delegate: RippleButton {
                            id: quickDirButton
                            required property var modelData
                            anchors {
                                left: parent.left
                                right: parent.right
                            }
                            onClicked: Wallpapers.setDirectory(quickDirButton.modelData.path)
                            enabled: modelData.icon.length > 0
                            toggled: Wallpapers.directory === Qt.resolvedUrl(modelData.path)
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
                    Layout.margins: 4
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    directory: Wallpapers.effectiveDirectory
                    onNavigateToDirectory: path => {
                        Wallpapers.setDirectory(path.length == 0 ? "/" : path);
                    }
                    radius: wallpaperGridBackground.radius - Layout.margins
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
                        visible: Wallpapers.thumbnailGenerationRunning && value == 0
                        anchors {
                            bottom: parent.top
                            left: parent.left
                            right: parent.right
                            leftMargin: 4
                            rightMargin: 4
                        }
                    }

                    StyledProgressBar {
                        visible: Wallpapers.thumbnailGenerationRunning && value > 0
                        value: Wallpapers.thumbnailGenerationProgress
                        anchors.fill: indeterminateProgressBar
                    }

                    GridView {
                        id: grid
                        visible: !root._weMode && Wallpapers.folderModel.count > 0

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

                        model: root._colorFilter.length > 0 ? _filteredModel : Wallpapers.folderModel
                        onModelChanged: currentIndex = 0
                        delegate: WallpaperDirectoryItem {
                            required property int index
                            required property string filePath
                            required property string fileName
                            required property bool fileIsDir
                            required property url fileUrl

                            // Compute once; avoids two separate Wallpapers.isCurrentWallpaperPath
                            // calls per binding re-evaluation (colBackground + colText).
                            readonly property bool _isCurrent: Wallpapers.isCurrentWallpaperPath(filePath, root.currentSelectionTarget, root.selectedMonitor)

                            fileModelData: ({
                                filePath: filePath,
                                fileName: fileName,
                                fileIsDir: fileIsDir,
                                fileUrl: fileUrl
                            })
                            width: grid.cellWidth
                            height: grid.cellHeight
                            colBackground: (index === grid?.currentIndex || containsMouse) ? Appearance.colors.colPrimary : _isCurrent ? Appearance.colors.colSecondaryContainer : ColorUtils.transparentize(Appearance.colors.colPrimaryContainer)
                            colText: (index === grid.currentIndex || containsMouse) ? Appearance.colors.colOnPrimary : _isCurrent ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer0

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
                        visible: root._weMode
                        anchors.fill: parent
                        cellWidth: width / root.columns
                        cellHeight: cellWidth / root.previewCellAspectRatio
                        interactive: true
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        bottomMargin: extraOptions.implicitHeight
                        ScrollBar.vertical: StyledScrollBar {}

                        property int currentIndex: 0

                        model: root.weWallpapers

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

                    // Empty-state hint for WE mode
                    StyledText {
                        visible: root._weMode && root._weLoaded && root.weWallpapers.length === 0
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        color: Appearance.colors.colOnSurfaceVariant
                        text: Translation.tr("No Wallpaper Engine wallpapers found.\nSubscribe to some via Steam Workshop, then reload.")
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

                        IconToolbarButton {
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
                            visible: !root._weMode
                            implicitWidth: height
                            onClicked: {
                                Wallpapers.randomFromCurrentFolder(root.useDarkMode);
                            }
                            text: "ifl"
                            StyledToolTip {
                                text: Translation.tr("Pick random from this folder")
                            }
                        }

                        // ─── Wallpaper Engine toggle ──────────
                        IconToolbarButton {
                            implicitWidth: height
                            toggled: root._weMode
                            onClicked: {
                                root._weMode = !root._weMode
                                if (root._weMode && !root._weLoaded) {
                                    root.loadWEWallpapers()
                                }
                            }
                            text: "animation"
                            StyledToolTip {
                                text: Translation.tr("Toggle Wallpaper Engine library")
                            }
                        }

                        // ─── WE mode controls (visible only in WE mode) ──
                        IconToolbarButton {
                            visible: root._weMode
                            implicitWidth: height
                            onClicked: root.loadWEWallpapers()
                            text: "refresh"
                            StyledToolTip {
                                text: Translation.tr("Reload Wallpaper Engine library")
                            }
                        }

                        IconToolbarButton {
                            visible: root._weMode && root.weCurrentId.length > 0
                            implicitWidth: height
                            onClicked: root.stopWEWallpaper()
                            text: "stop_circle"
                            StyledToolTip {
                                text: Translation.tr("Stop Wallpaper Engine and restore normal wallpaper")
                            }
                        }

                        IconToolbarButton {
                            implicitWidth: height
                            onClicked: {
                                root.useDarkMode = !root.useDarkMode
                                MaterialThemeLoader.setDarkMode(root.useDarkMode)
                            }
                            text: root.useDarkMode ? "dark_mode" : "light_mode"
                            StyledToolTip {
                                text: Translation.tr("Click to toggle light/dark mode\n(applied when wallpaper is chosen)")
                            }
                        }

                        // ─── Color filter chips ───────────────
                        Row {
                            id: colorDotsRow
                            spacing: 5
                            Layout.alignment: Qt.AlignVCenter
                            Layout.leftMargin: 4

                            MaterialSymbol {
                                anchors.verticalCenter: parent.verticalCenter
                                iconSize: 18
                                text: root._colorAnalysisRunning ? "hourglass_empty" : "palette"
                                color: Appearance.colors.colOnSurfaceVariant
                            }

                            Repeater {
                                model: root._colorBuckets
                                delegate: MouseArea {
                                    required property var modelData
                                    required property int index
                                    property bool hovered: containsMouse
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 26
                                    height: 26
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: {
                                        if (root._colorFilter === modelData.name)
                                            root._colorFilter = ""
                                        else
                                            root._colorFilter = modelData.name
                                    }

                                    Rectangle {
                                        id: dot
                                        anchors.centerIn: parent
                                        width: root._colorFilter === parent.modelData.name ? 22 : (parent.containsMouse ? 20 : 16)
                                        height: width
                                        radius: width / 2
                                        color: parent.modelData.color
                                        opacity: (root._colorFilter.length === 0 || root._colorFilter === parent.modelData.name) ? 1.0 : 0.45

                                        Behavior on width {
                                            NumberAnimation { duration: 120 }
                                        }
                                        Behavior on opacity {
                                            NumberAnimation { duration: 120 }
                                        }
                                    }

                                    Rectangle {
                                        visible: root._colorFilter === parent.modelData.name
                                        anchors.centerIn: parent
                                        width: dot.width + 4
                                        height: width
                                        radius: width / 2
                                        color: "transparent"
                                        border.width: 2
                                        border.color: Appearance.colors.colOnSurface
                                    }

                                    StyledToolTip {
                                        text: {
                                            const name = parent.modelData.name
                                            const count = root._bucketCount(name)
                                            return name.charAt(0).toUpperCase() + name.slice(1) + ` (${count})`
                                        }
                                    }
                                }
                            }
                        }

                        IconToolbarButton {
                            implicitWidth: height
                            visible: root._colorFilter.length > 0
                            onClicked: root._colorFilter = ""
                            text: "filter_alt_off"
                            StyledToolTip {
                                text: Translation.tr("Clear color filter")
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
                                Wallpapers.searchQuery = text;
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
                                GlobalStates.wallpaperSelectorOpen = false
                                Config.setNestedValue("wallpaperSelector.style", "coverflow")
                                GlobalStates.coverflowSelectorOpen = true
                            }
                            text: "view_carousel"
                            StyledToolTip {
                                text: Translation.tr("Switch to coverflow view")
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
            if (GlobalStates.wallpaperSelectorOpen) {
                Wallpapers.searchQuery = ""
                Qt.callLater(() => {
                    root.syncDirectoryToCurrentSelection()
                    root.updateThumbnails()
                })
                if (monitorIsFocused) {
                    filterField.forceActiveFocus();
                }
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
