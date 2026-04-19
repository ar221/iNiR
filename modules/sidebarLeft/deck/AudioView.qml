pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

/**
 * AudioView — Audio FX tab for the Deck sidebar (View 3).
 *
 * Binds entirely to the EasyEffects singleton. No direct socket access.
 *
 * Layout:
 *   Status row: connection dot + label + bypass toggle
 *   Preset chips (horizontal scroll)
 *   Plugin cards (equalizer, compressor, limiter, reverb, crystalizer)
 *     gated by Config.options?.sidebar?.deck?.audioFX?.plugins
 *
 * Signals:
 *   editEqRequested() — wired in DeckSurface to expand the EQ editor
 */
Item {
    id: root

    signal editEqRequested()

    // ── Config helpers ────────────────────────────────────────────────────────
    readonly property bool _showSliders:    Config.options?.sidebar?.deck?.audioFX?.showSliders    ?? true
    readonly property bool _showEqEditor:   Config.options?.sidebar?.deck?.audioFX?.showEqEditor   ?? true
    readonly property bool _showEqualizer:  Config.options?.sidebar?.deck?.audioFX?.plugins?.equalizer  ?? true
    readonly property bool _showCompressor: Config.options?.sidebar?.deck?.audioFX?.plugins?.compressor ?? true
    readonly property bool _showLimiter:    Config.options?.sidebar?.deck?.audioFX?.plugins?.limiter    ?? true
    readonly property bool _showReverb:     Config.options?.sidebar?.deck?.audioFX?.plugins?.reverb     ?? false
    readonly property bool _showCrystalizer:Config.options?.sidebar?.deck?.audioFX?.plugins?.crystalizer?? false

    // ── Not-available empty state ─────────────────────────────────────────────
    Item {
        anchors.fill: parent
        visible: !EasyEffects.available

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 12

            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                text: "equalizer"
                iconSize: 48
                color: ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.20)
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "EasyEffects not found"
                font.pixelSize: 13
                font.weight: Font.Medium
                color: ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.55)
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 200
                text: "Install EasyEffects to use Audio FX controls"
                font.pixelSize: 11
                color: ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.35)
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    // ── Main content ──────────────────────────────────────────────────────────
    Flickable {
        anchors.fill: parent
        visible: EasyEffects.available
        contentWidth: width
        contentHeight: mainColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: StyledScrollBar {
            policy: contentHeight > height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
        }

        ColumnLayout {
            id: mainColumn
            width: parent.width
            spacing: 8

            // ── Status + Bypass header ────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: statusRow.implicitHeight + 16
                color: Appearance.colors.colLayer1
                radius: Appearance.rounding.normal

                RowLayout {
                    id: statusRow
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: 12
                        rightMargin: 12
                    }
                    spacing: 8

                    // Connection status dot
                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: {
                            if (EasyEffects.socketConnected) return "#4caf50"
                            if (EasyEffects.active)          return "#ff9800"
                            return ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.30)
                        }

                        Behavior on color {
                            enabled: Appearance.animationsEnabled
                            ColorAnimation { duration: 200 }
                        }
                    }

                    // Label
                    Text {
                        Layout.fillWidth: true
                        text: "EasyEffects"
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        font.family: Appearance.font.family.main
                        color: Appearance.colors.colOnSurface
                    }

                    // Bypass toggle button
                    Rectangle {
                        id: bypassBtn
                        implicitWidth: bypassRow.implicitWidth + 16
                        implicitHeight: 30
                        radius: Appearance.rounding.normal

                        // Active = NOT bypassed (chain is processing)
                        readonly property bool _isActive: EasyEffects.socketConnected && !EasyEffects.bypassed

                        color: _isActive
                            ? ColorUtils.applyAlpha(Appearance.colors.colPrimary, bypassMouse.containsMouse ? 0.20 : 0.12)
                            : ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, bypassMouse.containsMouse ? 0.15 : 0.08)

                        border.width: 1
                        border.color: _isActive
                            ? Appearance.colors.colPrimary
                            : ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.30)

                        opacity: EasyEffects.active ? 1.0 : 0.5

                        Behavior on color {
                            enabled: Appearance.animationsEnabled
                            ColorAnimation { duration: 120 }
                        }
                        Behavior on border.color {
                            enabled: Appearance.animationsEnabled
                            ColorAnimation { duration: 120 }
                        }

                        RowLayout {
                            id: bypassRow
                            anchors.centerIn: parent
                            spacing: 6

                            MaterialSymbol {
                                text: "power_settings_new"
                                iconSize: 14
                                color: bypassBtn._isActive
                                    ? Appearance.colors.colPrimary
                                    : ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.55)
                            }

                            Text {
                                text: EasyEffects.bypassed ? "Bypassed" : "Active"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                font.family: Appearance.font.family.main
                                color: bypassBtn._isActive
                                    ? Appearance.colors.colPrimary
                                    : ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.55)
                            }
                        }

                        MouseArea {
                            id: bypassMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: EasyEffects.active
                            onClicked: EasyEffects.toggleBypass()
                        }
                    }
                }
            }

            // ── Preset Switcher ───────────────────────────────────────────
            DeckDivider {}

            DeckLabel { text: "PRESETS" }

            // Empty state
            Text {
                Layout.fillWidth: true
                visible: EasyEffects.presets.length === 0
                text: "No presets saved — create one in EasyEffects"
                font.pixelSize: 11
                font.family: Appearance.font.family.main
                color: ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.40)
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                topPadding: 4
                bottomPadding: 4
            }

            // Horizontal chip row
            Item {
                Layout.fillWidth: true
                implicitHeight: presetScroll.implicitHeight
                visible: EasyEffects.presets.length > 0

                Flickable {
                    id: presetScroll
                    anchors.fill: parent
                    implicitHeight: presetRow.implicitHeight
                    contentWidth: presetRow.implicitWidth
                    contentHeight: presetRow.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.HorizontalFlick

                    Row {
                        id: presetRow
                        spacing: 6

                        Repeater {
                            model: EasyEffects.presets

                            Rectangle {
                                required property string modelData
                                required property int index

                                readonly property bool _isActive: EasyEffects.currentPreset === modelData

                                implicitWidth: chipLabel.implicitWidth + 20
                                implicitHeight: 28
                                radius: 14  // pill shape

                                color: _isActive
                                    ? Appearance.colors.colPrimary
                                    : Appearance.colors.colLayer1

                                border.width: 1
                                border.color: _isActive
                                    ? Appearance.colors.colPrimary
                                    : ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.20)

                                Behavior on color {
                                    enabled: Appearance.animationsEnabled
                                    ColorAnimation { duration: 150 }
                                }

                                Text {
                                    id: chipLabel
                                    anchors.centerIn: parent
                                    text: modelData
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    font.family: Appearance.font.family.main
                                    color: parent._isActive
                                        ? Appearance.m3colors.m3onPrimary
                                        : Appearance.colors.colOnSurfaceVariant
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    enabled: EasyEffects.socketConnected
                                    onClicked: EasyEffects.loadPreset(modelData)
                                }
                            }
                        }
                    }
                }
            }

            // ── Plugin Cards ──────────────────────────────────────────────
            DeckDivider {}

            DeckLabel { text: "PLUGINS" }

            // Equalizer card
            PluginCard {
                Layout.fillWidth: true
                visible: root._showEqualizer
                pluginName: "equalizer"
                displayName: "Equalizer"
                iconName: "equalizer"
                showEqEditorButton: root._showEqEditor
                onEditEqRequested: root.editEqRequested()
            }

            // Compressor card
            PluginCard {
                Layout.fillWidth: true
                visible: root._showCompressor
                pluginName: "compressor"
                displayName: "Compressor"
                iconName: "compress"
                showSliders: root._showSliders
                sliders: [
                    { prop: "threshold", label: "Threshold", min: -60, max: 0, suffix: " dB" },
                    { prop: "ratio",     label: "Ratio",     min: 1,   max: 20, suffix: ":1" }
                ]
            }

            // Limiter card
            PluginCard {
                Layout.fillWidth: true
                visible: root._showLimiter
                pluginName: "limiter"
                displayName: "Limiter"
                iconName: "volume_down"
                showSliders: root._showSliders
                sliders: [
                    { prop: "threshold", label: "Threshold", min: -60, max: 0, suffix: " dB" }
                ]
            }

            // Reverb card
            PluginCard {
                Layout.fillWidth: true
                visible: root._showReverb
                pluginName: "reverb"
                displayName: "Reverb"
                iconName: "waves"
                showSliders: root._showSliders
                sliders: [
                    { prop: "room_size", label: "Room Size", min: 0, max: 1, suffix: "" }
                ]
            }

            // Crystalizer card
            PluginCard {
                Layout.fillWidth: true
                visible: root._showCrystalizer
                pluginName: "crystalizer"
                displayName: "Crystalizer"
                iconName: "diamond"
            }

            // Bottom spacer
            Item { implicitHeight: 8 }
        }
    }

    // ── PluginCard — inline component ─────────────────────────────────────────
    component PluginCard: Rectangle {
        id: card

        required property string pluginName
        required property string displayName
        required property string iconName

        property bool   showSliders: false
        property bool   showEqEditorButton: false
        property var    sliders: []
        signal editEqRequested()

        // Local bypass state (start true = not bypassed = active)
        property bool _pluginBypassed: false

        implicitHeight: cardColumn.implicitHeight + 20
        color: Appearance.colors.colLayer1
        radius: Appearance.rounding.normal

        ColumnLayout {
            id: cardColumn
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: 12
                rightMargin: 12
            }
            spacing: 8

            // Card header: icon + name + bypass toggle
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                MaterialSymbol {
                    text: card.iconName
                    iconSize: 16
                    color: card._pluginBypassed
                        ? ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.40)
                        : Appearance.colors.colPrimary

                    Behavior on color {
                        enabled: Appearance.animationsEnabled
                        ColorAnimation { duration: 150 }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: card.displayName
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    font.family: Appearance.font.family.main
                    color: card._pluginBypassed
                        ? ColorUtils.applyAlpha(Appearance.colors.colOnSurface, 0.50)
                        : Appearance.colors.colOnSurface

                    Behavior on color {
                        enabled: Appearance.animationsEnabled
                        ColorAnimation { duration: 150 }
                    }
                }

                // Bypass toggle — small icon button
                Rectangle {
                    implicitWidth: 26
                    implicitHeight: 26
                    radius: 6

                    color: card._pluginBypassed
                        ? ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, pluginBypassMouse.containsMouse ? 0.15 : 0.08)
                        : ColorUtils.applyAlpha(Appearance.colors.colPrimary, pluginBypassMouse.containsMouse ? 0.20 : 0.10)

                    border.width: 1
                    border.color: card._pluginBypassed
                        ? ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.25)
                        : ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.50)

                    opacity: EasyEffects.socketConnected ? 1.0 : 0.4

                    Behavior on color { enabled: Appearance.animationsEnabled; ColorAnimation { duration: 120 } }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: card._pluginBypassed ? "pause_circle" : "play_circle"
                        iconSize: 14
                        color: card._pluginBypassed
                            ? ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.55)
                            : Appearance.colors.colPrimary
                    }

                    MouseArea {
                        id: pluginBypassMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: EasyEffects.socketConnected
                        onClicked: {
                            card._pluginBypassed = !card._pluginBypassed
                            EasyEffects.setPluginBypass(card.pluginName, card._pluginBypassed)
                        }
                    }
                }
            }

            // Property sliders
            Repeater {
                model: (card.showSliders && card.sliders.length > 0) ? card.sliders : []

                ColumnLayout {
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    spacing: 2

                    property real _sliderValue: (modelData.min + modelData.max) / 2

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            Layout.fillWidth: true
                            text: modelData.label
                            font.pixelSize: 10
                            font.family: Appearance.font.family.monospace
                            color: ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.60)
                        }

                        Text {
                            text: _sliderValue.toFixed(modelData.suffix.includes(":") ? 0 : 1) + modelData.suffix
                            font.pixelSize: 10
                            font.family: Appearance.font.family.numbers?.family ?? Appearance.font.family.monospace
                            color: ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.60)
                        }
                    }

                    // Track + fill
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 14

                        Rectangle {
                            id: sliderTrack
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            height: 3
                            radius: 2
                            color: ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.15)

                            // Fill
                            Rectangle {
                                width: sliderTrack.width * Math.max(0, Math.min(1,
                                    (_sliderValue - modelData.min) / (modelData.max - modelData.min)))
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                radius: parent.radius
                                color: card._pluginBypassed
                                    ? ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.35)
                                    : Appearance.colors.colPrimary
                            }

                            // Drag handle
                            Rectangle {
                                width: 10
                                height: 10
                                radius: 5
                                color: Appearance.colors.colPrimary
                                anchors.verticalCenter: parent.verticalCenter
                                x: sliderTrack.width * Math.max(0, Math.min(1,
                                    (_sliderValue - modelData.min) / (modelData.max - modelData.min))) - width / 2
                                opacity: card._pluginBypassed ? 0.5 : 1.0
                            }

                            MouseArea {
                                anchors.fill: parent
                                anchors.topMargin: -5
                                anchors.bottomMargin: -5
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: EasyEffects.socketConnected && !card._pluginBypassed

                                function _seek(mx) {
                                    const ratio = Math.max(0, Math.min(1, mx / sliderTrack.width))
                                    const val = modelData.min + ratio * (modelData.max - modelData.min)
                                    _sliderValue = val
                                    EasyEffects.setPluginProperty(card.pluginName, modelData.prop,
                                        modelData.suffix.includes(":") ? Math.round(val).toString() : val.toFixed(2))
                                }

                                onClicked: (e) => { _seek(e.x) }
                                onPositionChanged: (e) => { if (pressed) _seek(e.x) }
                            }
                        }
                    }
                }
            }

            // EQ editor button (equalizer card only)
            Rectangle {
                Layout.fillWidth: true
                visible: card.showEqEditorButton
                implicitHeight: 28
                radius: Appearance.rounding.normal
                color: eqEditorMouse.containsMouse
                    ? ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.12)
                    : ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.06)
                border.width: 1
                border.color: ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.30)
                opacity: EasyEffects.socketConnected ? 1.0 : 0.4

                Behavior on color { enabled: Appearance.animationsEnabled; ColorAnimation { duration: 120 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    MaterialSymbol {
                        text: "open_in_full"
                        iconSize: 13
                        color: Appearance.colors.colPrimary
                    }

                    Text {
                        text: "Open EQ Editor"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        font.family: Appearance.font.family.main
                        color: Appearance.colors.colPrimary
                    }
                }

                MouseArea {
                    id: eqEditorMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: card.editEqRequested()
                }
            }
        }
    }
}
