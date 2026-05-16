pragma ComponentBehavior: Bound

import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

Scope {
    id: root

    readonly property int railWidth: 56
    readonly property int railPadding: 8
    readonly property int itemGap: 4
    readonly property int iconSize: Config.options?.dock?.railIconSize ?? 32
    readonly property int buttonSize: iconSize + 4
    readonly property var emptyList: []

    // Unity-style auto-hide state (shared across per-screen rails)
    // - Default visibility: only when current workspace has <= 1 window (auto-hide on crowd).
    // - Hotkey reveal: super+<key> → courierRail toggle; overlays without re-claiming space.
    // - Hotkey reset: workspace switch or focus change away from the captured focused window
    //   re-hides the hotkey overlay so the next reveal is intentional.
    property bool visibleByHotkey: false
    property int capturedFocusedWindowId: -1

    function _currentFocusedWindowId() {
        const wins = NiriService?.windows ?? []
        for (let i = 0; i < wins.length; i++) {
            if (wins[i]?.is_focused) return wins[i].id ?? -1
        }
        return -1
    }

    function toggleHotkey() {
        if (visibleByHotkey) {
            visibleByHotkey = false
            capturedFocusedWindowId = -1
        } else {
            visibleByHotkey = true
            capturedFocusedWindowId = _currentFocusedWindowId()
        }
    }

    function hideHotkey() {
        visibleByHotkey = false
        capturedFocusedWindowId = -1
    }

    // Reset hotkey reveal only on explicit workspace switch — focus-id tracking was
    // too eager (NiriService.onWindowsChanged fires on any window-state update, dismissing
    // the rail before user could interact). Per Ayaz: hotkey reveal sticks until toggled
    // off or workspace changes.
    Connections {
        target: NiriService
        function onFocusedWorkspaceIdChanged() {
            if (root.visibleByHotkey) root.hideHotkey()
        }
    }

    IpcHandler {
        target: "courierRail"
        function toggle(): void { root.toggleHotkey() }
        function show(): void {
            root.visibleByHotkey = true
            root.capturedFocusedWindowId = root._currentFocusedWindowId()
        }
        function hide(): void { root.hideHotkey() }
    }

    Variants {
        model: {
            const screens = Quickshell.screens
            const list = Config.options?.dock?.screenList ?? []
            if (!list || list.length === 0) return screens
            const matched = screens.filter(screen => {
                const name = screen?.name ?? ""
                return name.length > 0 && list.includes(name)
            })
            return matched.length > 0 ? matched : screens
        }

        Loader {
            id: screenLoader
            required property var modelData
            active: true

            sourceComponent: PanelWindow {
                id: railWindow
                screen: screenLoader.modelData
                color: "transparent"

                // --- Auto-hide derivation (per-screen) ---
                // windowsOnCurrentWorkspace: number of Niri windows on THIS screen's active workspace.
                // visibleByDefault: rail shows + claims exclusive zone only when the workspace has ≤ 1 window.
                // When more windows arrive the rail auto-hides; super+<key> hotkey reveals it as a non-reflowing overlay.
                property int workspaceWindowCount: 0
                readonly property bool visibleByDefault: workspaceWindowCount <= 1
                readonly property bool effectivelyVisible: !GlobalStates.screenLocked
                    && !GameMode.shouldHidePanels
                    && (visibleByDefault || root.visibleByHotkey)

                function recomputeWorkspaceWindowCount() {
                    if (!CompositorService.isNiri) { workspaceWindowCount = 0; return }
                    const screenName = railWindow.screen?.name ?? ""
                    const allWs = NiriService?.allWorkspaces ?? []
                    let activeWsId = null
                    for (let i = 0; i < allWs.length; i++) {
                        const ws = allWs[i]
                        if (ws?.output === screenName && ws?.is_active) { activeWsId = ws.id; break }
                    }
                    if (activeWsId === null) { workspaceWindowCount = 0; return }
                    const wins = NiriService?.windows ?? []
                    let n = 0
                    for (let j = 0; j < wins.length; j++) {
                        if (wins[j]?.workspace_id === activeWsId) n++
                    }
                    workspaceWindowCount = n
                }

                Connections {
                    target: NiriService
                    function onWindowsChanged() { railWindow.recomputeWorkspaceWindowCount() }
                    function onAllWorkspacesChanged() { railWindow.recomputeWorkspaceWindowCount() }
                    function onFocusedWorkspaceIdChanged() { railWindow.recomputeWorkspaceWindowCount() }
                }

                // Niri gap toggle: kill niri gaps when rail visible (single-window flush mode),
                // restore when hidden. Debounced 150ms to avoid thrash on rapid workspace switching.
                property bool _lastGapState: false
                Timer {
                    id: gapToggleDebounce
                    interval: 150
                    repeat: false
                    onTriggered: {
                        const wantGapOff = railWindow.effectivelyVisible
                        if (wantGapOff === railWindow._lastGapState) return
                        railWindow._lastGapState = wantGapOff
                        Quickshell.execDetached(["/home/ayaz/.local/bin/courier-rail-gap", wantGapOff ? "on" : "off"])
                    }
                }
                onEffectivelyVisibleChanged: gapToggleDebounce.restart()

                visible: effectivelyVisible
                anchors.left: true
                anchors.top: true
                anchors.bottom: true
                implicitWidth: root.railWidth
                WlrLayershell.namespace: "quickshell:courierrail"
                WlrLayershell.layer: WlrLayer.Top
                // Claim exclusive zone whenever rail is shown (default-visible OR hotkey reveal).
                // Per Ayaz: hotkey reveal should push the focused window right + kill gaps too.
                WlrLayershell.exclusiveZone: (GameMode.shouldHidePanels || !effectivelyVisible) ? 0 : root.railWidth

                property var dockItems: []
                property Item previewAnchorItem: null
                property var previewEntry: null
                property bool previewHovered: false
                property bool contextMenuOpen: false
                property var _lastGoodToplevels: []
                property var _cachedIgnoredRegexes: []
                property var _lastIgnoredRegexStrings: []

                Item { id: previewAnchorFallback; width: 1; height: 1 }

                readonly property var pinnedItems: dockItems.filter(item => item.section === "pinned")
                readonly property var runningItems: dockItems.filter(item => item.section === "running")
                readonly property bool showDivider: pinnedItems.length > 0 && runningItems.length > 0
                readonly property bool showEmpty: pinnedItems.length === 0 && runningItems.length === 0

                function getIgnoredRegexes() {
                    const ignored = Config.options?.dock?.ignoredAppRegexes ?? []
                    if (JSON.stringify(ignored) !== JSON.stringify(_lastIgnoredRegexStrings)) {
                        const systemIgnored = ["^$", "^portal$", "^x-run-dialog$", "^kdialog$", "^org.freedesktop.impl.portal.*"]
                        _cachedIgnoredRegexes = ignored.concat(systemIgnored).map(pattern => new RegExp(pattern, "i"))
                        _lastIgnoredRegexStrings = ignored.slice()
                    }
                    return _cachedIgnoredRegexes
                }

                function rebuildDockItems() {
                    const pinnedApps = Config.options?.dock?.pinnedApps ?? []
                    const ignoredRegexes = getIgnoredRegexes()

                    let allToplevels
                    if (CompositorService.sortedToplevels && CompositorService.sortedToplevels.length) {
                        allToplevels = CompositorService.sortedToplevels
                        _lastGoodToplevels = allToplevels
                    } else {
                        allToplevels = _lastGoodToplevels.length ? _lastGoodToplevels : ToplevelManager.toplevels.values
                    }

                    const dockScope = Config.options?.dock?.scope ?? "global"
                    if (dockScope === "workspace" && CompositorService.isNiri) {
                        const screenName = railWindow.screen?.name ?? ""
                        allToplevels = NiriService.filterCurrentWorkspace(allToplevels, screenName)
                    }

                    const runningAppsMap = new Map()
                    let insertionOrder = 0
                    for (const toplevel of allToplevels) {
                        if (!toplevel.appId || toplevel.appId === "null") continue
                        if (ignoredRegexes.some(re => re.test(toplevel.appId))) continue
                        const lower = toplevel.appId.toLowerCase()
                        if (!runningAppsMap.has(lower)) runningAppsMap.set(lower, { appId: toplevel.appId, toplevels: [], insertionOrder: insertionOrder++ })
                        runningAppsMap.get(lower).toplevels.push(toplevel)
                    }

                    const values = []
                    for (const appId of pinnedApps) {
                        const lower = appId.toLowerCase()
                        if (!runningAppsMap.has(lower)) values.push({ uniqueId: "app-" + lower, appId: lower, toplevels: [], pinned: true, originalAppId: appId, section: "pinned" })
                    }

                    const running = []
                    for (const [lowerAppId, entry] of runningAppsMap) running.push({ lowerAppId: lowerAppId, entry: entry })
                    running.sort((a, b) => {
                        const aIndex = pinnedApps.findIndex(p => p.toLowerCase() === a.lowerAppId)
                        const bIndex = pinnedApps.findIndex(p => p.toLowerCase() === b.lowerAppId)
                        const aPinned = aIndex !== -1
                        const bPinned = bIndex !== -1
                        if (aPinned && bPinned) return aIndex - bIndex
                        if (aPinned) return -1
                        if (bPinned) return 1
                        return a.entry.insertionOrder - b.entry.insertionOrder
                    })
                    for (const item of running) values.push({ uniqueId: "app-" + item.lowerAppId, appId: item.lowerAppId, toplevels: item.entry.toplevels, pinned: pinnedApps.some(p => p.toLowerCase() === item.lowerAppId), originalAppId: item.entry.appId, section: "running" })

                    dockItems = values
                }

                function launchFromDesktopEntry(entry): bool {
                    let id = entry?.originalAppId ?? entry?.appId ?? ""
                    if (id === "com.github.th_ch.youtube_music") id = "youtube-music"
                    if (id === "spotify" || id === "spotify-launcher") id = "spotify-launcher"
                    if (!id) return false
                    const cmd = "/usr/bin/gtk-launch \"" + id + "\" || \"" + id + "\" &"
                    Quickshell.execDetached(["/usr/bin/bash", "-lc", cmd])
                    return true
                }

                function openPreview(entry, anchorItem) {
                    if (anchorItem) {
                        const pos = previewAnchorFallback.parent.mapFromItem(anchorItem, 0, 0)
                        previewAnchorFallback.x = pos.x
                        previewAnchorFallback.y = pos.y
                        previewAnchorFallback.width = anchorItem.width
                        previewAnchorFallback.height = anchorItem.height
                    }
                    previewEntry = entry
                    previewAnchorItem = previewAnchorFallback
                }
                function closePreview() { previewEntry = null; previewAnchorItem = previewAnchorFallback; previewHovered = false }

                Connections { target: ToplevelManager.toplevels; function onValuesChanged() { railWindow.rebuildDockItems() } }
                Connections { target: CompositorService; function onSortedToplevelsChanged() { railWindow.rebuildDockItems() } }
                Connections { target: NiriService; function onFocusedWorkspaceIdChanged() { railWindow.rebuildDockItems() } }
                Connections {
                    target: Config.options?.dock
                    function onPinnedAppsChanged() { railWindow.rebuildDockItems() }
                    function onIgnoredAppRegexesChanged() { railWindow.rebuildDockItems() }
                    function onScopeChanged() { railWindow.rebuildDockItems() }
                }
                Component.onCompleted: { rebuildDockItems(); recomputeWorkspaceWindowCount(); gapToggleDebounce.restart() }

                Rectangle {
                    anchors.fill: parent
                    color: Appearance.courier.colCanvas

                    Rectangle {
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        width: 1
                        color: Appearance.courier.colBorder
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.leftMargin: root.railPadding
                        anchors.rightMargin: root.railPadding
                        anchors.topMargin: root.railPadding
                        anchors.bottomMargin: root.railPadding
                        spacing: root.itemGap

                        Repeater {
                            model: ScriptModel {
                                values: railWindow.pinnedItems
                                objectProp: "uniqueId"
                            }
                            delegate: railItemDelegate
                        }

                        Rectangle {
                            visible: railWindow.showDivider
                            Layout.alignment: Qt.AlignHCenter
                            width: 20
                            height: 1
                            color: Appearance.courier.colBorderDim
                        }

                        Repeater {
                            model: ScriptModel {
                                values: railWindow.runningItems
                                objectProp: "uniqueId"
                            }
                            delegate: railItemDelegate
                        }

                        Item { Layout.fillHeight: true }

                        Column {
                            visible: railWindow.showEmpty
                            spacing: 3
                            Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom

                            Rectangle {
                                width: emptyPill.implicitWidth + 8
                                height: emptyPill.implicitHeight + 4
                                radius: 0
                                border.width: 1
                                border.color: Appearance.courier.colBorder
                                color: ColorUtils.transparentize(Appearance.courier.colBorder, 0.85)
                                StyledText {
                                    id: emptyPill
                                    anchors.centerIn: parent
                                    text: "[EMPTY]"
                                    color: Appearance.courier.colBorder
                                    font.family: Appearance.font.family.monospace
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                    font.letterSpacing: 1.2
                                }
                            }

                            StyledText { text: "DOCK"; color: Appearance.courier.colTextDim; font.family: Appearance.font.family.monospace; font.pixelSize: Appearance.font.pixelSize.smallest; font.letterSpacing: 1.2; horizontalAlignment: Text.AlignHCenter }
                            StyledText { text: "─────"; color: Appearance.courier.colTextDim; font.family: Appearance.font.family.monospace; font.pixelSize: Appearance.font.pixelSize.smallest; font.letterSpacing: 1.2; horizontalAlignment: Text.AlignHCenter }
                            StyledText { text: "pinned"; color: Appearance.courier.colTextDim; font.family: Appearance.font.family.monospace; font.pixelSize: Appearance.font.pixelSize.smallest; font.letterSpacing: 1.2; horizontalAlignment: Text.AlignHCenter }
                            StyledText { text: "none"; color: Appearance.courier.colText; font.family: Appearance.font.family.monospace; font.pixelSize: Appearance.font.pixelSize.smaller; horizontalAlignment: Text.AlignHCenter }
                            Item { width: 1; height: 4 }
                            StyledText { text: "route"; color: Appearance.courier.colTextDim; font.family: Appearance.font.family.monospace; font.pixelSize: Appearance.font.pixelSize.smallest; font.letterSpacing: 1.2; horizontalAlignment: Text.AlignHCenter }
                            StyledText { text: "+ from"; color: Appearance.courier.colText; font.family: Appearance.font.family.monospace; font.pixelSize: Appearance.font.pixelSize.smaller; horizontalAlignment: Text.AlignHCenter }
                            StyledText { text: "  launcher"; color: Appearance.courier.colText; font.family: Appearance.font.family.monospace; font.pixelSize: Appearance.font.pixelSize.smaller; horizontalAlignment: Text.AlignHCenter }
                        }
                    }
                }

                Component {
                    id: railItemDelegate
                    Item {
                        id: appItem
                        required property var modelData
                        property int lastFocused: -1
                        readonly property bool hasWindows: (modelData?.toplevels?.length ?? 0) > 0
                        readonly property bool isFocused: modelData?.toplevels?.find(t => t?.activated === true) !== undefined
                        readonly property var desktopEntry: AppSearch.lookupDesktopEntry(modelData?.originalAppId ?? modelData?.appId)
                        width: root.buttonSize
                        height: root.buttonSize

                        Rectangle { anchors.fill: parent; radius: Appearance.courier.radiusMicro; color: mouseArea.pressed ? Appearance.courier.colSurfaceActive : (mouseArea.containsMouse ? Appearance.courier.colSurfaceHover : "transparent") }
                        Rectangle { visible: appItem.hasWindows; width: appItem.isFocused ? 4 : 3; anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.right: parent.right; color: appItem.isFocused ? Appearance.courier.colBorder : Appearance.courier.colBorderDim }

                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: root.iconSize
                            source: {
                                const appId = appItem.modelData?.originalAppId ?? appItem.modelData?.appId ?? ""
                                const icon = appItem.desktopEntry?.icon || AppSearch.guessIcon(appId)
                                return Quickshell.iconPath(IconThemeService.smartIconName(icon, appId), "application-x-executable")
                            }
                            mipmap: true
                            smooth: true
                        }

                        Timer {
                            id: hoverPreviewTimer
                            interval: Config.options?.dock?.hoverPreviewDelay ?? 400
                            onTriggered: if (appItem.hasWindows && mouseArea.containsMouse) railWindow.openPreview(appItem.modelData, appItem)
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                            hoverEnabled: true
                            onEntered: if (appItem.hasWindows && Config.options?.dock?.hoverPreview !== false) hoverPreviewTimer.restart()
                            onExited: { hoverPreviewTimer.stop(); if (!railWindow.previewHovered) railWindow.closePreview() }

                            onClicked: mouse => {
                                const entry = appItem.modelData
                                if (mouse.button === Qt.RightButton) {
                                    contextMenu.anchorItem = appItem
                                    contextMenu.active = true
                                    railWindow.contextMenuOpen = true
                                    railWindow.closePreview()
                                    return
                                }
                                if (mouse.button === Qt.MiddleButton || !appItem.hasWindows) {
                                    railWindow.launchFromDesktopEntry(entry)
                                    return
                                }
                                const total = entry.toplevels.length
                                appItem.lastFocused = (appItem.lastFocused + 1) % total
                                const toplevel = entry.toplevels[appItem.lastFocused]
                                if (CompositorService.isNiri && toplevel?.niriWindowId) NiriService.focusWindow(toplevel.niriWindowId)
                                else toplevel?.activate()
                            }
                        }

                        DockContextMenu {
                            id: contextMenu
                            anchorItem: appItem
                            anchorHovered: mouseArea.containsMouse
                            onActiveChanged: if (!active) railWindow.contextMenuOpen = false
                            model: [
                                {
                                    iconName: IconThemeService.smartIconName(appItem.desktopEntry?.icon ?? "", appItem.modelData?.originalAppId ?? appItem.modelData?.appId),
                                    text: appItem.desktopEntry?.name ?? StringUtils.toTitleCase(appItem.modelData?.originalAppId ?? appItem.modelData?.appId ?? ""),
                                    monochromeIcon: false,
                                    action: () => railWindow.launchFromDesktopEntry(appItem.modelData)
                                },
                                {
                                    iconName: appItem.modelData?.pinned ? "keep_off" : "keep",
                                    text: appItem.modelData?.pinned ? Translation.tr("Unpin from dock") : Translation.tr("Pin to dock"),
                                    monochromeIcon: true,
                                    action: () => {
                                        const appId = appItem.modelData?.originalAppId ?? appItem.modelData?.appId
                                        const pinned = Config.options?.dock?.pinnedApps ?? []
                                        if (pinned.indexOf(appId) !== -1) Config.setNestedValue("dock.pinnedApps", pinned.filter(id => id !== appId))
                                        else Config.setNestedValue("dock.pinnedApps", pinned.concat([appId]))
                                    }
                                },
                                ...(appItem.hasWindows ? [{ type: "separator" }, {
                                    iconName: "close",
                                    text: appItem.modelData.toplevels.length > 1 ? Translation.tr("Close all windows") : Translation.tr("Close window"),
                                    monochromeIcon: true,
                                    action: () => { for (let toplevel of appItem.modelData.toplevels) toplevel.close() }
                                }] : root.emptyList)
                            ]
                        }
                    }
                }

                PopupWindow {
                    visible: railWindow.previewEntry !== null && railWindow.previewAnchorItem !== null && !GameMode.shouldHidePanels
                    color: "transparent"
                    anchor.item: railWindow.previewAnchorItem ?? previewAnchorFallback
                    anchor.adjustment: PopupAdjustment.Slide
                    anchor.gravity: Edges.Right
                    anchor.edges: Edges.Left
                    implicitWidth: previewLayout.implicitWidth + 16
                    implicitHeight: previewLayout.implicitHeight + 16

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: railWindow.previewHovered = true
                        onExited: railWindow.closePreview()

                        Rectangle {
                            anchors.fill: parent
                            radius: Appearance.courier.radiusMicro
                            color: Appearance.courier.colSurface
                            border.width: 1
                            border.color: Appearance.courier.colBorderDim

                            RowLayout {
                                id: previewLayout
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8
                                Repeater {
                                    model: ScriptModel { values: railWindow.previewEntry?.toplevels ?? root.emptyList; objectProp: "niriWindowId" }
                                    delegate: DockWindowPreview {
                                        required property var modelData
                                        toplevel: modelData
                                        onWindowActivated: railWindow.closePreview()
                                        onWindowCloseClicked: railWindow.closePreview()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
