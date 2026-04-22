import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.modules.sidebarRight.quickToggles
import qs.modules.sidebarRight.quickToggles.classicStyle
import qs.modules.sidebarRight.quickToggles.androidStyle
import qs.modules.sidebarRight.bluetoothDevices
import qs.modules.sidebarRight.events
import qs.modules.sidebarRight.hotspot
import qs.modules.sidebarRight.nightLight
import qs.modules.sidebarRight.volumeMixer
import qs.modules.sidebarRight.wifiNetworks

Item {
    id: root

    property int sidebarWidth: Appearance.sizes.sidebarWidth
    property int sidebarPadding: 10
    property int screenWidth: 1920
    property int screenHeight: 1080
    property var panelScreen: null
    readonly property int contentInset: 12
    readonly property int sectionGap: 8
    readonly property real sectionLetterSpacing: 1.25
    readonly property string monoFamily: (Appearance.font && Appearance.font.family && Appearance.font.family.mono)
        ? Appearance.font.family.mono
        : "monospace"

    property bool showAudioOutputDialog: false
    property bool showAudioInputDialog: false
    property bool showBluetoothDialog: false
    property bool showEventsDialog: false
    property bool showHotspotDialog: false
    property bool showNightLightDialog: false
    property bool showWifiDialog: false
    property var eventsDialogEditEvent: null

    function focusActiveItem() {
        // Bridge sections are loader-backed; focus handling can be layered in later.
    }

    property int activeSection: 0
    readonly property int notificationCount: Notifications.list?.length ?? 0
    readonly property var sections: [
        { id: "controls", icon: "tune", label: Translation.tr("Bridge") },
        { id: "alerts", icon: "notifications", label: Translation.tr("Alerts") },
        { id: "session", icon: "view_sidebar", label: Translation.tr("Session") }
    ]

    Component.onCompleted: Notifications.ensureInitialized()

    Connections {
        target: GlobalStates
        function onSidebarRightOpenChanged() {
            if (!GlobalStates.sidebarRightOpen) {
                root.showWifiDialog = false
                root.showBluetoothDialog = false
                root.showEventsDialog = false
                root.showAudioOutputDialog = false
                root.showAudioInputDialog = false
                root.showNightLightDialog = false
                root.showHotspotDialog = false
                root.eventsDialogEditEvent = null
            }
        }
    }

    SidebarBackground {
        id: bg
        anchors.fill: parent
        side: "right"
        panelScreen: root.panelScreen
        screenWidth: root.screenWidth
        screenHeight: root.screenHeight
        sidebarWidth: root.sidebarWidth
        sidebarPadding: root.sidebarPadding

        readonly property color cardColor: angelEverywhere
            ? ColorUtils.transparentize(Appearance.angel.colGlassCard, 0.76)
            : inirEverywhere ? ColorUtils.transparentize(Appearance.inir.colLayer1, 0.18)
            : auroraEverywhere ? ColorUtils.transparentize((blendedColors?.colLayer0 ?? Appearance.colors.colLayer0Base), 0.60)
            : ColorUtils.transparentize(Appearance.colors.colLayer3, 0.16)
        readonly property color borderColor: angelEverywhere
            ? ColorUtils.transparentize(Appearance.angel.colCardBorder, 0.44)
            : inirEverywhere ? ColorUtils.transparentize(Appearance.inir.colBorder, 0.28)
            : ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.64)

        RowLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                id: leftRail
                Layout.fillHeight: true
                Layout.preferredWidth: 54
                color: "transparent"

                Rectangle {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.topMargin: bg.radius
                    anchors.bottomMargin: bg.radius
                    width: 1
                    color: bg.borderColor
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.topMargin: 12
                    anchors.bottomMargin: 12
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    spacing: 6

                    Repeater {
                        model: root.sections
                        delegate: Rectangle {
                            id: navButton
                            required property int index
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 42
                            radius: bg.angelEverywhere ? Appearance.angel.roundingSmall
                                : bg.inirEverywhere ? Appearance.inir.roundingSmall
                                : Appearance.rounding.small
                            color: root.activeSection === index
                                ? (bg.inirEverywhere ? Appearance.inir.colSecondaryContainer
                                    : bg.angelEverywhere ? ColorUtils.transparentize(Appearance.angel.colPrimary, navMouse.pressed ? 0.50 : 0.58)
                                    : ColorUtils.transparentize(Appearance.colors.colSecondaryContainer, navMouse.pressed ? 0.08 : 0.14))
                                : navMouse.pressed
                                    ? ColorUtils.transparentize(bg.cardColor, 0.20)
                                    : (navMouse.containsMouse ? bg.cardColor : "transparent")
                            border.width: (root.activeSection === index || navMouse.containsMouse) ? 1 : 0
                            border.color: root.activeSection === index
                                ? (bg.inirEverywhere ? Appearance.inir.colPrimary
                                    : bg.angelEverywhere ? Appearance.angel.colPrimary
                                    : Appearance.colors.colPrimary)
                                : bg.borderColor

                            Behavior on color {
                                enabled: Appearance.animationsEnabled
                                ColorAnimation { duration: 120 }
                            }
                            Behavior on border.width {
                                enabled: Appearance.animationsEnabled
                                NumberAnimation { duration: 120 }
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: 2.5
                                height: 18
                                radius: 1.25
                                color: bg.inirEverywhere ? Appearance.inir.colPrimary
                                    : bg.angelEverywhere ? Appearance.angel.colPrimary
                                    : Appearance.colors.colPrimary
                                visible: root.activeSection === index
                                opacity: visible ? 1.0 : 0.0

                                Behavior on opacity {
                                    enabled: Appearance.animationsEnabled
                                    NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                                }
                            }

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: modelData.icon
                                iconSize: 22
                                fill: root.activeSection === index ? 1 : 0
                                color: root.activeSection === index
                                    ? (bg.inirEverywhere ? Appearance.inir.colOnSecondaryContainer
                                        : bg.angelEverywhere ? Appearance.angel.colOnPrimary
                                        : Appearance.m3colors.m3onSecondaryContainer)
                                    : navMouse.containsMouse
                                        ? (bg.inirEverywhere ? Appearance.inir.colText
                                            : bg.angelEverywhere ? Appearance.angel.colText
                                            : Appearance.colors.colOnLayer1)
                                        : (bg.inirEverywhere ? Appearance.inir.colTextSecondary
                                            : bg.angelEverywhere ? Appearance.angel.colTextSecondary
                                            : Appearance.colors.colOnLayer1)
                                Behavior on color {
                                    enabled: Appearance.animationsEnabled
                                    ColorAnimation { duration: 120 }
                                }
                            }

                            MouseArea {
                                id: navMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.activeSection = index
                            }


                        }
                    }

                    Item { Layout.fillHeight: true }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 38
                        radius: bg.angelEverywhere ? Appearance.angel.roundingSmall
                            : bg.inirEverywhere ? Appearance.inir.roundingSmall
                            : Appearance.rounding.small
                        color: layoutMouse.pressed
                            ? ColorUtils.transparentize(bg.cardColor, 0.20)
                            : layoutMouse.containsMouse ? bg.cardColor : "transparent"
                        border.width: (layoutMouse.containsMouse || layoutMouse.pressed) ? 1 : 0
                        border.color: layoutMouse.containsMouse
                            ? (bg.inirEverywhere ? Appearance.inir.colPrimary
                                : bg.angelEverywhere ? Appearance.angel.colPrimary
                                : Appearance.colors.colPrimary)
                            : bg.borderColor
                        Behavior on color {
                            enabled: Appearance.animationsEnabled
                            ColorAnimation { duration: 120 }
                        }
                        Behavior on border.width {
                            enabled: Appearance.animationsEnabled
                            NumberAnimation { duration: 120 }
                        }

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "view_agenda"
                            iconSize: 18
                            color: layoutMouse.containsMouse
                                ? (bg.inirEverywhere ? Appearance.inir.colPrimary
                                    : bg.angelEverywhere ? Appearance.angel.colPrimary
                                    : Appearance.colors.colPrimary)
                                : (bg.inirEverywhere ? Appearance.inir.colTextSecondary
                                    : bg.angelEverywhere ? Appearance.angel.colTextSecondary
                                    : Appearance.colors.colOnLayer1)
                            Behavior on color {
                                enabled: Appearance.animationsEnabled
                                ColorAnimation { duration: 120 }
                            }
                        }

                        MouseArea {
                            id: layoutMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Config.setNestedValue("sidebar.layout", "compact")
                        }


                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Loader {
                    anchors.fill: parent
                    active: root.activeSection === 0
                    visible: active
                    sourceComponent: controlsSection
                }

                Loader {
                    anchors.fill: parent
                    active: root.activeSection === 1
                    visible: active
                    sourceComponent: alertsSection
                }

                Loader {
                    anchors.fill: parent
                    active: root.activeSection === 2
                    visible: active
                    sourceComponent: sessionSection
                }
            }
        }
    }

    component SectionCard: Rectangle {
        id: card
        default property alias content: inner.data
        Layout.fillWidth: true
        radius: bg.angelEverywhere ? Appearance.angel.roundingNormal
            : bg.inirEverywhere ? Appearance.inir.roundingNormal
            : Appearance.rounding.normal
        color: bg.cardColor
        border.width: 1
        border.color: bg.borderColor
        implicitHeight: inner.implicitHeight + 22

        ColumnLayout {
            id: inner
            anchors.fill: parent
            anchors.margins: root.contentInset
            spacing: root.sectionGap
        }
    }

    component SectionTitle: RowLayout {
        required property string text
        required property string icon
        Layout.fillWidth: true
        spacing: 8

        Rectangle {
            width: 2
            height: 12
            radius: 1
            color: bg.inirEverywhere ? Appearance.inir.colPrimary
                : bg.angelEverywhere ? Appearance.angel.colPrimary
                : Appearance.colors.colPrimary
        }
        MaterialSymbol {
            text: parent.icon
            iconSize: 16
            color: bg.inirEverywhere ? Appearance.inir.colTextSecondary
                : bg.angelEverywhere ? Appearance.angel.colTextSecondary
                : Appearance.colors.colSubtext
        }
        StyledText {
            text: String(parent.text).toUpperCase()
            font.pixelSize: Appearance.font.pixelSize.small
            font.weight: Font.DemiBold
            font.family: root.monoFamily
            font.letterSpacing: root.sectionLetterSpacing
            color: bg.inirEverywhere ? Appearance.inir.colTextSecondary
                : bg.angelEverywhere ? Appearance.angel.colTextSecondary
                : Appearance.colors.colSubtext
        }
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.84)
        }
    }

    component ActionRow: RippleButton {
        id: btn
        required property string label
        required property string iconName
        Layout.fillWidth: true
        implicitHeight: 40
        colBackground: "transparent"
        colBackgroundHover: bg.cardColor
        contentItem: RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8
            MaterialSymbol {
                text: btn.iconName
                iconSize: 16
                color: bg.inirEverywhere ? Appearance.inir.colPrimary
                    : bg.angelEverywhere ? Appearance.angel.colPrimary
                    : Appearance.colors.colPrimary
            }
            StyledText {
                Layout.fillWidth: true
                text: btn.label
                font.pixelSize: Appearance.font.pixelSize.small
                color: bg.inirEverywhere ? Appearance.inir.colText
                    : bg.angelEverywhere ? Appearance.angel.colText
                    : Appearance.colors.colOnLayer1
            }
            MaterialSymbol {
                text: "chevron_right"
                iconSize: 16
                color: ColorUtils.transparentize(Appearance.colors.colOnSurfaceVariant, 0.25)
            }
        }
    }

    Component {
        id: controlsSection
        Flickable {
            anchors.fill: parent
            anchors.margins: root.contentInset
            contentWidth: width
            contentHeight: controlsColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: StyledScrollBar {
                policy: controlsSection.contentHeight > controlsSection.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
            }

            ColumnLayout {
                id: controlsColumn
                width: parent.width - 2
                spacing: root.sectionGap

                SectionTitle { text: Translation.tr("Bridge Controls"); icon: "tune" }

                Loader {
                    Layout.fillWidth: true
                    active: {
                        const q = Config.options?.sidebar?.quickSliders
                        if (!q?.enable) return false
                        return q?.showMic || q?.showVolume || q?.showBrightness
                    }
                    visible: active
                    sourceComponent: SectionCard { QuickSliders { width: parent.width } }
                }

                Loader {
                    Layout.fillWidth: true
                    active: Config.options?.sidebar?.focusModeChips?.enable ?? true
                    visible: active
                    sourceComponent: SectionCard {
                        ButtonGroup {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 32
                            spacing: 4
                            color: "transparent"

                            Repeater {
                                model: FocusMode._modeOrder

                                GroupButton {
                                    required property string modelData
                                    required property int index

                                    readonly property var modeProfile: FocusMode._profiles[modelData] ?? ({})
                                    readonly property bool isActive: FocusMode.activeMode === modelData

                                    toggled: isActive
                                    buttonText: modeProfile.label ?? modelData
                                    buttonRadius: bg.angelEverywhere ? Appearance.angel.roundingSmall
                                        : bg.inirEverywhere ? Appearance.inir.roundingSmall
                                        : Appearance.rounding.small

                                    implicitHeight: 32
                                    horizontalPadding: 12
                                    verticalPadding: 0
                                    bounce: false

                                    colBackgroundToggled: {
                                        switch (modelData) {
                                            case "focus": return Appearance.m3colors.m3primary
                                            case "gaming": return Appearance.m3colors.m3tertiary
                                            case "zen": return Appearance.m3colors.m3secondary
                                            default: return bg.angelEverywhere ? Appearance.angel.colGlassCard
                                                : bg.inirEverywhere ? Appearance.inir.colLayer2
                                                : bg.auroraEverywhere ? Appearance.aurora.colSubSurface
                                                : Appearance.colors.colLayer2
                                        }
                                    }
                                    colBackgroundToggledHover: ColorUtils.transparentize(colBackgroundToggled, 0.15)
                                    colBackground: "transparent"
                                    colBackgroundHover: bg.angelEverywhere ? Appearance.angel.colGlassCardHover
                                        : bg.inirEverywhere ? Appearance.inir.colLayer2Hover
                                        : bg.auroraEverywhere ? Appearance.aurora.colSubSurfaceHover
                                        : Appearance.colors.colLayer2Hover

                                    Layout.fillWidth: true

                                    onClicked: FocusMode.setMode(modelData)
                                }
                            }
                        }
                    }
                }

                SectionCard {
                    StyledText {
                        text: Translation.tr("Quick Toggles")
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Medium
                        color: bg.inirEverywhere ? Appearance.inir.colTextSecondary
                            : bg.angelEverywhere ? Appearance.angel.colTextSecondary
                            : Appearance.colors.colSubtext
                    }

                    Loader {
                        id: classicLoader
                        Layout.fillWidth: true
                        active: (Config.options?.sidebar?.quickToggles?.style ?? "classic") === "classic"
                        visible: active
                        sourceComponent: ClassicQuickPanel {}
                        Connections {
                            target: classicLoader.item
                            function onOpenAudioOutputDialog() { root.showAudioOutputDialog = true }
                            function onOpenAudioInputDialog() { root.showAudioInputDialog = true }
                            function onOpenBluetoothDialog() { root.showBluetoothDialog = true }
                            function onOpenNightLightDialog() { root.showNightLightDialog = true }
                            function onOpenHotspotDialog() { root.showHotspotDialog = true }
                            function onOpenWifiDialog() { root.showWifiDialog = true }
                        }
                    }

                    Loader {
                        id: androidLoader
                        Layout.fillWidth: true
                        active: (Config.options?.sidebar?.quickToggles?.style ?? "classic") === "android"
                        visible: active
                        sourceComponent: AndroidQuickPanel {}
                        Connections {
                            target: androidLoader.item
                            function onOpenAudioOutputDialog() { root.showAudioOutputDialog = true }
                            function onOpenAudioInputDialog() { root.showAudioInputDialog = true }
                            function onOpenBluetoothDialog() { root.showBluetoothDialog = true }
                            function onOpenNightLightDialog() { root.showNightLightDialog = true }
                            function onOpenHotspotDialog() { root.showHotspotDialog = true }
                            function onOpenWifiDialog() { root.showWifiDialog = true }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: alertsSection
        Item {
            anchors.fill: parent
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: root.contentInset
                spacing: root.sectionGap

                SectionTitle {
                    text: root.notificationCount > 0
                        ? Translation.tr("Alerts · %1").arg(root.notificationCount)
                        : Translation.tr("Alerts")
                    icon: "notifications"
                }

                CenterWidgetGroup {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }
    }

    Component {
        id: sessionSection
        Flickable {
            anchors.fill: parent
            anchors.margins: root.contentInset
            contentWidth: width
            contentHeight: sessionColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: StyledScrollBar {
                policy: sessionSection.contentHeight > sessionSection.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
            }

            ColumnLayout {
                id: sessionColumn
                width: parent.width - 2
                spacing: root.sectionGap

                SectionTitle { text: Translation.tr("Session"); icon: "view_sidebar" }

                SectionCard {
                    CompactMediaPlayer { width: parent.width }
                }

                SectionCard {
                    StyledText {
                        text: Translation.tr("Actions")
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Medium
                        color: bg.inirEverywhere ? Appearance.inir.colTextSecondary
                            : bg.angelEverywhere ? Appearance.angel.colTextSecondary
                            : Appearance.colors.colSubtext
                    }
                    ActionRow {
                        label: Translation.tr("Switch to compact layout")
                        iconName: "view_agenda"
                        onClicked: Config.setNestedValue("sidebar.layout", "compact")
                    }
                    ActionRow {
                        label: Translation.tr("Close bridge")
                        iconName: "keyboard_double_arrow_right"
                        onClicked: GlobalStates.sidebarRightOpen = false
                    }
                }

                SectionCard {
                    SectionTitle { text: Translation.tr("Utility Bay"); icon: "widgets" }
                    BottomWidgetGroup { Layout.fillWidth: true }
                }
            }
        }
    }

    component ToggleDialog: Loader {
        id: toggleDialogLoader
        required property string shownPropertyString
        property alias dialog: toggleDialogLoader.sourceComponent
        readonly property bool shown: root[shownPropertyString]
        anchors.fill: parent
        active: shown

        onItemChanged: {
            if (item) {
                item.show = true
                item.forceActiveFocus()
            }
        }

        Connections {
            target: toggleDialogLoader.item
            function onDismiss() {
                root[toggleDialogLoader.shownPropertyString] = false
            }
        }
    }

    ToggleDialog { shownPropertyString: "showAudioOutputDialog"; dialog: VolumeDialog { isSink: true } }
    ToggleDialog { shownPropertyString: "showAudioInputDialog"; dialog: VolumeDialog { isSink: false } }
    ToggleDialog {
        shownPropertyString: "showBluetoothDialog"
        dialog: BluetoothDialog {}
        onShownChanged: {
            if (!Bluetooth.defaultAdapter) return
            Bluetooth.defaultAdapter.discovering = shown
        }
    }
    ToggleDialog { shownPropertyString: "showNightLightDialog"; dialog: NightLightDialog {} }
    ToggleDialog { shownPropertyString: "showHotspotDialog"; dialog: HotspotDialog {} }
    ToggleDialog { shownPropertyString: "showWifiDialog"; dialog: WifiDialog {} }
    ToggleDialog {
        shownPropertyString: "showEventsDialog"
        dialog: EventsDialog {}
        onShownChanged: {
            if (!shown || !dialog.item) return
            dialog.item.editingEvent = root.eventsDialogEditEvent
        }
    }
}
