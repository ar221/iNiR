import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// MonogramAnchor — two-letter identity badge, replaces LeftSidebarButton.
// Tints colPersonalAccent during NA equities market hours (9:30–16:00 ET, Mon–Fri).
// Market state is written by the market-state systemd timer every minute;
// watched via FileView — no QML Timer polling.
RippleButton {
    id: root

    property string monogramText: Config.options?.bar?.identity?.monogram?.text ?? "AR"
    property string marketState: "closed" // "open" | "closed"

    // Gated by Appearance.apolloActive (Call B Path B refactor).
    // Under Apollo+Courier: warm-amber identity with flattened market register (Open Call A).
    // Fallback restores pre-wedge market-aware register (5619af4f^): personal-accent on open,
    // theme text on closed; invader uses personal-accent open / `#c66b4e` closed; eyes colLayer0.
    readonly property color monogramTextColor: Appearance.apolloActive
        ? (marketState === "open" ? Appearance.apollo.colTextStrong : Appearance.apollo.colText)
        : (marketState === "open"
            ? Appearance.colors.colPersonalAccent
            : (Appearance.angelEverywhere ? Appearance.angel.colText
                : Appearance.inirEverywhere ? Appearance.inir.colText
                : Appearance.colors.colOnLayer1))
    readonly property color invaderColor: Appearance.apolloActive
        ? Appearance.apollo.colAmberDim
        : (marketState === "open" ? Appearance.colors.colPersonalAccent : "#c66b4e")
    readonly property color invaderEyeColor: Appearance.apolloActive
        ? Appearance.apollo.colCanvas
        : Appearance.colors.colLayer0

    property real buttonPadding: 5
    readonly property int _monogramSize: 28
    readonly property int _invaderSize: 21
    readonly property int _glyphGap: 4
    implicitWidth: _monogramSize + _glyphGap + _invaderSize + buttonPadding * 2
    implicitHeight: _monogramSize + buttonPadding * 2

    buttonRadius: 4
    colBackgroundHover: Appearance.angelEverywhere ? Appearance.angel.colGlassCardHover
        : Appearance.inirEverywhere ? Appearance.inir.colLayer1Hover
        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurface
        : Appearance.colors.colLayer1Hover
    colRipple: Appearance.angelEverywhere ? Appearance.angel.colGlassCardActive
        : Appearance.inirEverywhere ? Appearance.inir.colLayer1Active
        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurfaceActive
        : Appearance.colors.colLayer1Active
    colBackgroundToggled: Appearance.angelEverywhere ? Appearance.angel.colGlassCard
        : Appearance.inirEverywhere ? Appearance.inir.colPrimaryContainer
        : Appearance.auroraEverywhere ? Appearance.aurora.colElevatedSurface
        : Appearance.colors.colSecondaryContainer
    colBackgroundToggledHover: Appearance.angelEverywhere ? Appearance.angel.colGlassCardHover
        : Appearance.inirEverywhere ? Appearance.inir.colSelectionHover
        : Appearance.auroraEverywhere ? Appearance.aurora.colElevatedSurfaceHover
        : Appearance.colors.colSecondaryContainerHover
    colRippleToggled: Appearance.angelEverywhere ? Appearance.angel.colGlassCardActive
        : Appearance.inirEverywhere ? Appearance.inir.colPrimaryActive
        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurfaceActive
        : Appearance.colors.colSecondaryContainerActive
    toggled: GlobalStates.sidebarLeftOpen

    onPressed: {
        GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen;
    }

    // Watch market-state file; no QML Timer polling
    FileView {
        id: marketStateFile
        path: Qt.resolvedUrl("file://" + Quickshell.env("HOME") + "/.local/state/inir/market-state")
        watchChanges: true
        onLoaded: {
            const raw = marketStateFile.text()
            if (raw !== null && raw !== undefined) {
                root.marketState = raw.trim() === "open" ? "open" : "closed"
            }
        }
        onLoadFailed: (error) => {
            // File may not exist yet (timer not fired). Keep "closed".
            root.marketState = "closed"
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: root._glyphGap

        Rectangle {
            id: monogramCircle
            width: root._monogramSize
            height: root._monogramSize
            // Gated by Appearance.apolloActive (Call B Path B refactor).
            // Pill chrome keeps solid-square structure across all themes (Option B
            // approximate fallback); pre-wedge gradient-round structure NOT restored.
            // Flagged for Elsa review — see implementation report.
            radius: Appearance.apolloActive ? Appearance.apollo.radiusMicro : 2
            color: Appearance.apolloActive ? Appearance.apollo.colSurface
                : Appearance.angelEverywhere ? Appearance.angel.colGlassCard
                : Appearance.inirEverywhere ? Appearance.inir.colLayer1
                : Appearance.colors.colLayer1
            border.width: Appearance.apolloActive ? Appearance.apollo.borderWidth : 1
            border.color: Appearance.apolloActive ? Appearance.apollo.colBorder
                : Appearance.angelEverywhere ? Appearance.angel.colPanelBorder
                : Appearance.inirEverywhere ? Appearance.inir.colBorder
                : Appearance.colors.colOutlineVariant
            antialiasing: true

            StyledText {
                anchors.centerIn: parent
                text: root.monogramText
                font.pixelSize: 13
                font.weight: Font.Bold
                color: root.monogramTextColor

                Behavior on color {
                    enabled: Appearance.animationsEnabled
                    ColorAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
                }
            }
        }

        Item {
            id: claudeCodeInvader
            width: root._invaderSize
            height: root._monogramSize

            readonly property int px: 3
            readonly property int spriteTop: 2
            readonly property var blocks: [
                // body: 5×5 block, with two dark eyes punched out
                { x: 1, y: 1, w: 5, h: 1, eye: false },
                { x: 1, y: 2, w: 1, h: 1, eye: false },
                { x: 2, y: 2, w: 1, h: 1, eye: true },
                { x: 3, y: 2, w: 1, h: 1, eye: false },
                { x: 4, y: 2, w: 1, h: 1, eye: true },
                { x: 5, y: 2, w: 1, h: 1, eye: false },
                { x: 1, y: 3, w: 5, h: 1, eye: false },
                { x: 1, y: 4, w: 5, h: 1, eye: false },
                { x: 1, y: 5, w: 5, h: 1, eye: false },
                // side arms
                { x: 0, y: 3, w: 1, h: 2, eye: false },
                { x: 6, y: 3, w: 1, h: 2, eye: false },
                // feet
                { x: 2, y: 6, w: 1, h: 1, eye: false },
                { x: 4, y: 6, w: 1, h: 1, eye: false }
            ]

            Repeater {
                model: claudeCodeInvader.blocks

                Rectangle {
                    x: modelData.x * claudeCodeInvader.px
                    y: claudeCodeInvader.spriteTop + modelData.y * claudeCodeInvader.px
                    width: modelData.w * claudeCodeInvader.px
                    height: modelData.h * claudeCodeInvader.px
                    radius: 0
                    color: modelData.eye ? root.invaderEyeColor : root.invaderColor
                    opacity: modelData.eye ? 0.95 : (root.marketState === "open" ? 0.95 : 0.88)
                    antialiasing: false
                }
            }
        }
    }
}
