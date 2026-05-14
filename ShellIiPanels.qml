import qs.modules.background
import qs.modules.bar
import qs.modules.cheatsheet
import qs.modules.controlPanel
import qs.modules.dock
import qs.modules.lock
import qs.modules.mediaControls
import qs.modules.notificationPopup
import qs.modules.onScreenDisplay
import qs.modules.onScreenKeyboard
import qs.modules.overview
import qs.modules.polkit
import qs.modules.regionSelector
import qs.modules.screenCorners
import qs.modules.sessionScreen
import qs.modules.sidebarLeft
import qs.modules.sidebarRight
import qs.modules.tilingOverlay
import qs.modules.verticalBar
import qs.modules.wallpaperSelector
import qs.modules.ii.overlay
import qs.modules.shellUpdate
import "modules/clipboard" as ClipboardModule

import QtQuick
import Quickshell
import qs.modules.common
import qs.services

Item {
    // Simple loader for panels without contract slots
    component PanelLoader: LazyLoader {
        required property string identifier
        property bool extraCondition: true
        active: Config.ready && (Config.options?.enabledPanels ?? []).includes(identifier) && extraCondition
    }

    // Contract-aware loader for panels with a Contracts slot.
    // When the slot is overridden by a plugin, loads the override source instead of the default.
    component ContractPanelLoader: Item {
        id: cpl
        required property string identifier
        required property string slotName
        required property Component defaultComponent
        property bool extraCondition: true

        readonly property var _slot: Contracts.getSlot(slotName)
        readonly property bool _enabled: Config.ready
            && (Config.options?.enabledPanels ?? []).includes(cpl.identifier)
            && cpl.extraCondition
            && cpl._slot !== null && cpl._slot.active

        // Override loader — active only when a plugin has overridden this slot
        LazyLoader {
            active: cpl._enabled && cpl._slot.overridden
            component: Loader { source: cpl._slot.source }
        }

        // Default loader — active when the slot is NOT overridden
        LazyLoader {
            active: cpl._enabled && !cpl._slot.overridden
            component: cpl.defaultComponent
        }
    }

    // ── Contract-aware panels (8 slots) ──
    ContractPanelLoader {
        identifier: "iiBar"; slotName: "bar"
        extraCondition: !(Config.options?.bar?.vertical ?? false)
        defaultComponent: Bar {}
    }
    ContractPanelLoader {
        identifier: "iiVerticalBar"; slotName: "bar"
        extraCondition: Config.options?.bar?.vertical ?? false
        defaultComponent: VerticalBar {}
    }
    ContractPanelLoader { identifier: "iiBackground"; slotName: "background"; defaultComponent: Background {} }
    ContractPanelLoader { identifier: "iiDock"; slotName: "dock"; extraCondition: Config.options?.dock?.enable ?? true; defaultComponent: Dock {} }
    ContractPanelLoader { identifier: "iiLock"; slotName: "lock"; defaultComponent: Lock {} }
    ContractPanelLoader { identifier: "iiMediaControls"; slotName: "mediaControls"; defaultComponent: MediaControls {} }
    ContractPanelLoader { identifier: "iiSidebarLeft"; slotName: "sidebarLeft"; defaultComponent: SidebarLeft {} }
    ContractPanelLoader { identifier: "iiSidebarRight"; slotName: "sidebarRight"; defaultComponent: SidebarRight {} }
    ContractPanelLoader { identifier: "iiControlPanel"; slotName: "controlPanel"; defaultComponent: ControlPanel {} }

    // ── Standard panels (no contract slots) ──
    PanelLoader { identifier: "iiBackdrop"; extraCondition: Config.options?.background?.backdrop?.enable ?? false; component: Backdrop {} }
    PanelLoader { identifier: "iiCheatsheet"; component: Cheatsheet {} }
    PanelLoader { identifier: "iiNotificationPopup"; component: NotificationPopup {} }
    PanelLoader { identifier: "iiOnScreenDisplay"; component: OnScreenDisplay {} }
    PanelLoader { identifier: "iiOnScreenKeyboard"; component: OnScreenKeyboard {} }
    PanelLoader { identifier: "iiOverlay"; component: Overlay {} }
    PanelLoader { identifier: "iiOverview"; component: Overview {} }
    PanelLoader { identifier: "iiPolkit"; component: Polkit {} }
    PanelLoader { identifier: "iiRegionSelector"; component: RegionSelector {} }
    PanelLoader { identifier: "iiScreenCorners"; component: ScreenCorners {} }
    PanelLoader { identifier: "iiSessionScreen"; component: SessionScreen {} }
    PanelLoader { identifier: "iiTilingOverlay"; component: TilingOverlay {} }
    PanelLoader { identifier: "iiWallpaperSelector"; component: WallpaperSelector {} }
    PanelLoader { identifier: "iiClipboard"; component: ClipboardModule.ClipboardPanel {} }
    PanelLoader { identifier: "iiShellUpdate"; component: ShellUpdateOverlay {} }
}
