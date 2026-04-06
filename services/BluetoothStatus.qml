pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import QtQuick
import qs.services
import qs.modules.common

/**
 * Bluetooth status service.
 */
Singleton {
    id: root

    readonly property bool available: Bluetooth.adapters.values.length > 0
    readonly property bool enabled: Bluetooth.defaultAdapter?.enabled ?? false
    readonly property BluetoothDevice firstActiveDevice: Bluetooth.defaultAdapter?.devices.values.find(device => device.connected) ?? null
    readonly property int activeDeviceCount: Bluetooth.defaultAdapter?.devices.values.filter(device => device.connected).length ?? 0
    readonly property bool connected: Bluetooth.devices.values.some(d => d.connected)

    // Track connection count changes for sound feedback
    property int _previousDeviceCount: 0
    onActiveDeviceCountChanged: {
        // Skip initial load (count goes from 0 to N on startup)
        if (!_btReady) return;
        if (activeDeviceCount > _previousDeviceCount) {
            if (Config.options?.sounds?.bluetooth ?? true)
                Audio.playSystemSound("device-added")
        } else if (activeDeviceCount < _previousDeviceCount) {
            if (Config.options?.sounds?.bluetooth ?? true)
                Audio.playSystemSound("device-removed")
        }
        _previousDeviceCount = activeDeviceCount;
    }
    property bool _btReady: false
    Timer {
        interval: 3000
        running: true
        onTriggered: {
            root._previousDeviceCount = root.activeDeviceCount;
            root._btReady = true;
        }
    }
}
