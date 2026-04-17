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

    property real buttonPadding: 5
    implicitWidth: 28 + buttonPadding * 2
    implicitHeight: 28 + buttonPadding * 2

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
    property color _gradStart: marketState === "open" ? ColorUtils.mix(Appearance.colors.colPersonalAccent, "#ffffff", 0.6) : "#fb923c"
    property color _gradEnd: marketState === "open" ? Appearance.colors.colPersonalAccent : "#f472b6"

    Rectangle {
        id: monogramCircle
        anchors.centerIn: parent
        width: 28
        height: 28
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
}
