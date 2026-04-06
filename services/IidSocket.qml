pragma Singleton

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * IidSocket — Client for the iid backend daemon.
 *
 * Connects to the iid Unix socket at $XDG_RUNTIME_DIR/iid.sock.
 * Provides request/response methods for display and input settings,
 * and receives event pushes for state changes.
 *
 * Usage:
 *   IidSocket.request("display.list", {}, result => { console.log(JSON.stringify(result)) })
 *   IidSocket.request("input.get", {}, result => { root.inputSettings = result })
 *   IidSocket.request("display.set_scale", {output: "DP-2", scale: 1.5})
 */
Singleton {
    id: root

    readonly property string socketPath: (Quickshell.env("XDG_RUNTIME_DIR") || "/run/user/1000") + "/iid.sock"

    // Connection state
    readonly property bool connected: socket.connected

    // Reactive state — updated on connect and on events
    property var displays: ({})       // Map<output_name, output_object> from display.list
    property var inputSettings: ({})  // {keyboard: {...}, touchpad: {...}, mouse: {...}} from input.get
    property var keybindsList: ({})   // Result from keybinds.list

    // Signals for event-driven updates
    signal displayChanged(string output)
    signal inputChanged()
    signal keybindsChanged()

    // Request ID counter
    property int _nextId: 1
    property var _pendingCallbacks: ({})  // Map<id, callback_function>

    Component.onCompleted: {
        socket.connected = true
    }

    DankSocket {
        id: socket
        path: root.socketPath
        reconnectBaseMs: 1000
        reconnectMaxMs: 10000

        onConnectionStateChanged: {
            if (connected) {
                console.log("IidSocket: Connected to iid daemon")
                root._refreshAll()
            } else {
                console.warn("IidSocket: Disconnected from iid daemon")
            }
        }

        parser: SplitParser {
            onRead: line => {
                try {
                    const msg = JSON.parse(line)

                    // Event push (no id)
                    if (msg.event) {
                        root._handleEvent(msg.event, msg.data || {})
                        return
                    }

                    // Response to a request
                    if (msg.id !== undefined) {
                        const cb = root._pendingCallbacks[msg.id]
                        if (cb) {
                            delete root._pendingCallbacks[msg.id]
                            if (msg.error) {
                                console.warn("IidSocket: Error for request", msg.id, ":", msg.error)
                            } else {
                                cb(msg.result)
                            }
                        }
                    }
                } catch (e) {
                    console.warn("IidSocket: Failed to parse:", line, e)
                }
            }
        }
    }

    // -------------------------------------------------------------------------
    // PUBLIC API
    // -------------------------------------------------------------------------

    /**
     * Send a request to the daemon.
     * @param method  e.g. "display.list", "input.set_touchpad"
     * @param params  Object with method parameters
     * @param callback  Optional function(result) called on success
     */
    function request(method, params, callback) {
        if (!socket.connected) {
            console.warn("IidSocket: Not connected, dropping request:", method)
            return
        }

        const id = root._nextId++
        if (callback) {
            root._pendingCallbacks[id] = callback
        }

        socket.send({
            method: method,
            params: params || {},
            id: id
        })
    }

    // -- Display shortcuts --

    function refreshDisplays() {
        request("display.list", {}, result => {
            root.displays = result
        })
    }

    function setDisplayMode(output, width, height, refresh) {
        request("display.set_mode", {
            output: output,
            width: width,
            height: height,
            refresh: refresh
        })
    }

    function setDisplayScale(output, scale) {
        request("display.set_scale", {
            output: output,
            scale: scale
        })
    }

    function setDisplayTransform(output, transform) {
        request("display.set_transform", {
            output: output,
            transform: transform
        })
    }

    function setDisplayVrr(output, enabled) {
        request("display.set_vrr", {
            output: output,
            enabled: enabled
        })
    }

    function setDisplayPosition(output, x, y) {
        request("display.set_position", {
            output: output,
            x: x,
            y: y
        })
    }

    // -- Input shortcuts --

    function refreshInput() {
        request("input.get", {}, result => {
            root.inputSettings = result
        })
    }

    function setTouchpad(settings) {
        request("input.set_touchpad", settings)
    }

    function setMouse(settings) {
        request("input.set_mouse", settings)
    }

    function setKeyboard(settings) {
        request("input.set_keyboard", settings)
    }

    // -- Keybind shortcuts --

    function refreshKeybinds() {
        request("keybinds.list", {}, result => {
            root.keybindsList = result
        })
    }

    function setKeybind(originalKey, mods, key, action, options) {
        request("keybinds.set", {
            originalKey: originalKey,
            mods: mods,
            key: key,
            action: action,
            options: options ?? {}
        }, () => refreshKeybinds())
    }

    function addKeybind(mods, key, action, options, comment) {
        request("keybinds.add", {
            mods: mods,
            key: key,
            action: action,
            options: options ?? {},
            comment: comment ?? ""
        }, () => refreshKeybinds())
    }

    function removeKeybind(keyCombo) {
        request("keybinds.remove", {
            keyCombo: keyCombo
        }, () => refreshKeybinds())
    }

    // -------------------------------------------------------------------------
    // INTERNALS
    // -------------------------------------------------------------------------

    function _refreshAll() {
        refreshDisplays()
        refreshInput()
        refreshKeybinds()
    }

    function _handleEvent(eventName, data) {
        switch (eventName) {
        case "display.changed":
            refreshDisplays()
            displayChanged(data.output || "")
            break
        case "input.changed":
            refreshInput()
            inputChanged()
            break
        case "keybinds.changed":
            refreshKeybinds()
            keybindsChanged()
            break
        default:
            console.log("IidSocket: Unknown event:", eventName)
        }
    }
}
