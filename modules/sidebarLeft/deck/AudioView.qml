pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services

/**
 * AudioView — Audio FX tab for the Deck sidebar (View 3).
 *
 * Binds entirely to the EasyEffects singleton. No direct socket access.
 *
 * v1 scope:
 *   - Bypass toggle (works via socket)
 *   - Preset chip switcher (works via socket)
 *   - Plugin cards: NOT WIRED. The EasyEffects socket protocol exposes
 *     load_preset / toggle_global_bypass but NOT per-plugin bypass or
 *     per-property mutation — those live inside preset JSONs. The PluginCard
 *     component is kept here so re-enabling it via config is one toggle, but
 *     all plugin defaults in config.json ship as `false`. EasyEffects.qml's
 *     setPluginBypass/setPluginProperty stubs warn-and-noop so misconfigured
 *     enables don't crash.
 *
 * Lifecycle:
 *   onVisibleChanged drives EasyEffects.pollEnabled — the 1.5s state poll
 *   only runs while this view is on-screen, so we don't burn cycles for the
 *   other Deck tabs.
 *
 * Signals:
 *   editEqRequested() — wired in DeckSurface to expand the EQ editor (future)
 */
Item {
    id: root

    // Kept as a noop signal — DeckSurface still references it. PluginCard
    // (the consumer that emitted this) was cut from v1; re-add together
    // if/when EQ editor flow returns.
    signal editEqRequested()

    // ── Bypass dim ────────────────────────────────────────────────────────
    // When the chain is bypassed, CURVE + CHAIN sections dim — they show
    // "what the chain WOULD do" but nothing's happening right now. LIVE meter
    // stays lit (system audio plays regardless of EE state) and PRESETS stays
    // lit + interactive (user may want to switch presets even while bypassed).
    property real _chainAlpha: EasyEffects.bypassed ? 0.35 : 1.0

    Behavior on _chainAlpha {
        enabled: Appearance.animationsEnabled
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    // ── Poll lifecycle: only ping the daemon while we're on-screen ──────────
    onVisibleChanged: {
        EasyEffects.pollEnabled = root.visible
        if (root.visible) {
            // Trigger an immediate refresh so the UI populates without waiting
            // for the next 1.5s tick.
            EasyEffects.refreshState()
            EasyEffects.refreshPresets()
        }
    }
    Component.onCompleted: {
        if (root.visible) {
            EasyEffects.pollEnabled = true
            EasyEffects.refreshState()
            EasyEffects.refreshPresets()
        }
    }
    Component.onDestruction: {
        EasyEffects.pollEnabled = false
    }

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
                font.pixelSize: Appearance.font.pixelSize.smallie
                font.weight: Font.Medium
                color: ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.55)
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 200
                text: "Install EasyEffects to use Audio FX controls"
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.35)
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    // ── Main content ──────────────────────────────────────────────────────────
    Flickable {
        id: mainFlick
        anchors.fill: parent
        visible: EasyEffects.available
        contentWidth: width
        contentHeight: mainColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: StyledScrollBar {
            policy: mainFlick.contentHeight > mainFlick.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
        }

        ColumnLayout {
            id: mainColumn
            width: parent.width
            spacing: 2

            // ── Status + Bypass header ────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: statusRow.implicitHeight + 10
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

                    // Connection status dot with pulse animation
                    // - colPrimary  → socket connected, ready (pulses)
                    // - colTertiary → daemon detected but socket not yet up
                    // - dim         → daemon not running
                    Item {
                        width: 8
                        height: 8

                        // Pulsing outer ring when connected
                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width * (EasyEffects.socketConnected ? 1.8 : 1.0)
                            height: parent.height * (EasyEffects.socketConnected ? 1.8 : 1.0)
                            radius: width / 2
                            color: "transparent"
                            border.width: 1
                            border.color: Appearance.colors.colPrimary
                            opacity: EasyEffects.socketConnected ? 0.0 : 0.0
                            visible: EasyEffects.socketConnected

                            SequentialAnimation on opacity {
                                running: EasyEffects.socketConnected
                                loops: Animation.Infinite
                                NumberAnimation { from: 0.5; to: 0.0; duration: 1200; easing.type: Easing.OutCubic }
                                PauseAnimation { duration: 300 }
                            }

                            SequentialAnimation on scale {
                                running: EasyEffects.socketConnected
                                loops: Animation.Infinite
                                NumberAnimation { from: 1.0; to: 1.4; duration: 1200; easing.type: Easing.OutCubic }
                                PauseAnimation { duration: 300 }
                            }
                        }

                        // Core dot
                        Rectangle {
                            anchors.centerIn: parent
                            width: 8
                            height: 8
                            radius: 4
                            color: {
                                if (EasyEffects.socketConnected) return Appearance.colors.colPrimary
                                if (EasyEffects.active)          return Appearance.m3colors.m3tertiary
                                return ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.30)
                            }

                            Behavior on color {
                                enabled: Appearance.animationsEnabled
                                ColorAnimation { duration: 200 }
                            }
                        }
                    }

                    // Label — show preset name if loaded, else the brand name.
                    Text {
                        Layout.fillWidth: true
                        text: EasyEffects.currentPreset.length > 0
                            ? EasyEffects.currentPreset
                            : "EasyEffects"
                        font.pixelSize: Appearance.font.pixelSize.smallie
                        font.weight: Font.Medium
                        font.family: Appearance.font.family.main
                        color: Appearance.colors.colOnSurface
                        elide: Text.ElideRight
                    }

                    // Bypass toggle button — instrument panel style
                    Rectangle {
                        id: bypassBtn
                        implicitWidth: bypassRow.implicitWidth + 20
                        implicitHeight: 32
                        radius: Appearance.rounding.small

                        // Active = NOT bypassed (chain is processing)
                        readonly property bool _isActive: EasyEffects.socketConnected && !EasyEffects.bypassed
                        property bool _toggleFlash: false

                        color: _isActive
                            ? ColorUtils.applyAlpha(Appearance.colors.colPrimary, bypassMouse.containsMouse ? 0.25 : 0.18)
                            : Appearance.colors.colSurfaceContainerHigh

                        border.width: _isActive ? 2 : 1
                        border.color: _isActive
                            ? Appearance.colors.colPrimary
                            : ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.25)

                        opacity: EasyEffects.active ? 1.0 : 0.5

                        // Inset shadow for inactive state
                        layer.enabled: !_isActive
                        layer.effect: Item {
                            Rectangle {
                                anchors.fill: parent
                                color: "transparent"
                                border.width: 1
                                border.color: ColorUtils.applyAlpha("#000000", 0.20)
                                radius: parent.radius
                            }
                        }

                        Behavior on color {
                            enabled: Appearance.animationsEnabled
                            ColorAnimation { duration: 150 }
                        }
                        Behavior on border.color {
                            enabled: Appearance.animationsEnabled
                            ColorAnimation { duration: 150 }
                        }
                        Behavior on border.width {
                            enabled: Appearance.animationsEnabled
                            NumberAnimation { duration: 150 }
                        }

                        // Outer glow when active
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: -2
                            radius: parent.radius + 1
                            color: "transparent"
                            border.width: 2
                            border.color: ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.35)
                            visible: parent._isActive
                            opacity: parent._isActive ? 1.0 : 0.0

                            Behavior on opacity {
                                enabled: Appearance.animationsEnabled
                                NumberAnimation { duration: 200 }
                            }
                        }

                        // Flash effect on toggle
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: Appearance.colors.colPrimary
                            opacity: parent._toggleFlash ? 0.4 : 0.0

                            Behavior on opacity {
                                enabled: Appearance.animationsEnabled
                                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                            }
                        }

                        RowLayout {
                            id: bypassRow
                            anchors.centerIn: parent
                            spacing: 7

                            MaterialSymbol {
                                text: "power_settings_new"
                                iconSize: 16
                                color: bypassBtn._isActive
                                    ? Appearance.colors.colPrimary
                                    : Appearance.colors.colOnSurface
                            }

                            Text {
                                text: EasyEffects.bypassed ? "BYPASSED" : "ACTIVE"
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                font.weight: Font.DemiBold
                                font.family: Appearance.font.family.mono
                                font.letterSpacing: 0.5
                                color: bypassBtn._isActive
                                    ? Appearance.colors.colPrimary
                                    : Appearance.colors.colOnSurface
                            }
                        }

                        MouseArea {
                            id: bypassMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: EasyEffects.active
                            onClicked: {
                                EasyEffects.toggleBypass()
                                // Trigger flash effect
                                bypassBtn._toggleFlash = true
                                flashTimer.start()
                            }
                        }

                        Timer {
                            id: flashTimer
                            interval: 200
                            onTriggered: bypassBtn._toggleFlash = false
                        }
                    }
                }
            }

            // ── Live audio meter ──────────────────────────────────────────
            Item { Layout.fillWidth: true; implicitHeight: 6 }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: meterColumn.implicitHeight + 20
                color: Appearance.colors.colLayer1
                radius: Appearance.rounding.normal

                ColumnLayout {
                    id: meterColumn
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 12
                    }
                    spacing: 6

                    SectionHeader { text: "LIVE" }

                    AudioMeter {
                        Layout.fillWidth: true
                        active: root.visible
                    }
                }
            }

            // ── Preset Switcher ───────────────────────────────────────────
            Item { Layout.fillWidth: true; implicitHeight: 6 }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: presetsColumn.implicitHeight + 20
                color: Appearance.colors.colLayer1
                radius: Appearance.rounding.normal

                ColumnLayout {
                    id: presetsColumn
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 12
                    }
                    spacing: 6

                    SectionHeader { text: "PRESETS" }

                    // Empty state — covers two cases: no presets on disk, OR daemon
                    // not yet running so we haven't been able to scan.
                    Text {
                        Layout.fillWidth: true
                        visible: EasyEffects.presets.length === 0
                        text: EasyEffects.socketConnected
                            ? "No presets saved — create one in EasyEffects"
                            : (EasyEffects.active
                                ? "Connecting to EasyEffects…"
                                : "EasyEffects daemon not running")
                        font.pixelSize: Appearance.font.pixelSize.smaller
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
                                        implicitHeight: 32
                                        radius: Appearance.rounding.small

                                        color: _isActive
                                            ? Appearance.colors.colPrimary
                                            : Appearance.colors.colSurfaceContainerHigh

                                        border.width: _isActive ? 2 : 1
                                        border.color: _isActive
                                            ? Appearance.colors.colPrimary
                                            : ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.20)

                                        // Inset shadow for inactive (pressable surface)
                                        layer.enabled: !_isActive
                                        layer.effect: Item {
                                            Rectangle {
                                                anchors.fill: parent
                                                color: "transparent"
                                                border.width: 1
                                                border.color: ColorUtils.applyAlpha("#000000", 0.15)
                                                radius: parent.radius
                                            }
                                        }

                                        Behavior on color {
                                            enabled: Appearance.animationsEnabled
                                            ColorAnimation { duration: 150 }
                                        }
                                        Behavior on border.width {
                                            enabled: Appearance.animationsEnabled
                                            NumberAnimation { duration: 150 }
                                        }

                                        // Glow effect for active preset
                                        Rectangle {
                                            anchors.fill: parent
                                            anchors.margins: -2
                                            radius: parent.radius + 1
                                            color: "transparent"
                                            border.width: 2
                                            border.color: ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.3)
                                            visible: parent._isActive
                                            opacity: parent._isActive ? 1.0 : 0.0

                                            Behavior on opacity {
                                                enabled: Appearance.animationsEnabled
                                                NumberAnimation { duration: 150 }
                                            }
                                        }

                                        Text {
                                            id: chipLabel
                                            anchors.centerIn: parent
                                            text: modelData
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            font.weight: Font.DemiBold
                                            font.family: Appearance.font.family.mono
                                            color: parent._isActive
                                                ? Appearance.m3colors.m3onPrimary
                                                : Appearance.colors.colOnSurface
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
                }
            }

            // ── Active Preset: EQ curve ────────────────────────────────────
            Item { Layout.fillWidth: true; implicitHeight: 6 }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: curveColumn.implicitHeight + 20
                color: Appearance.colors.colLayer1
                radius: Appearance.rounding.normal
                opacity: root._chainAlpha

                ColumnLayout {
                    id: curveColumn
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 12
                    }
                    spacing: 6

                    SectionHeader { text: "CURVE" }

                    EqCurveViz {
                        Layout.fillWidth: true
                    }
                }
            }

            // ── Active Preset: Plugin chain ────────────────────────────────
            Item { Layout.fillWidth: true; implicitHeight: 6 }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: chainColumn.implicitHeight + 20
                color: Appearance.colors.colLayer1
                radius: Appearance.rounding.normal
                opacity: root._chainAlpha

                ColumnLayout {
                    id: chainColumn
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 12
                    }
                    spacing: 6

                    SectionHeader { text: "CHAIN" }

                    PluginChainStrip {
                        Layout.fillWidth: true
                    }
                }
            }

            // Bottom spacer
            Item { implicitHeight: 6 }
        }
    }
}
