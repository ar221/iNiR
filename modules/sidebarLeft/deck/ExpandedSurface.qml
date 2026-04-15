pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

/**
 * ExpandedSurface — ghost wrapper for expand-in-place content.
 *
 * Hosts whichever expandedContent DeckSurface passes in — re-parents it
 * into contentSlot, provides a 40px header with a back button and a
 * duck-typed title.
 *
 * Transparent background by design: AmbientBackground at z:0 is the
 * visual floor for both deck and expanded states. Painting a background
 * here would break the "one surface at two scales" intent.
 */
Item {
    id: root

    // ── Public API ────────────────────────────────────────────────────────
    property Item content: null      // the re-parented expandedContent Item
    property string title: ""        // header label; empty = icon-only header
    signal closeRequested()

    // ── Re-parent content on change ───────────────────────────────────────
    // Track previous so we can unparent it when content switches.
    property Item _previousContent: null

    onContentChanged: {
        if (_previousContent && _previousContent !== content) {
            _previousContent.parent = null
        }
        if (content !== null) {
            content.parent = contentSlot
            content.anchors.fill = contentSlot
        }
        _previousContent = content
    }

    // ── Header row (40px) ─────────────────────────────────────────────────
    Item {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 40
        z: 1

        RippleButton {
            id: backButton
            anchors.left: parent.left
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: 32
            implicitHeight: 32
            buttonRadius: Appearance.rounding.full
            colBackground: "transparent"
            colBackgroundHover: Appearance.colors.colLayer1Hover
            onClicked: root.closeRequested()

            MaterialSymbol {
                anchors.centerIn: parent
                text: "arrow_back"
                iconSize: Appearance.font.pixelSize.larger
                color: backButton.buttonHovered
                    ? Appearance.colors.colOnLayer1
                    : Appearance.colors.colOnLayer1Inactive
                Behavior on color {
                    enabled: Appearance.animationsEnabled
                    ColorAnimation {
                        duration: Appearance.animation.elementMoveFast.duration
                        easing.type: Appearance.animation.elementMoveFast.type
                        easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                    }
                }
            }
        }

        Text {
            id: titleLabel
            anchors.left: backButton.right
            anchors.leftMargin: 8
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            visible: root.title.length > 0
            text: root.title
            font.family: Appearance.font.family.title
            font.pixelSize: Appearance.font.pixelSize.large
            font.weight: Font.Medium
            color: Appearance.colors.colOnLayer1
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignLeft
        }
    }

    // ── Content slot (fills below header) ─────────────────────────────────
    Item {
        id: contentSlot
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 4
        clip: true
    }
}
