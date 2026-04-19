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

                    // Connection status dot.
                    // - colPrimary  → socket connected, ready
                    // - colTertiary → daemon detected but socket not yet up
                    // - dim         → daemon not running
                    // Using theme tokens so the dot still reads "different state"
                    // across every wallpaper palette.
                    Rectangle {
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

                    // Bypass toggle button
                    Rectangle {
                        id: bypassBtn
                        implicitWidth: bypassRow.implicitWidth + 16
                        implicitHeight: 28
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
                                font.pixelSize: Appearance.font.pixelSize.smaller
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

            // ── Live audio meter ──────────────────────────────────────────
            // Tiny gap above the meter so it doesn't kiss the status card.
            Item { Layout.fillWidth: true; implicitHeight: 8 }

            SectionHeader { text: "LIVE" }

            AudioMeter {
                Layout.fillWidth: true
                active: root.visible
            }

            // ── Preset Switcher ───────────────────────────────────────────
            Item { Layout.fillWidth: true; implicitHeight: 8 }

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
                                    font.pixelSize: Appearance.font.pixelSize.smaller
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

            // ── Active Preset: EQ curve ────────────────────────────────────
            Item { Layout.fillWidth: true; implicitHeight: 8; opacity: root._chainAlpha }

            SectionHeader { text: "CURVE"; opacity: root._chainAlpha }

            EqCurveViz {
                Layout.fillWidth: true
                opacity: root._chainAlpha
            }

            // ── Active Preset: Plugin chain ────────────────────────────────
            Item { Layout.fillWidth: true; implicitHeight: 8; opacity: root._chainAlpha }

            SectionHeader { text: "CHAIN"; opacity: root._chainAlpha }

            PluginChainStrip {
                Layout.fillWidth: true
                opacity: root._chainAlpha
            }

            // Bottom spacer
            Item { implicitHeight: 8 }
        }
    }
}
