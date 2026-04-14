import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.functions as CF
import qs.modules.common.widgets

ContentPage {
    id: root
    settingsPageIndex: 16
    settingsPageName: Translation.tr("Keybinds")
    settingsPageIcon: "keyboard"

    // ── Data source ──────────────────────────────────────────────────
    readonly property var keybindsData: {
        const data = IidSocket.keybindsList
        if (data && data.children && data.children.length > 0) return data
        return NiriKeybinds.keybinds
    }
    readonly property var categories: keybindsData?.children ?? []
    readonly property bool hasEditCapability: IidSocket.connected && IidSocket.keybindsList?.children?.length > 0

    property var keySubstitutions: ({
        "Super": "󰖳", "Slash": "/", "Return": "↵", "Escape": "Esc",
        "Comma": ",", "Period": ".", "BracketLeft": "[", "BracketRight": "]",
        "Left": "←", "Right": "→", "Up": "↑", "Down": "↓",
        "Page_Up": "PgUp", "Page_Down": "PgDn", "Home": "Home", "End": "End"
    })

    // Track which row is currently being edited (only one at a time)
    property int editingCategoryIndex: -1
    property int editingKeybindIndex: -1

    // Track which row is showing delete confirmation
    property int deleteCategoryIndex: -1
    property int deleteKeybindIndex: -1

    // Whether the "Add Keybind" form is open
    property bool addFormOpen: false

    Component.onCompleted: IidSocket.refreshKeybinds()

    Connections {
        target: IidSocket
        function onKeybindsChanged() { /* reactive via keybindsData binding */ }
    }

    // ── Helper functions ─────────────────────────────────────────────

    function getCategoryIcon(name) {
        const icons = {
            "System": "settings_power",
            "ii Shell": "auto_awesome",
            "Window Switcher": "swap_horiz",
            "Screenshots": "screenshot_region",
            "Applications": "apps",
            "Window Management": "web_asset",
            "Focus": "center_focus_strong",
            "Move Windows": "open_with",
            "Workspaces": "grid_view",
            "Media": "volume_up",
            "Brightness": "light_mode",
            "Other": "more_horiz"
        }
        return icons[name] ?? "keyboard"
    }

    function buildOriginalCombo(mods, key) {
        var parts = mods.map(m => m === "Super" ? "Mod" : m)
        parts.push(key)
        return parts.join("+")
    }

    function keyCodeToName(key) {
        const map = {}
        // Letters A-Z
        map[Qt.Key_A] = "A"; map[Qt.Key_B] = "B"; map[Qt.Key_C] = "C"
        map[Qt.Key_D] = "D"; map[Qt.Key_E] = "E"; map[Qt.Key_F] = "F"
        map[Qt.Key_G] = "G"; map[Qt.Key_H] = "H"; map[Qt.Key_I] = "I"
        map[Qt.Key_J] = "J"; map[Qt.Key_K] = "K"; map[Qt.Key_L] = "L"
        map[Qt.Key_M] = "M"; map[Qt.Key_N] = "N"; map[Qt.Key_O] = "O"
        map[Qt.Key_P] = "P"; map[Qt.Key_Q] = "Q"; map[Qt.Key_R] = "R"
        map[Qt.Key_S] = "S"; map[Qt.Key_T] = "T"; map[Qt.Key_U] = "U"
        map[Qt.Key_V] = "V"; map[Qt.Key_W] = "W"; map[Qt.Key_X] = "X"
        map[Qt.Key_Y] = "Y"; map[Qt.Key_Z] = "Z"
        // Numbers 0-9
        map[Qt.Key_0] = "0"; map[Qt.Key_1] = "1"; map[Qt.Key_2] = "2"
        map[Qt.Key_3] = "3"; map[Qt.Key_4] = "4"; map[Qt.Key_5] = "5"
        map[Qt.Key_6] = "6"; map[Qt.Key_7] = "7"; map[Qt.Key_8] = "8"
        map[Qt.Key_9] = "9"
        // F-keys
        map[Qt.Key_F1] = "F1"; map[Qt.Key_F2] = "F2"; map[Qt.Key_F3] = "F3"
        map[Qt.Key_F4] = "F4"; map[Qt.Key_F5] = "F5"; map[Qt.Key_F6] = "F6"
        map[Qt.Key_F7] = "F7"; map[Qt.Key_F8] = "F8"; map[Qt.Key_F9] = "F9"
        map[Qt.Key_F10] = "F10"; map[Qt.Key_F11] = "F11"; map[Qt.Key_F12] = "F12"
        // Navigation
        map[Qt.Key_Space] = "Space"; map[Qt.Key_Return] = "Return"
        map[Qt.Key_Enter] = "Return"; map[Qt.Key_Escape] = "Escape"
        map[Qt.Key_Tab] = "Tab"; map[Qt.Key_Backspace] = "Backspace"
        map[Qt.Key_Delete] = "Delete"; map[Qt.Key_Insert] = "Insert"
        map[Qt.Key_Left] = "Left"; map[Qt.Key_Right] = "Right"
        map[Qt.Key_Up] = "Up"; map[Qt.Key_Down] = "Down"
        map[Qt.Key_Home] = "Home"; map[Qt.Key_End] = "End"
        map[Qt.Key_PageUp] = "Page_Up"; map[Qt.Key_PageDown] = "Page_Down"
        // Punctuation / symbols
        map[Qt.Key_Comma] = "Comma"; map[Qt.Key_Period] = "Period"
        map[Qt.Key_Slash] = "Slash"; map[Qt.Key_Backslash] = "Backslash"
        map[Qt.Key_Semicolon] = "Semicolon"; map[Qt.Key_Apostrophe] = "Apostrophe"
        map[Qt.Key_BracketLeft] = "BracketLeft"; map[Qt.Key_BracketRight] = "BracketRight"
        map[Qt.Key_Minus] = "Minus"; map[Qt.Key_Equal] = "Equal"
        map[Qt.Key_QuoteLeft] = "Grave"; map[Qt.Key_Print] = "Print"
        map[Qt.Key_Pause] = "Pause"; map[Qt.Key_ScrollLock] = "Scroll_Lock"
        map[Qt.Key_CapsLock] = "Caps_Lock"; map[Qt.Key_NumLock] = "Num_Lock"
        // Media keys
        map[Qt.Key_VolumeUp] = "XF86AudioRaiseVolume"
        map[Qt.Key_VolumeDown] = "XF86AudioLowerVolume"
        map[Qt.Key_VolumeMute] = "XF86AudioMute"
        map[Qt.Key_MediaPlay] = "XF86AudioPlay"
        map[Qt.Key_MediaPause] = "XF86AudioPause"
        map[Qt.Key_MediaNext] = "XF86AudioNext"
        map[Qt.Key_MediaPrevious] = "XF86AudioPrev"
        map[Qt.Key_MonBrightnessUp] = "XF86MonBrightnessUp"
        map[Qt.Key_MonBrightnessDown] = "XF86MonBrightnessDown"
        return map[key] ?? null
    }

    function parseComboString(str) {
        if (!str || str.trim() === "") return { mods: [], key: "" }
        var parts = str.split("+").map(s => s.trim()).filter(s => s.length > 0)
        var modNames = ["Super", "Ctrl", "Alt", "Shift", "Mod"]
        var mods = []
        var key = ""
        for (var i = 0; i < parts.length; i++) {
            var p = parts[i]
            if (p === "Mod") {
                mods.push("Super")
            } else if (modNames.indexOf(p) >= 0) {
                mods.push(p)
            } else {
                key = p
            }
        }
        return { mods: mods, key: key }
    }

    // ── Status bar ───────────────────────────────────────────────────
    SettingsCardSection {
        expanded: true
        icon: root.hasEditCapability ? "check_circle" : "info"
        title: root.hasEditCapability
            ? Translation.tr("Keybinds loaded — editing enabled")
            : (root.categories.length > 0
                ? Translation.tr("Keybinds loaded (read-only)")
                : Translation.tr("No keybinds data available"))
        visible: CompositorService.isNiri

        SettingsGroup {
            StyledText {
                Layout.fillWidth: true
                text: root.hasEditCapability
                    ? (root.keybindsData?.configPath ?? Translation.tr("Config path unknown"))
                    : (!IidSocket.connected
                        ? Translation.tr("iNiR daemon (iid) is not running. Start it for editing capabilities.")
                        : Translation.tr("Daemon connected but keybind data unavailable. Read-only mode via NiriKeybinds."))
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
                wrapMode: Text.WordWrap
            }
        }
    }

    // ── Categories ───────────────────────────────────────────────────
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 16

        Repeater {
            model: root.categories

            delegate: SettingsCardSection {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                expanded: true

                readonly property int catIdx: index
                readonly property string catName: modelData.name ?? ""
                readonly property var categoryKeybinds: modelData.children?.[0]?.keybinds ?? []

                icon: root.getCategoryIcon(modelData.name)
                title: modelData.name

                SettingsGroup {
                    Layout.fillWidth: true

                    Repeater {
                        model: categoryKeybinds

                        delegate: EditableKeybindRow {
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            categoryIndex: catIdx
                            keybindIndex: index
                            mods: modelData.mods ?? []
                            keyName: modelData.key ?? modelData.rawKey ?? ""
                            rawKey: modelData.rawKey ?? modelData.key ?? ""
                            comment: modelData.comment ?? ""
                            action: modelData.action ?? ""
                            options: modelData.options ?? ({})
                            showDivider: index < categoryKeybinds.length - 1
                            editable: root.hasEditCapability
                            categoryName: catName
                        }
                    }
                }
            }
        }
    }

    // ── Add Keybind section ──────────────────────────────────────────
    SettingsCardSection {
        visible: root.hasEditCapability
        expanded: true
        icon: "add_circle"
        title: Translation.tr("Add Keybind")

        SettingsGroup {
            // FAB-style open button
            RippleButton {
                visible: !root.addFormOpen
                Layout.fillWidth: true
                Layout.preferredHeight: 44

                contentItem: RowLayout {
                    spacing: 8
                    Item { Layout.fillWidth: true }
                    MaterialSymbol {
                        text: "add"
                        iconSize: Appearance.font.pixelSize.larger
                        color: Appearance.m3colors.m3onPrimary
                    }
                    StyledText {
                        text: Translation.tr("New Keybind")
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.DemiBold
                        color: Appearance.m3colors.m3onPrimary
                    }
                    Item { Layout.fillWidth: true }
                }

                background: Rectangle {
                    radius: Appearance.rounding.normal
                    color: Appearance.m3colors.m3primary
                }

                onClicked: {
                    root.editingCategoryIndex = -1
                    root.editingKeybindIndex = -1
                    root.addFormOpen = true
                }
            }

            // Add form
            KeybindEditForm {
                id: addForm
                visible: root.addFormOpen
                Layout.fillWidth: true
                isNew: true

                onSave: function(mods, key, action, description, options) {
                    IidSocket.addKeybind(mods, key, action, options, description)
                    root.addFormOpen = false
                    addForm.reset()
                }
                onCancel: {
                    root.addFormOpen = false
                    addForm.reset()
                }
            }
        }
    }

    Item { Layout.preferredHeight: 20 }

    // ── Delete confirmation auto-cancel timer ────────────────────────
    Timer {
        id: deleteCancelTimer
        interval: 3000
        repeat: false
        onTriggered: {
            root.deleteCategoryIndex = -1
            root.deleteKeybindIndex = -1
        }
    }

    // ══════════════════════════════════════════════════════════════════
    // Components
    // ══════════════════════════════════════════════════════════════════

    // ── Key Badge ────────────────────────────────────────────────────
    component KeyBadge: Rectangle {
        property string keyText: ""

        implicitWidth: Math.max(keyLabel.implicitWidth + 10, 26)
        implicitHeight: 22
        radius: Appearance.rounding.small
        color: Appearance.colors.colSurfaceContainerHigh ?? Appearance.colors.colLayer1
        border.width: 1
        border.color: Appearance.m3colors.m3outlineVariant ?? CF.ColorUtils.transparentize(Appearance.colors.colOnLayer1, 0.85)

        StyledText {
            id: keyLabel
            anchors.centerIn: parent
            text: keyText
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.family: Appearance.font.family.monospace
            color: Appearance.colors.colOnLayer1
        }
    }

    // ── Editable Keybind Row ─────────────────────────────────────────
    component EditableKeybindRow: Item {
        id: kbRow
        property var mods: []
        property string keyName: ""
        property string rawKey: ""
        property string comment: ""
        property string action: ""
        property var options: ({})
        property bool showDivider: true
        property bool editable: false
        property int categoryIndex: -1
        property int keybindIndex: -1
        property string categoryName: ""

        readonly property bool isEditing: root.editingCategoryIndex === categoryIndex && root.editingKeybindIndex === keybindIndex
        readonly property bool isDeleting: root.deleteCategoryIndex === categoryIndex && root.deleteKeybindIndex === keybindIndex

        property int _searchId: -1

        function _buildComboString() {
            var parts = kbRow.mods.map(function(m) { return m === "Super" ? "Mod" : m; });
            if (kbRow.keyName.length > 0)
                parts.push(kbRow.keyName);
            return parts.join("+");
        }

        Component.onCompleted: {
            if (typeof SettingsSearchRegistry === "undefined")
                return;
            var combo = _buildComboString();
            _searchId = SettingsSearchRegistry.registerOption({
                control: kbRow,
                pageIndex: root.settingsPageIndex,
                pageName: root.settingsPageName || "",
                section: kbRow.categoryName,
                label: kbRow.comment || kbRow.action || combo,
                description: combo,
                keywords: [combo, kbRow.action, kbRow.comment, kbRow.categoryName].filter(function(s) { return s && s.length > 0; })
            });
        }

        Component.onDestruction: {
            if (typeof SettingsSearchRegistry !== "undefined")
                SettingsSearchRegistry.unregisterControl(kbRow);
        }

        implicitHeight: rowColumn.implicitHeight

        ColumnLayout {
            id: rowColumn
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 0

            // Main row
            Item {
                Layout.fillWidth: true
                implicitHeight: 40

                Rectangle {
                    anchors.fill: parent
                    color: rowMouse.containsMouse ? Appearance.colors.colLayer1Hover : "transparent"
                    radius: Appearance.rounding.small
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 12

                    // Key badges
                    Row {
                        Layout.preferredWidth: 200
                        Layout.minimumWidth: 150
                        spacing: 4

                        Repeater {
                            model: kbRow.mods
                            delegate: KeyBadge {
                                required property var modelData
                                keyText: root.keySubstitutions[modelData] ?? modelData
                            }
                        }

                        StyledText {
                            visible: kbRow.mods.length > 0 && kbRow.keyName.length > 0
                            text: "+"
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.small
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        KeyBadge {
                            visible: kbRow.keyName.length > 0
                            keyText: root.keySubstitutions[kbRow.keyName] ?? kbRow.keyName
                        }
                    }

                    // Comment / description
                    StyledText {
                        Layout.fillWidth: true
                        text: kbRow.comment
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer1
                        elide: Text.ElideRight
                    }

                    // Edit button
                    RippleButton {
                        visible: kbRow.editable && !kbRow.isEditing
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32

                        contentItem: MaterialSymbol {
                            text: "edit"
                            iconSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colSubtext
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            radius: Appearance.rounding.small
                            color: parent.hovered ? Appearance.colors.colLayer1Hover : "transparent"
                        }

                        onClicked: {
                            root.addFormOpen = false
                            root.deleteCategoryIndex = -1
                            root.deleteKeybindIndex = -1
                            root.editingCategoryIndex = kbRow.categoryIndex
                            root.editingKeybindIndex = kbRow.keybindIndex
                        }
                    }

                    // Delete button / confirmation
                    Item {
                        visible: kbRow.editable
                        Layout.preferredWidth: kbRow.isDeleting ? deleteConfirmRow.implicitWidth : 32
                        Layout.preferredHeight: 32

                        // Normal delete button
                        RippleButton {
                            visible: !kbRow.isDeleting
                            anchors.fill: parent

                            contentItem: MaterialSymbol {
                                text: "delete_outline"
                                iconSize: Appearance.font.pixelSize.normal
                                color: CF.ColorUtils.transparentize(Appearance.colors.colError, 0.4)
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                radius: Appearance.rounding.small
                                color: parent.hovered ? CF.ColorUtils.transparentize(Appearance.colors.colError, 0.9) : "transparent"
                            }

                            onClicked: {
                                root.deleteCategoryIndex = kbRow.categoryIndex
                                root.deleteKeybindIndex = kbRow.keybindIndex
                                deleteCancelTimer.restart()
                            }
                        }

                        // Delete confirmation
                        RowLayout {
                            id: deleteConfirmRow
                            visible: kbRow.isDeleting
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            StyledText {
                                text: Translation.tr("Delete?")
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colError
                                font.weight: Font.DemiBold
                            }

                            RippleButton {
                                Layout.preferredWidth: 28
                                Layout.preferredHeight: 28
                                contentItem: MaterialSymbol {
                                    text: "check"
                                    iconSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colError
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle {
                                    radius: Appearance.rounding.small
                                    color: parent.hovered ? CF.ColorUtils.transparentize(Appearance.colors.colError, 0.9) : "transparent"
                                }
                                onClicked: {
                                    var combo = root.buildOriginalCombo(kbRow.mods, kbRow.rawKey || kbRow.keyName)
                                    IidSocket.removeKeybind(combo)
                                    root.deleteCategoryIndex = -1
                                    root.deleteKeybindIndex = -1
                                    deleteCancelTimer.stop()
                                }
                            }

                            RippleButton {
                                Layout.preferredWidth: 28
                                Layout.preferredHeight: 28
                                contentItem: MaterialSymbol {
                                    text: "close"
                                    iconSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colSubtext
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle {
                                    radius: Appearance.rounding.small
                                    color: parent.hovered ? Appearance.colors.colLayer1Hover : "transparent"
                                }
                                onClicked: {
                                    root.deleteCategoryIndex = -1
                                    root.deleteKeybindIndex = -1
                                    deleteCancelTimer.stop()
                                }
                            }
                        }
                    }
                }
            }

            // Edit form (inline expansion)
            KeybindEditForm {
                visible: kbRow.isEditing
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                Layout.topMargin: 4
                Layout.bottomMargin: 8
                isNew: false
                initialMods: kbRow.mods
                initialKey: kbRow.rawKey || kbRow.keyName
                initialAction: kbRow.action
                initialDescription: kbRow.comment
                initialRepeat: kbRow.options?.repeat ?? true
                initialAllowWhenLocked: kbRow.options?.allow_when_locked ?? false

                onSave: function(mods, key, action, description, options) {
                    var originalCombo = root.buildOriginalCombo(kbRow.mods, kbRow.rawKey || kbRow.keyName)
                    IidSocket.setKeybind(originalCombo, mods, key, action, options)
                    root.editingCategoryIndex = -1
                    root.editingKeybindIndex = -1
                }
                onCancel: {
                    root.editingCategoryIndex = -1
                    root.editingKeybindIndex = -1
                }
            }

            // Divider
            Rectangle {
                visible: kbRow.showDivider
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                height: 1
                color: Appearance.colors.colOutlineVariant
                opacity: 0.3
            }
        }
    }

    // ── Keybind Edit Form ────────────────────────────────────────────
    component KeybindEditForm: Rectangle {
        id: editForm
        property bool isNew: false
        property var initialMods: []
        property string initialKey: ""
        property string initialAction: ""
        property string initialDescription: ""
        property bool initialRepeat: true
        property bool initialAllowWhenLocked: false

        signal save(var mods, string key, string action, string description, var options)
        signal cancel()

        // Internal state
        property var currentMods: initialMods.slice()
        property string currentKey: initialKey
        property string currentAction: initialAction
        property string currentDescription: initialDescription
        property bool currentRepeat: initialRepeat
        property bool currentAllowWhenLocked: initialAllowWhenLocked
        property bool capturing: false

        implicitHeight: formColumn.implicitHeight + 24
        radius: Appearance.rounding.small
        color: Appearance.colors.colSurfaceContainerLow ?? CF.ColorUtils.transparentize(Appearance.colors.colLayer1, 0.5)
        border.width: 1
        border.color: Appearance.colors.colLayer0Border ?? CF.ColorUtils.transparentize(Appearance.colors.colOnLayer1, 0.9)

        function reset() {
            currentMods = isNew ? [] : initialMods.slice()
            currentKey = isNew ? "" : initialKey
            currentAction = isNew ? "" : initialAction
            currentDescription = isNew ? "" : initialDescription
            currentRepeat = isNew ? true : initialRepeat
            currentAllowWhenLocked = isNew ? false : initialAllowWhenLocked
            capturing = false
        }

        // Reset when becoming visible
        onVisibleChanged: {
            if (visible) reset()
        }

        // Key capture focus scope
        FocusScope {
            id: keyCaptureScope
            anchors.fill: parent
            focus: editForm.capturing
            activeFocusOnTab: true

            Keys.onPressed: (event) => {
                if (!editForm.capturing) return
                event.accepted = true

                // Escape cancels capture
                if (event.key === Qt.Key_Escape) {
                    editForm.capturing = false
                    return
                }

                // Build mod list
                var mods = []
                if (event.modifiers & Qt.ControlModifier) mods.push("Ctrl")
                if (event.modifiers & Qt.AltModifier) mods.push("Alt")
                if (event.modifiers & Qt.ShiftModifier) mods.push("Shift")
                if (event.modifiers & Qt.MetaModifier) mods.push("Super")

                // Skip if only a modifier key was pressed
                var modKeyCodes = [
                    Qt.Key_Control, Qt.Key_Alt, Qt.Key_Shift, Qt.Key_Meta,
                    Qt.Key_Super_L, Qt.Key_Super_R
                ]
                if (modKeyCodes.indexOf(event.key) >= 0) return

                var keyName = root.keyCodeToName(event.key)
                if (keyName) {
                    editForm.currentMods = mods
                    editForm.currentKey = keyName
                    editForm.capturing = false
                }
            }
        }

        ColumnLayout {
            id: formColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 10

            // Row 1: Key combo capture
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                StyledText {
                    text: Translation.tr("Key Combination")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    font.weight: Font.DemiBold
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    // Capture button
                    RippleButton {
                        Layout.preferredHeight: 36
                        Layout.minimumWidth: 180

                        contentItem: RowLayout {
                            spacing: 6
                            anchors.margins: 8

                            MaterialSymbol {
                                visible: !editForm.capturing && editForm.currentKey === ""
                                text: "touch_app"
                                iconSize: Appearance.font.pixelSize.normal
                                color: Appearance.m3colors.m3primary
                            }

                            // Show captured combo as badges
                            Row {
                                visible: !editForm.capturing && editForm.currentKey !== ""
                                spacing: 3
                                Repeater {
                                    model: editForm.currentMods
                                    delegate: KeyBadge {
                                        required property var modelData
                                        keyText: root.keySubstitutions[modelData] ?? modelData
                                    }
                                }
                                StyledText {
                                    visible: editForm.currentMods.length > 0
                                    text: "+"
                                    color: Appearance.colors.colSubtext
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                KeyBadge {
                                    visible: editForm.currentKey !== ""
                                    keyText: root.keySubstitutions[editForm.currentKey] ?? editForm.currentKey
                                }
                            }

                            StyledText {
                                visible: editForm.capturing
                                text: Translation.tr("Press key combo...")
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.m3colors.m3primary
                                font.weight: Font.DemiBold

                                SequentialAnimation on opacity {
                                    running: editForm.capturing
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 0.4; duration: 300; easing.type: Easing.InOutQuad }
                                    NumberAnimation { to: 1.0; duration: 300; easing.type: Easing.InOutQuad }
                                }
                            }

                            StyledText {
                                visible: !editForm.capturing && editForm.currentKey === ""
                                text: Translation.tr("Click to capture...")
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.m3colors.m3primary
                            }
                        }

                        background: Rectangle {
                            radius: Appearance.rounding.small
                            color: editForm.capturing
                                ? CF.ColorUtils.transparentize(Appearance.m3colors.m3primary, 0.85)
                                : (parent.hovered ? Appearance.colors.colLayer1Hover : Appearance.colors.colLayer1)
                            border.width: editForm.capturing ? 2 : 1
                            border.color: editForm.capturing
                                ? Appearance.m3colors.m3primary
                                : Appearance.colors.colLayer0Border
                        }

                        onClicked: {
                            editForm.capturing = true
                            keyCaptureScope.forceActiveFocus()
                        }
                    }

                    StyledText {
                        text: Translation.tr("or")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }

                    // Manual text input
                    MaterialTextField {
                        id: manualKeyField
                        Layout.fillWidth: true
                        placeholderText: Translation.tr("e.g. Super+Shift+E")
                        text: {
                            if (editForm.currentKey === "") return ""
                            var parts = editForm.currentMods.slice()
                            parts.push(editForm.currentKey)
                            return parts.join("+")
                        }
                        onEditingFinished: {
                            var parsed = root.parseComboString(text)
                            editForm.currentMods = parsed.mods
                            editForm.currentKey = parsed.key
                            editForm.capturing = false
                        }
                    }
                }
            }

            // Row 2: Action
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                StyledText {
                    text: Translation.tr("Action")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    font.weight: Font.DemiBold
                }

                MaterialTextField {
                    id: actionField
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("e.g. spawn \"kitty\" or focus-workspace-down")
                    text: editForm.currentAction
                    onTextChanged: editForm.currentAction = text
                }
            }

            // Row 3: Description
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                StyledText {
                    text: Translation.tr("Description")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    font.weight: Font.DemiBold
                }

                MaterialTextField {
                    id: descField
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("What this shortcut does")
                    text: editForm.currentDescription
                    onTextChanged: editForm.currentDescription = text
                }
            }

            // Row 4: Options
            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                // Repeat toggle
                RippleButton {
                    Layout.preferredHeight: 32
                    readonly property bool isActive: editForm.currentRepeat

                    contentItem: RowLayout {
                        spacing: 6
                        anchors.margins: 8
                        MaterialSymbol {
                            text: parent.parent.isActive ? "check_box" : "check_box_outline_blank"
                            iconSize: Appearance.font.pixelSize.normal
                            color: parent.parent.isActive ? Appearance.m3colors.m3primary : Appearance.colors.colSubtext
                        }
                        StyledText {
                            text: Translation.tr("Repeat")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnLayer1
                        }
                    }
                    background: Rectangle {
                        radius: Appearance.rounding.small
                        color: parent.hovered ? Appearance.colors.colLayer1Hover : "transparent"
                    }
                    onClicked: editForm.currentRepeat = !editForm.currentRepeat
                }

                // Allow when locked toggle
                RippleButton {
                    Layout.preferredHeight: 32
                    readonly property bool isActive: editForm.currentAllowWhenLocked

                    contentItem: RowLayout {
                        spacing: 6
                        anchors.margins: 8
                        MaterialSymbol {
                            text: parent.parent.isActive ? "check_box" : "check_box_outline_blank"
                            iconSize: Appearance.font.pixelSize.normal
                            color: parent.parent.isActive ? Appearance.m3colors.m3primary : Appearance.colors.colSubtext
                        }
                        StyledText {
                            text: Translation.tr("Allow when locked")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnLayer1
                        }
                    }
                    background: Rectangle {
                        radius: Appearance.rounding.small
                        color: parent.hovered ? Appearance.colors.colLayer1Hover : "transparent"
                    }
                    onClicked: editForm.currentAllowWhenLocked = !editForm.currentAllowWhenLocked
                }

                Item { Layout.fillWidth: true }
            }

            // Row 5: Buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Item { Layout.fillWidth: true }

                RippleButton {
                    Layout.preferredHeight: 36
                    Layout.preferredWidth: 90

                    contentItem: StyledText {
                        text: Translation.tr("Cancel")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer1
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: Appearance.rounding.small
                        color: parent.hovered ? Appearance.colors.colLayer1Hover : Appearance.colors.colLayer1
                        border.width: 1
                        border.color: Appearance.colors.colLayer0Border
                    }
                    onClicked: editForm.cancel()
                }

                RippleButton {
                    Layout.preferredHeight: 36
                    Layout.preferredWidth: 90
                    enabled: editForm.currentKey !== "" && editForm.currentAction !== ""

                    contentItem: StyledText {
                        text: Translation.tr("Save")
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.DemiBold
                        color: parent.enabled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colSubtext
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: Appearance.rounding.small
                        color: parent.enabled
                            ? (parent.hovered ? Appearance.colors.colPrimaryHover : Appearance.m3colors.m3primary)
                            : Appearance.colors.colLayer1
                        border.width: parent.enabled ? 0 : 1
                        border.color: Appearance.colors.colLayer0Border
                    }
                    onClicked: {
                        if (!enabled) return
                        editForm.save(
                            editForm.currentMods,
                            editForm.currentKey,
                            editForm.currentAction,
                            editForm.currentDescription,
                            {
                                repeat: editForm.currentRepeat,
                                allow_when_locked: editForm.currentAllowWhenLocked
                            }
                        )
                    }
                }
            }
        }
    }
}
