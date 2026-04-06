import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: displayPage
    settingsPageIndex: 6
    settingsPageName: Translation.tr("Displays")
    settingsPageIcon: "monitor"

    // Refresh display data when page loads
    Component.onCompleted: IidSocket.refreshDisplays()

    // Re-read on display change events
    Connections {
        target: IidSocket
        function onDisplayChanged() { IidSocket.refreshDisplays() }
    }

    // ── Display Arrangement ────────────────────────────────────────
    SettingsCardSection {
        expanded: true
        icon: "grid_view"
        title: Translation.tr("Display Arrangement")

        SettingsGroup {
            // Canvas for monitor arrangement
            Item {
                id: arrangementCanvas
                Layout.fillWidth: true
                implicitHeight: 400

                // -- Computed layout properties --
                readonly property var displayKeys: Object.keys(IidSocket.displays ?? {})
                readonly property int monitorCount: displayKeys.length
                readonly property bool multiMonitor: monitorCount > 1

                // Bounding box of all monitors in real coordinates
                readonly property var boundingBox: {
                    const keys = displayKeys
                    if (keys.length === 0) return { x: 0, y: 0, w: 1920, h: 1080 }

                    let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity
                    for (const k of keys) {
                        const d = IidSocket.displays[k]
                        const l = d?.logical ?? {}
                        const x = l.x ?? 0
                        const y = l.y ?? 0
                        const w = l.width ?? 1920
                        const h = l.height ?? 1080
                        minX = Math.min(minX, x)
                        minY = Math.min(minY, y)
                        maxX = Math.max(maxX, x + w)
                        maxY = Math.max(maxY, y + h)
                    }
                    return { x: minX, y: minY, w: maxX - minX, h: maxY - minY }
                }

                // Scale factor: fit bounding box into canvas with padding
                readonly property real canvasPadding: 60
                readonly property real availableW: width - canvasPadding * 2
                readonly property real availableH: height - canvasPadding * 2
                readonly property real scaleFactor: {
                    const bb = boundingBox
                    if (bb.w <= 0 || bb.h <= 0) return 0.1
                    return Math.min(availableW / bb.w, availableH / bb.h, 0.5)
                }

                // Offset to center the arrangement
                readonly property real offsetX: (width - boundingBox.w * scaleFactor) / 2
                readonly property real offsetY: (height - boundingBox.h * scaleFactor) / 2

                // Convert real coords to canvas coords
                function toCanvasX(realX) {
                    return (realX - boundingBox.x) * scaleFactor + offsetX
                }
                function toCanvasY(realY) {
                    return (realY - boundingBox.y) * scaleFactor + offsetY
                }

                // Convert canvas coords back to real coords
                function toRealX(canvasX) {
                    return (canvasX - offsetX) / scaleFactor + boundingBox.x
                }
                function toRealY(canvasY) {
                    return (canvasY - offsetY) / scaleFactor + boundingBox.y
                }

                // Currently selected monitor name
                property string selectedOutput: displayKeys.length > 0 ? displayKeys[0] : ""

                // Track which monitor is being dragged
                property string draggingOutput: ""

                // Dark canvas background
                Rectangle {
                    anchors.fill: parent
                    radius: Appearance.rounding.screenRounding
                    color: Appearance.colors.colLayer0
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border

                    // Grid pattern hint (subtle dots)
                    Canvas {
                        anchors.fill: parent
                        anchors.margins: 1
                        onPaint: {
                            const ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            ctx.fillStyle = Qt.rgba(
                                Appearance.colors.colSubtext.r,
                                Appearance.colors.colSubtext.g,
                                Appearance.colors.colSubtext.b,
                                0.08
                            )
                            const step = 30
                            for (let x = step; x < width; x += step) {
                                for (let y = step; y < height; y += step) {
                                    ctx.beginPath()
                                    ctx.arc(x, y, 1, 0, 2 * Math.PI)
                                    ctx.fill()
                                }
                            }
                        }
                        // Repaint when colors change
                        Connections {
                            target: Appearance.colors
                            function onColSubtextChanged() { parent.requestPaint() }
                        }
                    }
                }

                // Monitor rectangles
                Repeater {
                    id: monitorRepeater
                    model: arrangementCanvas.displayKeys

                    delegate: Item {
                        id: monitorDelegate
                        required property string modelData
                        required property int index

                        readonly property var output: IidSocket.displays[modelData] ?? {}
                        readonly property var logical: output.logical ?? {}
                        readonly property real realX: logical.x ?? 0
                        readonly property real realY: logical.y ?? 0
                        readonly property real realW: logical.width ?? 1920
                        readonly property real realH: logical.height ?? 1080
                        readonly property bool isSelected: arrangementCanvas.selectedOutput === modelData
                        readonly property bool isDragging: arrangementCanvas.draggingOutput === modelData

                        // Positioned by canvas coordinates
                        // During drag, MouseArea updates x/y imperatively.
                        // When not dragging, bind to the computed canvas position.
                        property real targetX: arrangementCanvas.toCanvasX(realX)
                        property real targetY: arrangementCanvas.toCanvasY(realY)
                        onTargetXChanged: if (!isDragging) x = targetX
                        onTargetYChanged: if (!isDragging) y = targetY
                        Component.onCompleted: { x = targetX; y = targetY }
                        width: realW * arrangementCanvas.scaleFactor
                        height: realH * arrangementCanvas.scaleFactor
                        z: isDragging ? 10 : (isSelected ? 5 : 1)

                        // Smooth position animation when not dragging
                        Behavior on x {
                            enabled: !isDragging
                            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                        }
                        Behavior on y {
                            enabled: !isDragging
                            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                        }

                        // Drop shadow
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: -2
                            radius: Appearance.rounding.screenRounding + 2
                            color: "transparent"
                            border.width: isSelected ? 2 : 0
                            border.color: Appearance.colors.colPrimary
                            opacity: isSelected ? 0.6 : 0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }

                        // Monitor body
                        Rectangle {
                            id: monitorBody
                            anchors.fill: parent
                            radius: Appearance.rounding.screenRounding
                            color: isSelected ? Appearance.colors.colPrimary : Appearance.colors.colLayer2
                            border.width: 1
                            border.color: isSelected
                                ? Qt.darker(Appearance.colors.colPrimary, 1.2)
                                : Appearance.colors.colLayer1

                            Behavior on color { ColorAnimation { duration: 150 } }

                            // Number badge
                            Rectangle {
                                id: badge
                                width: 24; height: 24
                                radius: 12
                                anchors { top: parent.top; left: parent.left; margins: 8 }
                                color: isSelected ? Appearance.colors.colOnPrimary : Appearance.colors.colPrimary

                                StyledText {
                                    anchors.centerIn: parent
                                    text: (index + 1).toString()
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    font.weight: Font.Bold
                                    color: isSelected ? Appearance.colors.colPrimary : Appearance.colors.colOnPrimary
                                }
                            }

                            // Labels
                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2

                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData
                                    font.pixelSize: Math.max(Appearance.font.pixelSize.small, Math.min(Appearance.font.pixelSize.normal, monitorBody.width * 0.08))
                                    font.weight: Font.DemiBold
                                    color: isSelected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }

                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: Math.round(realW * (logical.scale ?? 1)) + "×" + Math.round(realH * (logical.scale ?? 1))
                                    font.pixelSize: Math.max(Appearance.font.pixelSize.smaller, Math.min(Appearance.font.pixelSize.small, monitorBody.width * 0.06))
                                    color: isSelected ? Appearance.colors.colOnPrimary : Appearance.colors.colSubtext
                                    opacity: 0.8
                                    visible: monitorBody.width > 80
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }
                            }

                            // Drag interaction
                            MouseArea {
                                anchors.fill: parent
                                enabled: arrangementCanvas.multiMonitor
                                cursorShape: arrangementCanvas.multiMonitor ? (pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor) : Qt.ArrowCursor
                                hoverEnabled: true

                                property real dragStartX: 0
                                property real dragStartY: 0
                                property real itemStartX: 0
                                property real itemStartY: 0

                                onPressed: event => {
                                    arrangementCanvas.selectedOutput = modelData
                                    if (!arrangementCanvas.multiMonitor) return
                                    arrangementCanvas.draggingOutput = modelData
                                    dragStartX = event.x
                                    dragStartY = event.y
                                    itemStartX = monitorDelegate.x
                                    itemStartY = monitorDelegate.y
                                }

                                onPositionChanged: event => {
                                    if (arrangementCanvas.draggingOutput !== modelData) return
                                    const newX = itemStartX + (event.x - dragStartX)
                                    const newY = itemStartY + (event.y - dragStartY)

                                    // Clamp within canvas bounds
                                    monitorDelegate.x = Math.max(0, Math.min(newX, arrangementCanvas.width - monitorDelegate.width))
                                    monitorDelegate.y = Math.max(0, Math.min(newY, arrangementCanvas.height - monitorDelegate.height))
                                }

                                onReleased: {
                                    if (arrangementCanvas.draggingOutput !== modelData) return
                                    arrangementCanvas.draggingOutput = ""

                                    // Convert canvas position to real coordinates
                                    let newRealX = arrangementCanvas.toRealX(monitorDelegate.x)
                                    let newRealY = arrangementCanvas.toRealY(monitorDelegate.y)

                                    // Edge snapping: check against all other monitors
                                    const snapThreshold = 20 // real-world pixels
                                    const keys = arrangementCanvas.displayKeys
                                    for (const k of keys) {
                                        if (k === modelData) continue
                                        const other = IidSocket.displays[k]
                                        const ol = other?.logical ?? {}
                                        const ox = ol.x ?? 0
                                        const oy = ol.y ?? 0
                                        const ow = ol.width ?? 0
                                        const oh = ol.height ?? 0

                                        // Snap right edge of dragged to left edge of other
                                        if (Math.abs((newRealX + realW) - ox) < snapThreshold)
                                            newRealX = ox - realW
                                        // Snap left edge of dragged to right edge of other
                                        if (Math.abs(newRealX - (ox + ow)) < snapThreshold)
                                            newRealX = ox + ow
                                        // Snap left edges
                                        if (Math.abs(newRealX - ox) < snapThreshold)
                                            newRealX = ox
                                        // Snap right edges
                                        if (Math.abs((newRealX + realW) - (ox + ow)) < snapThreshold)
                                            newRealX = ox + ow - realW

                                        // Snap bottom edge of dragged to top edge of other
                                        if (Math.abs((newRealY + realH) - oy) < snapThreshold)
                                            newRealY = oy - realH
                                        // Snap top edge of dragged to bottom edge of other
                                        if (Math.abs(newRealY - (oy + oh)) < snapThreshold)
                                            newRealY = oy + oh
                                        // Snap top edges
                                        if (Math.abs(newRealY - oy) < snapThreshold)
                                            newRealY = oy
                                        // Snap bottom edges
                                        if (Math.abs((newRealY + realH) - (oy + oh)) < snapThreshold)
                                            newRealY = oy + oh - realH
                                    }

                                    // Overlap prevention: push away if overlapping any other monitor
                                    for (const k of keys) {
                                        if (k === modelData) continue
                                        const other = IidSocket.displays[k]
                                        const ol = other?.logical ?? {}
                                        const ox = ol.x ?? 0
                                        const oy = ol.y ?? 0
                                        const ow = ol.width ?? 0
                                        const oh = ol.height ?? 0

                                        // Check overlap
                                        if (newRealX < ox + ow && newRealX + realW > ox &&
                                            newRealY < oy + oh && newRealY + realH > oy) {
                                            // Find minimum displacement to resolve overlap
                                            const pushLeft = ox - (newRealX + realW)
                                            const pushRight = (ox + ow) - newRealX
                                            const pushUp = oy - (newRealY + realH)
                                            const pushDown = (oy + oh) - newRealY

                                            const minH = Math.abs(pushLeft) < Math.abs(pushRight) ? pushLeft : pushRight
                                            const minV = Math.abs(pushUp) < Math.abs(pushDown) ? pushUp : pushDown

                                            if (Math.abs(minH) < Math.abs(minV))
                                                newRealX += minH
                                            else
                                                newRealY += minV
                                        }
                                    }

                                    // Round to integers
                                    newRealX = Math.round(newRealX)
                                    newRealY = Math.round(newRealY)

                                    // Commit position to daemon
                                    IidSocket.setDisplayPosition(modelData, newRealX, newRealY)
                                }

                                onClicked: {
                                    arrangementCanvas.selectedOutput = modelData
                                }
                            }
                        }
                    }
                }

                // Single-monitor hint
                StyledText {
                    anchors {
                        bottom: parent.bottom
                        horizontalCenter: parent.horizontalCenter
                        bottomMargin: 12
                    }
                    visible: arrangementCanvas.monitorCount === 1
                    text: Translation.tr("Connect additional displays to arrange them")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    opacity: 0.6
                }

                // Empty state
                ColumnLayout {
                    anchors.centerIn: parent
                    visible: arrangementCanvas.monitorCount === 0
                    spacing: 8

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        text: IidSocket.connected ? "desktop_access_disabled" : "link_off"
                        iconSize: 48
                        color: Appearance.colors.colSubtext
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: IidSocket.connected
                            ? Translation.tr("No displays detected")
                            : Translation.tr("Display daemon not connected")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colSubtext
                    }
                }
            }
        }
    }

    // ── Monitor Overview ────────────────────────────────────────────
    SettingsCardSection {
        expanded: true
        icon: "monitor"
        title: Translation.tr("Monitors")

        SettingsGroup {
            Repeater {
                model: Object.keys(IidSocket.displays ?? {})

                delegate: Item {
                    required property string modelData
                    required property int index

                    readonly property var output: IidSocket.displays[modelData] ?? {}
                    readonly property var logical: output.logical ?? {}
                    readonly property var modes: output.modes ?? []
                    readonly property int currentModeIdx: output.current_mode ?? 0
                    readonly property var currentMode: modes[currentModeIdx] ?? {}

                    Layout.fillWidth: true
                    implicitHeight: monitorColumn.implicitHeight + 16

                    ColumnLayout {
                        id: monitorColumn
                        anchors {
                            left: parent.left; right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: 8; rightMargin: 8
                        }
                        spacing: 12

                        // ── Header: Monitor name + info ──
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            MaterialSymbol {
                                text: "monitor"
                                iconSize: Appearance.font.pixelSize.hugeTitle
                                color: Appearance.colors.colPrimary
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                StyledText {
                                    text: modelData
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    font.weight: Font.Bold
                                    color: Appearance.colors.colOnLayer1
                                }
                                StyledText {
                                    text: (output.make ?? "") + " " + (output.model ?? "")
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colSubtext
                                }
                                StyledText {
                                    text: {
                                        const w = currentMode.width ?? 0
                                        const h = currentMode.height ?? 0
                                        const hz = ((currentMode.refresh_rate ?? 0) / 1000).toFixed(1)
                                        const s = logical.scale ?? 1
                                        return `${w}×${h} @ ${hz}Hz · Scale ${s}x`
                                    }
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colSubtext
                                }
                            }
                        }

                        SettingsDivider {}

                        // ── Resolution + Refresh Rate ──
                        ContentSubsection {
                            title: Translation.tr("Resolution & Refresh Rate")

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                StyledComboBox {
                                    id: modeCombo
                                    Layout.fillWidth: true

                                    property var modeList: {
                                        // Build unique mode strings, sorted by resolution then refresh
                                        const m = modes.map((mode, i) => ({
                                            idx: i,
                                            label: `${mode.width}×${mode.height} @ ${(mode.refresh_rate / 1000).toFixed(1)}Hz` + (mode.is_preferred ? " ★" : ""),
                                            width: mode.width,
                                            height: mode.height,
                                            refresh: mode.refresh_rate
                                        }))
                                        return m
                                    }

                                    model: modeList.map(m => m.label)
                                    currentIndex: currentModeIdx

                                    onActivated: index => {
                                        const selected = modeList[index]
                                        if (selected) {
                                            IidSocket.setDisplayMode(
                                                modelData,
                                                selected.width,
                                                selected.height,
                                                selected.refresh
                                            )
                                        }
                                    }
                                }
                            }
                        }

                        SettingsDivider {}

                        // ── Scale ──
                        ContentSubsection {
                            title: Translation.tr("Scale")
                            tooltip: Translation.tr("Display scaling factor. Niri supports fractional scaling.")

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                StyledComboBox {
                                    id: scaleCombo
                                    Layout.fillWidth: true

                                    readonly property var scaleOptions: [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0]
                                    model: scaleOptions.map(s => s + "x")

                                    currentIndex: {
                                        const current = logical.scale ?? 1.0
                                        const idx = scaleOptions.indexOf(current)
                                        return idx >= 0 ? idx : scaleOptions.indexOf(1.0)
                                    }

                                    onActivated: index => {
                                        IidSocket.setDisplayScale(modelData, scaleOptions[index])
                                    }
                                }
                            }
                        }

                        SettingsDivider {}

                        // ── Rotation ──
                        ContentSubsection {
                            title: Translation.tr("Rotation")

                            StyledComboBox {
                                id: transformCombo
                                Layout.fillWidth: true

                                readonly property var transformOptions: [
                                    { label: Translation.tr("Normal"), value: "normal" },
                                    { label: "90°", value: "90" },
                                    { label: "180°", value: "180" },
                                    { label: "270°", value: "270" },
                                    { label: Translation.tr("Flipped"), value: "flipped" },
                                    { label: Translation.tr("Flipped") + " 90°", value: "flipped-90" },
                                    { label: Translation.tr("Flipped") + " 180°", value: "flipped-180" },
                                    { label: Translation.tr("Flipped") + " 270°", value: "flipped-270" }
                                ]

                                model: transformOptions.map(t => t.label)

                                currentIndex: {
                                    const current = (logical.transform ?? "Normal").toLowerCase()
                                    const idx = transformOptions.findIndex(t => t.value === current)
                                    return idx >= 0 ? idx : 0
                                }

                                onActivated: index => {
                                    IidSocket.setDisplayTransform(modelData, transformOptions[index].value)
                                }
                            }
                        }

                        SettingsDivider {}

                        // ── VRR ──
                        SettingsSwitch {
                            buttonIcon: "display_settings"
                            text: Translation.tr("Variable Refresh Rate")
                            enabled: output.vrr_supported ?? false
                            checked: output.vrr_enabled ?? false
                            onCheckedChanged: {
                                if (checked !== (output.vrr_enabled ?? false)) {
                                    IidSocket.setDisplayVrr(modelData, checked)
                                }
                            }
                            StyledToolTip {
                                text: (output.vrr_supported ?? false)
                                    ? Translation.tr("Adaptive sync (FreeSync/G-Sync) reduces screen tearing")
                                    : Translation.tr("This monitor does not support VRR")
                            }
                        }
                    }

                    // Separator between monitors
                    Rectangle {
                        visible: index < Object.keys(IidSocket.displays ?? {}).length - 1
                        Layout.fillWidth: true
                        height: 2
                        color: Appearance.colors.colLayer1
                        Layout.topMargin: 8
                        Layout.bottomMargin: 8
                    }
                }
            }

            // Empty state when daemon not connected
            ColumnLayout {
                visible: !IidSocket.connected || Object.keys(IidSocket.displays ?? {}).length === 0
                Layout.fillWidth: true
                spacing: 8
                Layout.topMargin: 16
                Layout.bottomMargin: 16

                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    text: IidSocket.connected ? "monitor" : "link_off"
                    iconSize: 48
                    color: Appearance.colors.colSubtext
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: IidSocket.connected
                        ? Translation.tr("No displays detected")
                        : Translation.tr("Display daemon not connected")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colSubtext
                }

                StyledText {
                    visible: !IidSocket.connected
                    Layout.alignment: Qt.AlignHCenter
                    text: Translation.tr("Start the iid service: systemctl --user start iid")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }
            }
        }
    }

    // ── Daemon Status ───────────────────────────────────────────────
    SettingsCardSection {
        expanded: true
        icon: "dns"
        title: Translation.tr("Display Daemon")

        SettingsGroup {
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Layout.margins: 8

                MaterialSymbol {
                    text: IidSocket.connected ? "check_circle" : "error"
                    iconSize: Appearance.font.pixelSize.larger
                    color: IidSocket.connected ? Appearance.colors.colPrimary : Appearance.colors.colError
                }

                StyledText {
                    Layout.fillWidth: true
                    text: IidSocket.connected
                        ? Translation.tr("Connected to iid daemon")
                        : Translation.tr("Not connected — display settings unavailable")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: IidSocket.connected ? Appearance.colors.colOnLayer1 : Appearance.colors.colError
                }
            }
        }
    }
}
