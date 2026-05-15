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
            Layout.fillWidth: root.variant === "next"
            opacity: root.passive ? 0.55 : 1.0
            wrapMode: root.variant === "next" ? Text.WordWrap : Text.NoWrap
            maximumLineCount: root.variant === "next" ? 3 : 1
            elide: root.variant === "next" ? Text.ElideRight : Text.ElideNone
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
        id: _popup
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
        horizontalPadding: 14
        verticalPadding: 10

        contentItem: Item {
            id: _popupBody
            property bool shown: false
            readonly property real maxTextWidth: 360
            readonly property real textWidth: Math.min(_popupText.contentWidth, maxTextWidth)
            implicitWidth: textWidth + _popup.horizontalPadding * 2
            implicitHeight: _popupText.implicitHeight + _popup.verticalPadding * 2

            Rectangle {
                anchors.fill: parent
                radius: Appearance.rounding.verysmall
                color: Appearance.inirEverywhere
                    ? Appearance.inir.colLayer2
                    : Appearance.auroraEverywhere
                        ? Appearance.aurora.colTooltipSurface
                        : Appearance.colors.colLayer3
                border.width: 1
                border.color: Appearance.inirEverywhere
                    ? Appearance.inir.colBorder
                    : Appearance.auroraEverywhere
                        ? Appearance.aurora.colTooltipBorder
                        : Appearance.colors.colLayer3Hover
                opacity: _popupBody.shown ? 1 : 0
                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }

            StyledText {
                id: _popupText
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.leftMargin: _popup.horizontalPadding
                anchors.topMargin: _popup.verticalPadding
                width: _popupBody.maxTextWidth
                text: _popup.text
                font.family: Appearance.font.family.monospace
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.inirEverywhere
                    ? Appearance.inir.colText
                    : Appearance.colors.colOnLayer3
                wrapMode: Text.WordWrap
            }
        }
    }
}
