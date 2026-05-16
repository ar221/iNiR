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

    readonly property color marketOpenColor: Appearance.colors.colPersonalAccent
    readonly property color marketClosedColor: Appearance.angelEverywhere ? Appearance.angel.colText
        : Appearance.inirEverywhere ? Appearance.inir.colText
        : Appearance.colors.colOnLayer1

    readonly property color monogramColor: marketState === "open" ? marketOpenColor : marketClosedColor
    readonly property color invaderColor: marketState === "open" ? Appearance.colors.colPersonalAccent : "#c66b4e"

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

    // Market-aware gradient tinting
    property color _gradStart: marketState === "open" ? ColorUtils.mix(Appearance.colors.colPersonalAccent, "#ffffff", 0.6) : Qt.rgba(1, 1, 1, 0.55)
    property color _gradEnd: marketState === "open" ? Appearance.colors.colPersonalAccent : Qt.rgba(1, 1, 1, 0.28)

    Behavior on _gradStart {
        enabled: Appearance.animationsEnabled
        ColorAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
    }
    Behavior on _gradEnd {
        enabled: Appearance.animationsEnabled
        ColorAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
    }

    Row {
        anchors.centerIn: parent
        spacing: root._glyphGap

        Rectangle {
            id: monogramCircle
            width: root._monogramSize
            height: root._monogramSize
            radius: width / 2
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: root._gradStart }
                GradientStop { position: 1.0; color: root._gradEnd }
            }

            StyledText {
                anchors.centerIn: parent
                text: root.monogramText
                font.pixelSize: 13
                font.weight: Font.Bold
                color: "#ffffff"
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
                    color: modelData.eye ? Appearance.colors.colLayer0 : root.invaderColor
                    opacity: modelData.eye ? 0.95 : (root.marketState === "open" ? 0.95 : 0.88)
                    antialiasing: false
                }
            }
        }
    }
}
