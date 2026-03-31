pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Module override system — allows plugins to replace major UI components.
 *
 * Inspired by nucleus-shell's Contracts pattern, adapted for iNiR.
 * Each "slot" represents a replaceable panel/module. Plugins can override
 * a slot by providing an alternative QML file.
 *
 * Usage from a plugin's Main.qml:
 *   Component.onCompleted: {
 *       Contracts.bar.override(Qt.resolvedUrl("./MyBar.qml"))
 *   }
 *
 * Usage from ShellIiPanels.qml:
 *   Loader {
 *       active: Contracts.bar.overridden
 *       source: Contracts.bar.source
 *   }
 */
Singleton {
    id: root

    IpcHandler {
        target: "contracts"
        function list(): string { return root.getSlotList() }
        function reset(): void { root.resetAll() }
    }

    // ─── CONTRACT SLOTS ───
    // Only user-facing, replaceable panels. Infrastructure (polkit, session, corners, etc.) excluded.
    readonly property ContractSlot bar: ContractSlot { slotName: "bar" }
    readonly property ContractSlot sidebarLeft: ContractSlot { slotName: "sidebarLeft" }
    readonly property ContractSlot sidebarRight: ContractSlot { slotName: "sidebarRight" }
    readonly property ContractSlot dock: ContractSlot { slotName: "dock" }
    readonly property ContractSlot background: ContractSlot { slotName: "background" }
    readonly property ContractSlot mediaControls: ContractSlot { slotName: "mediaControls" }
    readonly property ContractSlot lock: ContractSlot { slotName: "lock" }
    readonly property ContractSlot controlPanel: ContractSlot { slotName: "controlPanel" }

    readonly property var _allSlots: [bar, sidebarLeft, sidebarRight, dock, background, mediaControls, lock, controlPanel]

    function getSlotList(): string {
        const result = _allSlots.map(s => ({
            name: s.slotName,
            overridden: s.overridden,
            disabled: s.disabled,
            source: s.overridden ? s.source.toString() : "(default)"
        }))
        return JSON.stringify(result, null, 2)
    }

    function resetAll() {
        for (const slot of _allSlots) slot.reset()
        console.log("[Contracts] All slots reset to defaults")
    }

    // Resolve a slot by name (used by PluginRegistry)
    function getSlot(name: string): var {
        for (const slot of _allSlots) {
            if (slot.slotName === name) return slot
        }
        console.warn("[Contracts] Unknown slot:", name)
        return null
    }

    component ContractSlot: QtObject {
        required property string slotName
        property url source: ""
        property bool overridden: false
        property bool disabled: false

        // Whether this slot should load (not disabled, and either overridden or using default)
        readonly property bool active: !disabled

        function override(newSource: url): void {
            source = newSource
            overridden = true
            console.log("[Contracts]", slotName, "overridden →", newSource)
        }

        function disable(): void {
            disabled = true
            console.log("[Contracts]", slotName, "disabled")
        }

        function reset(): void {
            source = ""
            overridden = false
            disabled = false
        }
    }
}
