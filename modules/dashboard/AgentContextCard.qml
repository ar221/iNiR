import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

DashboardCard {
    id: root

    headerText: "Context Staging"

    function defaultStagedItems() {
        const items = [
            { id: "model", title: `Model route: ${Ai.currentModelId ?? "none"}`, kind: "auto" },
            { id: "provider", title: `Provider: ${Ai.providerLabel ?? "none"}`, kind: "rule" },
            { id: "tool", title: `Tool mode: ${Ai.currentTool ?? "none"}`, kind: "rule" }
        ]

        if ((Ai.pendingFilePath ?? "").length > 0)
            items.push({ id: "attachment", title: `Attached file: ${Ai.pendingFilePath}`, kind: "file" })

        return items
    }

    property var stagedItems: root.defaultStagedItems()
    property int selectedIndex: stagedItems.length > 0 ? 0 : -1
    readonly property bool vimKeymapEnabled: (Config.options?.dashboard?.agentCockpit?.powerKeymap ?? true)

    function selectDelta(delta) {
        if (root.stagedItems.length === 0) {
            root.selectedIndex = -1
            return
        }
        const base = root.selectedIndex < 0 ? 0 : root.selectedIndex
        root.selectedIndex = Math.max(0, Math.min(root.stagedItems.length - 1, base + delta))
    }

    function moveSelected(delta) {
        const idx = root.selectedIndex
        const target = idx + delta
        if (idx < 0 || idx >= root.stagedItems.length) return
        if (target < 0 || target >= root.stagedItems.length) return
        const next = root.stagedItems.slice()
        const tmp = next[target]
        next[target] = next[idx]
        next[idx] = tmp
        root.stagedItems = next
        root.selectedIndex = target
    }

    function removeSelected() {
        const idx = root.selectedIndex
        if (idx < 0 || idx >= root.stagedItems.length) return
        const next = root.stagedItems.slice()
        next.splice(idx, 1)
        root.stagedItems = next
        root.selectedIndex = Math.min(next.length - 1, idx)
    }

    function iconForKind(kind) {
        if (kind === "file")
            return "description"
        if (kind === "rule")
            return "policy"
        if (kind === "note")
            return "sticky_note_2"
        return "target"
    }

    Connections {
        target: Ai
        function onCurrentModelIdChanged() {
            root.stagedItems = root.defaultStagedItems().concat(root.stagedItems.filter(i => i.kind === "note"))
            root.selectedIndex = root.stagedItems.length > 0 ? 0 : -1
        }
        function onCurrentToolChanged() {
            root.stagedItems = root.defaultStagedItems().concat(root.stagedItems.filter(i => i.kind === "note"))
            root.selectedIndex = root.stagedItems.length > 0 ? 0 : -1
        }
        function onPendingFilePathChanged() {
            root.stagedItems = root.defaultStagedItems().concat(root.stagedItems.filter(i => i.kind === "note"))
            root.selectedIndex = root.stagedItems.length > 0 ? 0 : -1
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        RippleButton {
            Layout.fillWidth: true
            implicitHeight: 34
            buttonRadius: 10
            colBackground: Qt.rgba(1, 1, 1, 0.04)
            colBackgroundHover: Qt.rgba(1, 1, 1, 0.08)
            colRipple: Qt.rgba(1, 1, 1, 0.12)
            onClicked: {
                root.stagedItems = root.stagedItems.concat([{ id: `note-${Date.now()}`, title: "Quick note context", kind: "note" }])
                root.selectedIndex = root.stagedItems.length - 1
            }

            contentItem: RowLayout {
                anchors.centerIn: parent
                spacing: 6
                MaterialSymbol { text: "add"; iconSize: 16; color: Appearance.colors.colOnLayer1 }
                StyledText {
                    text: "Add Note"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                }
            }
        }

        RippleButton {
            implicitWidth: 40
            implicitHeight: 34
            buttonRadius: 10
            colBackground: Qt.rgba(1, 1, 1, 0.04)
            colBackgroundHover: Qt.rgba(1, 1, 1, 0.08)
            onClicked: {
                root.stagedItems = root.defaultStagedItems()
                root.selectedIndex = root.stagedItems.length > 0 ? 0 : -1
            }
            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                text: "refresh"
                iconSize: 16
                color: Appearance.colors.colOnLayer1
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6

        Repeater {
            model: root.stagedItems

            Rectangle {
                required property var modelData
                required property int index
                readonly property bool selected: index === root.selectedIndex
                Layout.fillWidth: true
                implicitHeight: 34
                radius: 9
                color: selected
                    ? ColorUtils.transparentize(Appearance.colors.colPrimary, 0.84)
                    : Qt.rgba(1, 1, 1, 0.03)
                border.width: 1
                border.color: selected
                    ? ColorUtils.transparentize(Appearance.colors.colPrimary, 0.55)
                    : Qt.rgba(1, 1, 1, 0.06)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 6
                    spacing: 6

                    MaterialSymbol {
                        text: root.iconForKind(modelData.kind)
                        iconSize: 14
                        color: Appearance.colors.colSubtext
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: modelData.title
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer1
                        elide: Text.ElideRight
                    }

                    RippleButton {
                        implicitWidth: 24
                        implicitHeight: 24
                        buttonRadius: 12
                        colBackground: "transparent"
                        colBackgroundHover: Qt.rgba(1, 1, 1, 0.08)
                        onClicked: {
                            const idx = root.stagedItems.findIndex(i => i.id === modelData.id)
                            if (idx > 0) {
                                const next = root.stagedItems.slice()
                                const tmp = next[idx - 1]
                                next[idx - 1] = next[idx]
                                next[idx] = tmp
                                root.stagedItems = next
                                root.selectedIndex = idx - 1
                            }
                        }
                        contentItem: MaterialSymbol { anchors.centerIn: parent; text: "arrow_upward"; iconSize: 14; color: Appearance.colors.colSubtext }
                    }

                    RippleButton {
                        implicitWidth: 24
                        implicitHeight: 24
                        buttonRadius: 12
                        colBackground: "transparent"
                        colBackgroundHover: Qt.rgba(1, 1, 1, 0.08)
                        onClicked: {
                            const idx = root.stagedItems.findIndex(i => i.id === modelData.id)
                            if (idx >= 0 && idx < root.stagedItems.length - 1) {
                                const next = root.stagedItems.slice()
                                const tmp = next[idx + 1]
                                next[idx + 1] = next[idx]
                                next[idx] = tmp
                                root.stagedItems = next
                                root.selectedIndex = idx + 1
                            }
                        }
                        contentItem: MaterialSymbol { anchors.centerIn: parent; text: "arrow_downward"; iconSize: 14; color: Appearance.colors.colSubtext }
                    }

                    RippleButton {
                        implicitWidth: 24
                        implicitHeight: 24
                        buttonRadius: 12
                        colBackground: "transparent"
                        colBackgroundHover: Qt.rgba(1, 0.3, 0.3, 0.15)
                        onClicked: {
                            const idx = root.stagedItems.findIndex(i => i.id === modelData.id)
                            if (idx >= 0) {
                                root.stagedItems = root.stagedItems.filter(i => i.id !== modelData.id)
                                root.selectedIndex = Math.min(root.stagedItems.length - 2, idx)
                            }
                        }
                        contentItem: MaterialSymbol { anchors.centerIn: parent; text: "close"; iconSize: 14; color: Appearance.colors.colError }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selectedIndex = parent.index
                    propagateComposedEvents: true
                }
            }
        }
    }

    Shortcut {
        enabled: root.vimKeymapEnabled
        sequence: "Ctrl+Shift+J"
        onActivated: root.selectDelta(1)
    }

    Shortcut {
        enabled: root.vimKeymapEnabled
        sequence: "Ctrl+Shift+K"
        onActivated: root.selectDelta(-1)
    }

    Shortcut {
        enabled: root.vimKeymapEnabled
        sequence: "Alt+Down"
        onActivated: root.moveSelected(1)
    }

    Shortcut {
        enabled: root.vimKeymapEnabled
        sequence: "Alt+Up"
        onActivated: root.moveSelected(-1)
    }

    Shortcut {
        enabled: root.vimKeymapEnabled
        sequence: "Delete"
        onActivated: root.removeSelected()
    }

    Shortcut {
        enabled: root.vimKeymapEnabled
        sequence: "Ctrl+Shift+A"
        onActivated: {
            root.stagedItems = root.stagedItems.concat([{ id: `note-${Date.now()}`, title: "Quick note context", kind: "note" }])
            root.selectedIndex = root.stagedItems.length - 1
        }
    }

    StyledText {
        Layout.fillWidth: true
        text: `Live context items: ${root.stagedItems.length} · keymap: ${root.vimKeymapEnabled ? "vim" : "off"}`
        font.pixelSize: Appearance.font.pixelSize.smallest
        color: Appearance.colors.colSubtext
        elide: Text.ElideRight
    }
}
