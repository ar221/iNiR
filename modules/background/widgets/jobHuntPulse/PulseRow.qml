pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

// One pipeline row inside the Job Hunt Pulse widget.
// Variant drives bullet glyph + colors. Hover reveals a popup with full
// status/notes/date. Shift-click opens an Obsidian deep-link.
Item {
    id: root

    // "applied" | "ready" | "shortlist" | "next"
    property string variant: "applied"

    property string company: ""
    property string role: ""
    property string status: ""
    property string notes: ""
    property string dateStr: ""
    property string priorityTag: ""    // e.g. "P6" (shortlist only)
    property string marker: ""         // e.g. "SHIP" (ready only)
    property bool   passive: false     // applied-only: muted treatment

    property string obsidianPath: ""   // vault-relative path; empty disables shift-click
    property string vaultName: "Ayaz OS"

    implicitWidth: rowLayout.implicitWidth
    implicitHeight: rowLayout.implicitHeight + 6   // 3px padding top + bottom

    // — Hover (passive — does NOT swallow drag from parent MouseArea) —
    MouseArea {
        id: _hover
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        propagateComposedEvents: true
    }

    // — Modifier tracker — keeps current keyboard modifiers live for the TapHandler below.
    HoverHandler {
        id: _modProbe
    }

    // — Shift+click → Obsidian. TapHandler coexists with parent drag. —
    TapHandler {
        gesturePolicy: TapHandler.ReleaseWithinBounds
        onTapped: {
            if ((_modProbe.point.modifiers & Qt.ShiftModifier)
                && root.obsidianPath.length > 0) {
                const enc = encodeURIComponent
                const uri = "obsidian://open?vault=" + enc(root.vaultName)
                    + "&file=" + enc(root.obsidianPath)
                Qt.openUrlExternally(uri)
            }
        }
    }

    // — Hover tint —
    Rectangle {
        anchors.fill: parent
        radius: 2
        color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.92)
        visible: _hover.containsMouse
        z: -1
    }

    RowLayout {
        id: rowLayout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 10
        anchors.rightMargin: 6
        spacing: 8

        // — Bullet glyph —
        StyledText {
            text: {
                if (root.variant === "applied")   return "●"
                if (root.variant === "ready")     return "▲"
                if (root.variant === "shortlist") return "○"
                if (root.variant === "next")      return "→"
                return "·"
            }
            font.family: Appearance.font.family.monospace
            font.pixelSize: root.variant === "shortlist"
                ? Appearance.font.pixelSize.smallie
                : Appearance.font.pixelSize.smaller
            color: {
                if (root.variant === "applied")   return Appearance.colors.colSecondary
                if (root.variant === "ready")     return Appearance.colors.colTertiary
                if (root.variant === "shortlist") return Appearance.colors.colSubtext
                if (root.variant === "next")      return Appearance.colors.colPrimary
                return Appearance.colors.colSubtext
            }
            Layout.alignment: Qt.AlignBaseline
        }

        // — Priority tag (shortlist) —
        Rectangle {
            visible: root.variant === "shortlist" && root.priorityTag.length > 0
            color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.96)
            radius: 2
            implicitWidth: prioLabel.implicitWidth + 10
            implicitHeight: prioLabel.implicitHeight + 2
            Layout.alignment: Qt.AlignBaseline

            StyledText {
                id: prioLabel
                anchors.centerIn: parent
                text: root.priorityTag
                font.family: Appearance.font.family.monospace
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.DemiBold
                color: Appearance.colors.colSubtext
            }
        }

        // — Company —
        StyledText {
            text: root.company
            font.family: Appearance.font.family.monospace
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.weight: Font.Bold
            color: root.variant === "shortlist"
                ? Appearance.colors.colSubtext
                : Appearance.colors.colOnLayer0
            Layout.alignment: Qt.AlignBaseline
            opacity: root.passive ? 0.55 : 1.0
        }

        // — Role (elides) —
        StyledText {
            text: root.role
            font.family: Appearance.font.family.monospace
            font.pixelSize: Appearance.font.pixelSize.smallie
            color: Appearance.colors.colSubtext
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignBaseline
            elide: Text.ElideRight
            maximumLineCount: 1
            opacity: root.passive ? 0.55 : 1.0
        }

        // — Passive tag (applied + passive) —
        Rectangle {
            visible: root.variant === "applied" && root.passive
            color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.96)
            radius: 2
            implicitWidth: passLabel.implicitWidth + 10
            implicitHeight: passLabel.implicitHeight + 2
            Layout.alignment: Qt.AlignBaseline

            StyledText {
                id: passLabel
                anchors.centerIn: parent
                text: "PASSIVE"
                font.family: Appearance.font.family.monospace
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.weight: Font.DemiBold
                font.letterSpacing: 1
                color: Appearance.colors.colSubtext
            }
        }

        // — SHIP marker (ready) —
        Rectangle {
            visible: root.variant === "ready" && root.marker.length > 0
            color: Appearance.colors.colTertiary
            radius: 2
            implicitWidth: shipLabel.implicitWidth + 10
            implicitHeight: shipLabel.implicitHeight + 2
            Layout.alignment: Qt.AlignBaseline

            StyledText {
                id: shipLabel
                anchors.centerIn: parent
                text: root.marker
                font.family: Appearance.font.family.monospace
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.weight: Font.Bold
                font.letterSpacing: 1
                color: Appearance.colors.colOnLayer0   // dark text on amber
            }
        }
    }

    // — Hover popup: full detail —
    PopupToolTip {
        text: {
            const parts = []
            if (root.role.length > 0)   parts.push(root.role)
            if (root.status.length > 0) parts.push(root.status)
            if (root.notes.length > 0)  parts.push(root.notes)
            if (root.dateStr.length > 0) parts.push("date: " + root.dateStr)
            return parts.join("\n\n")
        }
        anchorEdges: Edges.Bottom
        extraVisibleCondition: false
        alternativeVisibleCondition: _hover.containsMouse
            && (root.status.length > 0 || root.notes.length > 0 || root.role.length > 0)
    }
}
