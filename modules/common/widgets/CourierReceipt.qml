pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

Rectangle {
    id: root

    property string state: "EMPTY"
    property string source: ""
    property string lastSignal: ""
    property string route: ""
    property string repair: ""
    property string density: "default"
    property bool omitStateLabel: false

    readonly property string normalizedState: {
        switch (state) {
        case "EMPTY":
        case "STALE":
        case "FAIL":
        case "LOADING":
        case "FILTERED":
        case "INVALID":
            return state
        default:
            return "INVALID"
        }
    }
    readonly property string normalizedDensity: density === "compact" || density === "default" || density === "airy" ? density : "default"
    readonly property bool isCompact: normalizedDensity === "compact"
    readonly property bool isAiry: normalizedDensity === "airy"
    readonly property string effectiveState: source === "" ? "INVALID" : normalizedState

    readonly property color stateColor: {
        switch (effectiveState) {
        case "STALE":
            return Appearance.mission.colAccent
        case "FAIL":
        case "INVALID":
            return Appearance.mission.colBorderHot
        case "LOADING":
        case "FILTERED":
            return Appearance.mission.colTextSecondary
        case "EMPTY":
        default:
            return Appearance.mission.colTextMuted
        }
    }
    readonly property color leftRuleColor: {
        switch (effectiveState) {
        case "STALE":
            return Appearance.mission.colAccent
        case "FAIL":
        case "INVALID":
            return Appearance.mission.colBorderHot
        default:
            return Appearance.mission.colBorder
        }
    }

    readonly property bool requiresLastSignal: effectiveState === "STALE" || effectiveState === "FAIL"
    readonly property bool requiresRoute: effectiveState === "EMPTY" || effectiveState === "STALE"
    readonly property bool requiresRepair: effectiveState === "FAIL" || effectiveState === "FILTERED"

    readonly property string compactValue: {
        if (repair !== "")
            return repair
        if (lastSignal !== "")
            return lastSignal
        if (route !== "")
            return route
        return ""
    }

    implicitWidth: compactRow.implicitWidth
    implicitHeight: contentColumn.implicitHeight + (isCompact ? 0 : 2 * contentColumn.anchors.margins)
    color: isCompact ? "transparent" : Appearance.mission.colSurface
    border.width: isCompact ? 0 : 1
    border.color: isCompact ? "transparent" : ColorUtils.transparentize(Appearance.mission.colBorder, 0.4)
    radius: isCompact ? 0 : Appearance.courier.radiusMicro

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        visible: !isCompact
        width: 2
        color: root.leftRuleColor
    }

    RowLayout {
        id: compactRow
        anchors.fill: parent
        visible: root.isCompact
        spacing: 4

        Rectangle {
            visible: !root.omitStateLabel
            implicitHeight: compactStateText.implicitHeight + 2
            implicitWidth: compactStateText.implicitWidth + 6
            radius: 0
            color: ColorUtils.transparentize(root.stateColor, 0.85)
            border.width: 1
            border.color: root.stateColor

            Text {
                id: compactStateText
                anchors.centerIn: parent
                text: root.effectiveState
                font.family: Appearance.font.family.monospace
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.letterSpacing: 1.4
                font.weight: Font.DemiBold
                color: root.stateColor
                renderType: Text.NativeRendering
            }
        }

        Text {
            Layout.fillWidth: true
            text: root.compactValue === "" ? root.source : (root.source + " · " + root.compactValue)
            elide: Text.ElideRight
            maximumLineCount: 1
            font.family: Appearance.font.family.monospace
            font.pixelSize: Appearance.font.pixelSize.smallest
            font.letterSpacing: 0.0
            font.weight: Font.Normal
            color: Appearance.mission.colText
            renderType: Text.NativeRendering
        }
    }

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        anchors.margins: root.isCompact ? 0 : (root.isAiry ? 14 : 8)
        visible: !root.isCompact
        spacing: root.isAiry ? 10 : 4

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Rectangle {
                visible: !root.omitStateLabel
                implicitHeight: stateText.implicitHeight + 4
                implicitWidth: stateText.implicitWidth + 8
                radius: 0
                color: ColorUtils.transparentize(root.stateColor, 0.85)
                border.width: 1
                border.color: root.stateColor

                Text {
                    id: stateText
                    anchors.centerIn: parent
                    text: root.effectiveState
                    font.family: Appearance.font.family.monospace
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    font.letterSpacing: 1.4
                    font.weight: Font.DemiBold
                    color: root.stateColor
                    renderType: Text.NativeRendering
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.source === "" ? "\u27e8missing source\u27e9" : root.source
                elide: Text.ElideRight
                maximumLineCount: 1
                font.family: Appearance.font.family.monospace
                font.pixelSize: root.isAiry ? Appearance.font.pixelSize.smallie : Appearance.font.pixelSize.smaller
                font.letterSpacing: 0.0
                font.weight: Font.Normal
                color: Appearance.mission.colText
                renderType: Text.NativeRendering
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.requiresLastSignal || root.lastSignal !== ""
            spacing: 6

            Text {
                text: "LAST SIGNAL"
                font.family: Appearance.font.family.monospace
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.letterSpacing: 1.2
                font.weight: Font.DemiBold
                color: Appearance.mission.colTextMuted
                renderType: Text.NativeRendering
            }

            Text {
                Layout.fillWidth: true
                text: root.lastSignal !== "" ? root.lastSignal : (root.requiresLastSignal ? "\u27e8pending wiring\u27e9" : "")
                elide: Text.ElideRight
                maximumLineCount: 1
                font.family: Appearance.font.family.monospace
                font.pixelSize: root.isAiry ? Appearance.font.pixelSize.smallie : Appearance.font.pixelSize.smaller
                font.letterSpacing: 0.0
                font.weight: Font.Normal
                color: Appearance.mission.colText
                renderType: Text.NativeRendering
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.effectiveState !== "INVALID" && (root.requiresRoute || root.route !== "")
            spacing: 6

            Text {
                text: "ROUTE"
                font.family: Appearance.font.family.monospace
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.letterSpacing: 1.2
                font.weight: Font.DemiBold
                color: Appearance.mission.colTextMuted
                renderType: Text.NativeRendering
            }

            Text {
                Layout.fillWidth: true
                text: root.route !== "" ? root.route : (root.requiresRoute ? "\u27e8pending wiring\u27e9" : "")
                elide: Text.ElideRight
                maximumLineCount: 1
                font.family: Appearance.font.family.monospace
                font.pixelSize: root.isAiry ? Appearance.font.pixelSize.smallie : Appearance.font.pixelSize.smaller
                font.letterSpacing: 0.0
                font.weight: Font.Normal
                color: Appearance.mission.colText
                renderType: Text.NativeRendering
            }
        }

        RowLayout {
            id: repairRow
            Layout.fillWidth: true
            visible: root.effectiveState !== "INVALID" && (root.requiresRepair || root.repair !== "")
            spacing: 6

            Text {
                text: "\u21b3"
                font.family: Appearance.font.family.monospace
                font.pixelSize: root.isAiry ? Appearance.font.pixelSize.smallie : Appearance.font.pixelSize.smaller
                font.letterSpacing: 0.0
                font.weight: Font.Normal
                color: Appearance.mission.colTextSecondary
                renderType: Text.NativeRendering
            }

            Text {
                id: repairText
                Layout.fillWidth: true
                text: root.repair !== "" ? root.repair : (root.requiresRepair ? "\u27e8pending wiring\u27e9" : "")
                elide: Text.ElideRight
                maximumLineCount: 1
                font.family: Appearance.font.family.monospace
                font.pixelSize: root.isAiry ? Appearance.font.pixelSize.smallie : Appearance.font.pixelSize.smaller
                font.letterSpacing: 0.0
                font.weight: Font.Normal
                color: Appearance.mission.colText
                renderType: Text.NativeRendering
            }

            HoverHandler {
                id: repairHover
                enabled: repairRow.visible && repairText.truncated
            }

            PopupToolTip {
                parent: repairText
                targetItem: repairText
                visible: repairHover.hovered && repairText.truncated
                text: repairText.text
                position: "top"
            }
        }
    }
}
