import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

GroupButton {
    id: root
    
    required property int buttonIndex
    required property var buttonData
    required property bool expandedSize
    required property string buttonIcon
    required property string name
    required property var mainAction
    property var altAction: null
    // Long-press deep-link to a settings dialog or detail panel. Falls back
    // to altAction when unset so existing toggles keep their long-press behavior.
    property var settingsAction: null
    property string statusText: toggled ? Translation.tr("Active") : Translation.tr("Inactive")

    required property real baseCellWidth
    required property real baseCellHeight
    required property real cellSpacing
    required property int cellSize
    baseWidth: root.baseCellWidth * cellSize + cellSpacing * (cellSize - 1)
    baseHeight: root.baseCellHeight

    property bool editMode: false
    enableImplicitWidthAnimation: !editMode && root.mouseArea.containsMouse
    enableImplicitHeightAnimation: !editMode && root.mouseArea.containsMouse
    Behavior on baseWidth {
        animation: NumberAnimation { duration: Appearance.animation.elementMove.duration; easing.type: Appearance.animation.elementMove.type; easing.bezierCurve: Appearance.animation.elementMove.bezierCurve }
    }
    Behavior on baseHeight {
        animation: NumberAnimation { duration: Appearance.animation.elementMove.duration; easing.type: Appearance.animation.elementMove.type; easing.bezierCurve: Appearance.animation.elementMove.bezierCurve }
    }
    opacity: 0
    Component.onCompleted: {
        opacity = 1
    }
    Behavior on opacity {
        animation: NumberAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
    }



    signal openMenu()

    // TapHandler for right-click - needs to be here because contentItem has MouseAreas
    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: {
            if (root.altAction) root.altAction();
        }
    }

    // Long-press deep-link: fires settingsAction when set. Fires slightly
    // before GroupButton's built-in 0.5s altAction handler, but the two are
    // compatible — dialog opens are idempotent.
    TapHandler {
        acceptedButtons: Qt.LeftButton
        longPressThreshold: 0.4
        onLongPressed: {
            if (root.settingsAction) root.settingsAction();
        }
    }

    padding: 8
    horizontalPadding: padding
    verticalPadding: padding

    colBackground: Appearance.angelEverywhere ? Appearance.angel.colGlassCard
        : Appearance.inirEverywhere ? Appearance.inir.colLayer2 
        : Appearance.auroraEverywhere ? "transparent" : Appearance.colors.colLayer2
    colBackgroundHover: Appearance.angelEverywhere ? Appearance.angel.colGlassCardHover
        : Appearance.inirEverywhere ? Appearance.inir.colLayer2Hover 
        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurface : Appearance.colors.colLayer2Hover
    colBackgroundToggled: Appearance.angelEverywhere ? ColorUtils.transparentize(Appearance.angel.colPrimary, 0.45)
        : Appearance.inirEverywhere 
        ? Appearance.inir.colPrimaryContainer
        : Appearance.colors.colPrimary
    colBackgroundToggledHover: Appearance.angelEverywhere ? ColorUtils.transparentize(Appearance.angel.colPrimaryHover, 0.35)
        : Appearance.inirEverywhere 
        ? Appearance.inir.colPrimaryContainerHover
        : Appearance.colors.colPrimaryHover
    colBackgroundToggledActive: Appearance.angelEverywhere ? ColorUtils.transparentize(Appearance.angel.colPrimaryActive, 0.30)
        : Appearance.inirEverywhere 
        ? Appearance.inir.colPrimaryContainerActive
        : Appearance.colors.colPrimaryActive
    buttonRadius: Appearance.angelEverywhere ? Appearance.angel.roundingSmall
        : Appearance.inirEverywhere 
        ? Appearance.inir.roundingSmall 
        : (toggled ? Appearance.rounding.large : baseHeight / 2)
    buttonRadiusPressed: Appearance.angelEverywhere ? Appearance.angel.roundingSmall
        : Appearance.inirEverywhere ? Appearance.inir.roundingSmall : Appearance.rounding.normal
    property color colText: Appearance.angelEverywhere
        ? (toggled ? Appearance.angel.colOnPrimary : Appearance.angel.colText)
        : Appearance.inirEverywhere
        ? (toggled ? Appearance.inir.colOnPrimaryContainer : Appearance.inir.colText)
        : Appearance.auroraEverywhere
        ? (toggled ? Appearance.m3colors.m3onPrimary : Appearance.m3colors.m3onSurface)
        : toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
    property color colIcon: Appearance.angelEverywhere
        ? (toggled ? Appearance.angel.colOnPrimary : Appearance.angel.colText)
        : Appearance.inirEverywhere
        ? (toggled ? Appearance.inir.colOnPrimaryContainer : Appearance.inir.colText)
        : Appearance.auroraEverywhere
        ? (toggled ? Appearance.m3colors.m3onPrimary : Appearance.m3colors.m3onSurface)
        : toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2

    onClicked: {
        root.mainAction();
    }

    contentItem: ColumnLayout {
        spacing: 2
        MaterialSymbol {
            Layout.alignment: Qt.AlignHCenter
            fill: root.toggled ? 1 : 0
            iconSize: 28
            color: root.colIcon
            text: root.buttonIcon
        }
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            text: root.name
            font.pixelSize: Appearance.font.pixelSize.smallest
            color: root.colText
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
        }
    }

    MouseArea { // Blocking MouseArea for edit interactions
        id: editModeInteraction
        visible: root.editMode
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons

        function toggleEnabled() {
            const index = root.buttonIndex;
            const toggleList = Config.options?.sidebar?.quickToggles?.android?.toggles ?? [];
            const buttonType = root.buttonData.type;
            if (!toggleList.find(toggle => toggle.type === buttonType)) {
                toggleList.push({ type: buttonType, size: 1 });
            } else {
                toggleList.splice(index, 1);
            }
            Config.setNestedValue("sidebar.quickToggles.android.toggles", toggleList);
        }

        function toggleSize() {
            const index = root.buttonIndex;
            const toggleList = Config.options?.sidebar?.quickToggles?.android?.toggles ?? [];
            const buttonType = root.buttonData.type;
            if (!toggleList.find(toggle => toggle.type === buttonType)) return;
            toggleList[index].size = 3 - toggleList[index].size; // Alternate between 1 and 2
            Config.setNestedValue("sidebar.quickToggles.android.toggles", toggleList);
        }

        function movePositionBy(offset) {
            const index = root.buttonIndex;
            const toggleList = Config.options?.sidebar?.quickToggles?.android?.toggles ?? [];
            const buttonType = root.buttonData.type;
            const targetIndex = index + offset;
            if (!toggleList.find(toggle => toggle.type === buttonType)) return;
            if (targetIndex < 0 || targetIndex >= toggleList.length) return;
            const temp = toggleList[index];
            toggleList[index] = toggleList[targetIndex];
            toggleList[targetIndex] = temp;
            Config.setNestedValue("sidebar.quickToggles.android.toggles", toggleList);
        }

        onReleased: (event) => {
            if (event.button === Qt.LeftButton)
                toggleEnabled();
        }
        onPressed: (event) => {
            if (event.button === Qt.RightButton) toggleSize();
        }
        onPressAndHold: (event) => { // Also toggle size
            toggleSize();
        }
        onWheel: (event) => {
            const index = root.buttonIndex;
            const toggleList = Config.options?.sidebar?.quickToggles?.android?.toggles ?? [];
            const buttonType = root.buttonData.type;
            if (event.angleDelta.y < 0) { // Move to right
                movePositionBy(1);
            } else if (event.angleDelta.y > 0) { // Move to left
                movePositionBy(-1);
            }
            event.accepted = true;
        }
    }
}
