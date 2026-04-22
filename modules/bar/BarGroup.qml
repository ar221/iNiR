import qs.modules.common
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property bool vertical: false
    readonly property string densityPreset: {
        const preset = String(Config.options?.bar?.density ?? "default").toLowerCase()
        return (preset === "compact" || preset === "airy") ? preset : "default"
    }
    readonly property string stylePreset: {
        const preset = String(Config.options?.bar?.stylePreset ?? "dusky").toLowerCase()
        return (preset === "clean" || preset === "glass") ? preset : "dusky"
    }
    property real padding: densityPreset === "compact" ? 4 : (densityPreset === "airy" ? 6 : 5)
    readonly property int blockMargin: densityPreset === "compact" ? 3 : (densityPreset === "airy" ? 5 : 4)
    readonly property bool cardStyleEverywhere: (Config.options?.dock?.cardStyle ?? false) && (Config.options?.sidebar?.cardStyle ?? false) && (Config.options?.bar?.cornerStyle === 3)
    readonly property color baseLayerColor: Appearance.angelEverywhere ? Appearance.angel.colGlassCard
        : Appearance.inirEverywhere ? Appearance.inir.colLayer1
        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurface
        : Appearance.colors.colLayer1
    readonly property real backgroundOpacity: stylePreset === "glass" ? 0.62 : (stylePreset === "clean" ? 0.92 : 1.0)
    readonly property int styleBorderWidth: stylePreset === "glass"
        ? 1
        : (stylePreset === "clean" ? 1
            : (Appearance.angelEverywhere ? Appearance.angel.cardBorderWidth : (Appearance.inirEverywhere ? 1 : (cardStyleEverywhere ? 1 : 0))))
    readonly property color styleBorderColor: stylePreset === "glass"
        ? (Appearance.inirEverywhere ? Appearance.inir.colBorder : Appearance.colors.colOutline)
        : (stylePreset === "clean"
            ? (Appearance.inirEverywhere ? Appearance.inir.colBorderSubtle : Appearance.colors.colLayer0Border)
            : (Appearance.angelEverywhere ? Appearance.angel.colCardBorder
                : (Appearance.inirEverywhere ? Appearance.inir.colBorder : Appearance.colors.colLayer0Border)))
    readonly property real baseRadius: Appearance.angelEverywhere ? Appearance.angel.roundingSmall
        : Appearance.inirEverywhere ? Appearance.inir.roundingNormal
        : (cardStyleEverywhere ? Appearance.rounding.normal : Appearance.rounding.small)
    readonly property real styleRadius: stylePreset === "clean"
        ? Math.max(2, baseRadius - 2)
        : (stylePreset === "glass" ? (baseRadius + 2) : baseRadius)
    implicitWidth: vertical ? Appearance.sizes.baseVerticalBarWidth : (gridLayout.implicitWidth + padding * 2)
    implicitHeight: vertical ? (gridLayout.implicitHeight + padding * 2) : Appearance.sizes.baseBarHeight
    default property alias items: gridLayout.children

    Rectangle {
        id: background
        anchors {
            fill: parent
            topMargin: root.vertical ? 0 : root.blockMargin
            bottomMargin: root.vertical ? 0 : root.blockMargin
            leftMargin: root.vertical ? root.blockMargin : 0
            rightMargin: root.vertical ? root.blockMargin : 0
        }
        color: (Config.options?.bar?.borderless ?? false) ? "transparent"
            : ColorUtils.applyAlpha(root.baseLayerColor, root.backgroundOpacity)
        border.width: (Config.options?.bar?.borderless ?? false) ? 0 : root.styleBorderWidth
        border.color: root.styleBorderColor
        radius: root.styleRadius
    }

    GridLayout {
        id: gridLayout
        columns: root.vertical ? 1 : -1
        anchors {
            verticalCenter: root.vertical ? undefined : parent.verticalCenter
            horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
            left: root.vertical ? undefined : parent.left
            right: root.vertical ? undefined : parent.right
            top: root.vertical ? parent.top : undefined
            bottom: root.vertical ? parent.bottom : undefined
            margins: root.padding
        }
        columnSpacing: densityPreset === "compact" ? 3 : (densityPreset === "airy" ? 6 : 4)
        rowSpacing: 12
    }
}