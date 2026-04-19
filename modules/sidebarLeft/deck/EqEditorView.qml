pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

/**
 * EqEditorView — Expanded EQ editor for the Deck sidebar.
 *
 * Displayed via DeckSurface.expand() when the user taps "Open EQ Editor"
 * from AudioView's Equalizer plugin card.
 *
 * Shows 8 band gain sliders. Values are sent live to EasyEffects via
 * EasyEffects.setPluginProperty("equalizer", "band<N>/gain", value).
 *
 * A "Save Preset" flow lets the user name and write a new preset JSON
 * via EasyEffects.writeAndLoadPreset().
 */
Item {
    id: root

    // Required by ExpandedSurface title mechanism
    property string expandTitle: "EQ Editor"

    // ── Band model ────────────────────────────────────────────────────────────
    // 8 bands at standard center frequencies.
    readonly property var _bands: [
        { label: "32Hz",   prop: "band0/gain",  freq: "32 Hz"  },
        { label: "64Hz",   prop: "band1/gain",  freq: "64 Hz"  },
        { label: "125Hz",  prop: "band2/gain",  freq: "125 Hz" },
        { label: "250Hz",  prop: "band3/gain",  freq: "250 Hz" },
        { label: "500Hz",  prop: "band4/gain",  freq: "500 Hz" },
        { label: "1kHz",   prop: "band5/gain",  freq: "1 kHz"  },
        { label: "4kHz",   prop: "band6/gain",  freq: "4 kHz"  },
        { label: "16kHz",  prop: "band7/gain",  freq: "16 kHz" }
    ]

    // Band gain values in dB (−12 to +12)
    property var _gains: [0, 0, 0, 0, 0, 0, 0, 0]

    // Preset name input state
    property string _presetNameInput: ""
    property bool   _showSaveInput: false

    // ── Layout ────────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // Connection warning
        Rectangle {
            Layout.fillWidth: true
            visible: !EasyEffects.socketConnected
            implicitHeight: warnRow.implicitHeight + 12
            color: ColorUtils.applyAlpha("#ff9800", 0.10)
            radius: Appearance.rounding.normal
            border.width: 1
            border.color: ColorUtils.applyAlpha("#ff9800", 0.35)

            RowLayout {
                id: warnRow
                anchors {
                    left: parent.left; right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: 12; rightMargin: 12
                }
                spacing: 8

                MaterialSymbol {
                    text: "warning"
                    iconSize: 14
                    color: "#ff9800"
                }

                Text {
                    Layout.fillWidth: true
                    text: "EasyEffects not connected — sliders are preview only"
                    font.pixelSize: 11
                    font.family: Appearance.font.family.main
                    color: "#ff9800"
                    wrapMode: Text.WordWrap
                }
            }
        }

        // EQ band sliders — horizontal bar chart style
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Row {
                anchors.fill: parent
                spacing: 4

                Repeater {
                    model: root._bands

                    Item {
                        required property var modelData
                        required property int index

                        width: (parent.width - (root._bands.length - 1) * 4) / root._bands.length
                        height: parent.height

                        readonly property real _gain: root._gains[index] ?? 0
                        // Normalize: 0 dB → 0.5 of height
                        readonly property real _ratio: Math.max(0, Math.min(1, (_gain + 12) / 24))

                        // Vertical slider track
                        Rectangle {
                            id: bandTrack
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 16
                            width: 6
                            height: parent.height - 40  // leave room for labels top+bottom
                            radius: 3
                            color: ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.12)

                            // Zero line
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: parent.height * 0.5 - height / 2
                                width: parent.width + 6
                                height: 1
                                color: ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.25)
                            }

                            // Fill from center to handle
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width
                                radius: parent.radius

                                readonly property real _handleY: bandTrack.height * (1 - _ratio) - 5
                                readonly property real _centerY: bandTrack.height * 0.5

                                y: Math.min(_handleY + 5, _centerY)
                                height: Math.abs(_centerY - (_handleY + 5))
                                color: _gain >= 0
                                    ? Appearance.colors.colPrimary
                                    : ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.55)
                            }

                            // Handle
                            Rectangle {
                                id: bandHandle
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: bandTrack.height * (1 - _ratio) - height / 2
                                width: 14
                                height: 14
                                radius: 7
                                color: Appearance.colors.colPrimary
                                opacity: EasyEffects.socketConnected ? 1.0 : 0.5
                            }

                            // Drag
                            MouseArea {
                                anchors.fill: parent
                                anchors.leftMargin: -12
                                anchors.rightMargin: -12
                                cursorShape: Qt.SizeVerCursor
                                hoverEnabled: true

                                function _apply(my) {
                                    const ratio = Math.max(0, Math.min(1, 1 - my / bandTrack.height))
                                    const gain = Math.round((ratio * 24 - 12) * 10) / 10
                                    var arr = root._gains.slice()
                                    arr[index] = gain
                                    root._gains = arr
                                    if (EasyEffects.socketConnected) {
                                        EasyEffects.setPluginProperty("equalizer", modelData.prop, gain.toFixed(1))
                                    }
                                }

                                onClicked: (e) => { _apply(e.y) }
                                onPositionChanged: (e) => { if (pressed) _apply(e.y) }
                            }
                        }

                        // Gain label (top)
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            text: (_gain >= 0 ? "+" : "") + _gain.toFixed(1)
                            font.pixelSize: 9
                            font.family: Appearance.font.family.numbers?.family ?? Appearance.font.family.monospace
                            color: ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.55)
                        }

                        // Frequency label (bottom)
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            text: modelData.label
                            font.pixelSize: 9
                            font.family: Appearance.font.family.monospace
                            color: ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.55)
                        }
                    }
                }
            }
        }

        // ── Reset + Save row ─────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Reset to flat
            Rectangle {
                implicitWidth: resetRow.implicitWidth + 20
                implicitHeight: 30
                radius: Appearance.rounding.normal
                color: resetMouse.containsMouse
                    ? ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.12)
                    : ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.06)
                border.width: 1
                border.color: ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.25)

                Behavior on color { enabled: Appearance.animationsEnabled; ColorAnimation { duration: 120 } }

                RowLayout {
                    id: resetRow
                    anchors.centerIn: parent
                    spacing: 6

                    MaterialSymbol { text: "restart_alt"; iconSize: 13; color: Appearance.colors.colOnSurfaceVariant }
                    Text {
                        text: "Reset"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        font.family: Appearance.font.family.main
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                }

                MouseArea {
                    id: resetMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root._gains = [0, 0, 0, 0, 0, 0, 0, 0]
                        if (EasyEffects.socketConnected) {
                            for (var i = 0; i < root._bands.length; i++) {
                                EasyEffects.setPluginProperty("equalizer", root._bands[i].prop, "0.0")
                            }
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Save preset toggle
            Rectangle {
                implicitWidth: saveRow.implicitWidth + 20
                implicitHeight: 30
                radius: Appearance.rounding.normal
                color: saveMouse.containsMouse
                    ? ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.18)
                    : ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.10)
                border.width: 1
                border.color: ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.40)

                Behavior on color { enabled: Appearance.animationsEnabled; ColorAnimation { duration: 120 } }

                RowLayout {
                    id: saveRow
                    anchors.centerIn: parent
                    spacing: 6

                    MaterialSymbol { text: "save"; iconSize: 13; color: Appearance.colors.colPrimary }
                    Text {
                        text: "Save Preset"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        font.family: Appearance.font.family.main
                        color: Appearance.colors.colPrimary
                    }
                }

                MouseArea {
                    id: saveMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root._showSaveInput = !root._showSaveInput
                }
            }
        }

        // ── Save preset name input ────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            visible: root._showSaveInput
            implicitHeight: 38
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1
            border.width: 1
            border.color: ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.40)

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 10
                    rightMargin: 6
                }
                spacing: 8

                TextInput {
                    id: presetNameInput
                    Layout.fillWidth: true
                    text: root._presetNameInput
                    font.pixelSize: 12
                    font.family: Appearance.font.family.main
                    color: Appearance.colors.colOnSurface
                    clip: true
                    selectByMouse: true
                    onTextChanged: root._presetNameInput = text

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        visible: presetNameInput.text.length === 0
                        text: "Preset name..."
                        font: presetNameInput.font
                        color: ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.40)
                    }
                }

                Rectangle {
                    implicitWidth: 60
                    implicitHeight: 26
                    radius: Appearance.rounding.normal
                    color: root._presetNameInput.trim().length > 0
                        ? (confirmSaveMouse.containsMouse
                            ? ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.20)
                            : ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.10))
                        : ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.08)
                    border.width: 1
                    border.color: root._presetNameInput.trim().length > 0
                        ? ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.40)
                        : ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.20)

                    Text {
                        anchors.centerIn: parent
                        text: "Save"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        font.family: Appearance.font.family.main
                        color: root._presetNameInput.trim().length > 0
                            ? Appearance.colors.colPrimary
                            : ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.40)
                    }

                    MouseArea {
                        id: confirmSaveMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: root._presetNameInput.trim().length > 0
                        onClicked: {
                            const name = root._presetNameInput.trim()
                            if (!name) return
                            // Build a minimal EasyEffects preset JSON with the 8 band gains
                            const bands = root._bands.map((b, i) => ({
                                frequency: [32, 64, 125, 250, 500, 1000, 4000, 16000][i],
                                gain: root._gains[i] ?? 0,
                                mode: "RLC (BT)",
                                mute: false,
                                q: 1.5,
                                slope: "x1",
                                solo: false,
                                type: i === 0 ? "Lo-shelf" : i === 7 ? "Hi-shelf" : "Bell"
                            }))
                            const preset = {
                                "output": {
                                    "equalizer": {
                                        "input-gain": 0,
                                        "output-gain": 0,
                                        "num-bands": 8,
                                        "mode": "IIR",
                                        "bands": bands
                                    }
                                }
                            }
                            EasyEffects.writeAndLoadPreset(name, JSON.stringify(preset, null, 2))
                            root._showSaveInput = false
                            root._presetNameInput = ""
                        }
                    }
                }
            }
        }
    }
}
