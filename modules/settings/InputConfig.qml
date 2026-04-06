import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

ContentPage {
    id: inputPage
    settingsPageIndex: 13
    settingsPageName: Translation.tr("Input Devices")
    settingsPageIcon: "keyboard"

    // Refresh input data when page loads
    Component.onCompleted: IidSocket.refreshInput()

    // Re-read on input change events
    Connections {
        target: IidSocket
        function onInputChanged() { /* values auto-update via inputSettings binding */ }
    }

    // ── Debounce timers ───────────────────────────────────────────────
    // Keyboard
    Timer {
        id: kbRepeatDelayTimer
        interval: 200; repeat: false
        property int pendingValue: 300
        onTriggered: IidSocket.setKeyboard({ repeat_delay: pendingValue })
    }
    Timer {
        id: kbRepeatRateTimer
        interval: 200; repeat: false
        property int pendingValue: 50
        onTriggered: IidSocket.setKeyboard({ repeat_rate: pendingValue })
    }
    // Touchpad speed
    Timer {
        id: touchpadSpeedTimer
        interval: 200; repeat: false
        property real pendingValue: 0
        onTriggered: IidSocket.setTouchpad({ speed: pendingValue })
    }
    // Mouse speed
    Timer {
        id: mouseSpeedTimer
        interval: 200; repeat: false
        property real pendingValue: 0
        onTriggered: IidSocket.setMouse({ speed: pendingValue })
    }

    // ── Styled slider component ──────────────────────────────────────
    component StyledSlider: Slider {
        id: styledSlider
        Layout.fillWidth: true
        implicitHeight: 28

        background: Rectangle {
            x: styledSlider.leftPadding
            y: styledSlider.topPadding + styledSlider.availableHeight / 2 - height / 2
            width: styledSlider.availableWidth
            height: 4
            radius: 2
            color: Appearance.colors.colLayer1

            Rectangle {
                width: styledSlider.visualPosition * parent.width
                height: parent.height
                radius: 2
                color: Appearance.m3colors.m3primary
            }
        }

        handle: Rectangle {
            x: styledSlider.leftPadding + styledSlider.visualPosition * (styledSlider.availableWidth - width)
            y: styledSlider.topPadding + styledSlider.availableHeight / 2 - height / 2
            width: 20; height: 20; radius: 10
            color: styledSlider.pressed ? Appearance.colors.colPrimaryHover : Appearance.m3colors.m3primary
            border.width: 2
            border.color: Appearance.m3colors.m3onPrimary
        }
    }

    // ── Section 1: Keyboard ──────────────────────────────────────────
    SettingsCardSection {
        expanded: true
        icon: "keyboard"
        title: Translation.tr("Keyboard")

        SettingsGroup {
            // Layout
            ContentSubsection {
                title: Translation.tr("Layout")
                tooltip: Translation.tr("Keyboard layout identifier (e.g. us, gb, de, fr, es, ru, jp)")

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    MaterialTextField {
                        id: layoutField
                        Layout.fillWidth: true
                        text: IidSocket.inputSettings?.keyboard?.layout ?? "us"
                        onEditingFinished: {
                            const val = text.trim()
                            if (val.length > 0)
                                IidSocket.setKeyboard({ layout: val })
                        }
                    }
                }

                StyledText {
                    text: Translation.tr("Common: us, gb, de, fr, es, ru, jp, br, it, se, no, dk, fi, pl")
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colSubtext
                    Layout.topMargin: 4
                }
            }

            SettingsDivider {}

            // Repeat Delay
            ContentSubsection {
                title: Translation.tr("Repeat Delay")
                tooltip: Translation.tr("Delay before key repeat starts (ms)")

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    StyledText {
                        text: Translation.tr("Delay")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer1
                    }

                    StyledSlider {
                        id: repeatDelaySlider
                        from: 100; to: 1000; stepSize: 50
                        value: IidSocket.inputSettings?.keyboard?.repeat_delay ?? 300
                        onMoved: {
                            kbRepeatDelayTimer.pendingValue = value
                            kbRepeatDelayTimer.restart()
                        }
                    }

                    StyledText {
                        text: repeatDelaySlider.value.toFixed(0) + Translation.tr("ms")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                        Layout.preferredWidth: 60
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }

            SettingsDivider {}

            // Repeat Rate
            ContentSubsection {
                title: Translation.tr("Repeat Rate")
                tooltip: Translation.tr("How fast keys repeat (characters per second)")

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    StyledText {
                        text: Translation.tr("Rate")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer1
                    }

                    StyledSlider {
                        id: repeatRateSlider
                        from: 10; to: 100; stepSize: 5
                        value: IidSocket.inputSettings?.keyboard?.repeat_rate ?? 50
                        onMoved: {
                            kbRepeatRateTimer.pendingValue = value
                            kbRepeatRateTimer.restart()
                        }
                    }

                    StyledText {
                        text: repeatRateSlider.value.toFixed(0)
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                        Layout.preferredWidth: 40
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }

            SettingsDivider {}

            // Numlock
            SettingsSwitch {
                buttonIcon: "dialpad"
                text: Translation.tr("Numlock on startup")
                checked: IidSocket.inputSettings?.keyboard?.numlock ?? false
                onCheckedChanged: {
                    if (checked !== (IidSocket.inputSettings?.keyboard?.numlock ?? false))
                        IidSocket.setKeyboard({ numlock: checked })
                }
            }
        }
    }

    // ── Section 2: Touchpad ──────────────────────────────────────────
    SettingsCardSection {
        expanded: true
        icon: "touchpad_mouse"
        title: Translation.tr("Touchpad")

        SettingsGroup {
            // Tap to Click
            SettingsSwitch {
                buttonIcon: "touch_app"
                text: Translation.tr("Tap to Click")
                checked: IidSocket.inputSettings?.touchpad?.tap ?? true
                onCheckedChanged: {
                    if (checked !== (IidSocket.inputSettings?.touchpad?.tap ?? true))
                        IidSocket.setTouchpad({ tap: checked })
                }
                StyledToolTip {
                    text: Translation.tr("Tap the touchpad to click instead of pressing the button")
                }
            }

            SettingsDivider {}

            // Natural Scrolling
            SettingsSwitch {
                buttonIcon: "swap_vert"
                text: Translation.tr("Natural Scrolling")
                checked: IidSocket.inputSettings?.touchpad?.natural_scroll ?? true
                onCheckedChanged: {
                    if (checked !== (IidSocket.inputSettings?.touchpad?.natural_scroll ?? true))
                        IidSocket.setTouchpad({ natural_scroll: checked })
                }
                StyledToolTip {
                    text: Translation.tr("Content follows finger direction (like a phone). Disable for traditional scroll direction.")
                }
            }

            SettingsDivider {}

            // Disable While Typing
            SettingsSwitch {
                buttonIcon: "do_not_touch"
                text: Translation.tr("Disable While Typing")
                checked: IidSocket.inputSettings?.touchpad?.dwt ?? false
                onCheckedChanged: {
                    if (checked !== (IidSocket.inputSettings?.touchpad?.dwt ?? false))
                        IidSocket.setTouchpad({ dwt: checked })
                }
                StyledToolTip {
                    text: Translation.tr("Prevent accidental touchpad input while typing on the keyboard")
                }
            }

            SettingsDivider {}

            // Pointer Speed
            ContentSubsection {
                title: Translation.tr("Pointer Speed")
                tooltip: Translation.tr("Touchpad pointer acceleration speed (-1.0 to 1.0)")

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    StyledText {
                        text: Translation.tr("Slow")
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        color: Appearance.colors.colSubtext
                    }

                    StyledSlider {
                        id: touchpadSpeedSlider
                        from: -1.0; to: 1.0; stepSize: 0.1
                        value: IidSocket.inputSettings?.touchpad?.speed ?? 0
                        onMoved: {
                            touchpadSpeedTimer.pendingValue = value
                            touchpadSpeedTimer.restart()
                        }
                    }

                    StyledText {
                        text: Translation.tr("Fast")
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        color: Appearance.colors.colSubtext
                    }

                    StyledText {
                        text: touchpadSpeedSlider.value.toFixed(1)
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer1
                        font.weight: Font.DemiBold
                        Layout.preferredWidth: 36
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }

            SettingsDivider {}

            // Tap Button Map
            ContentSubsection {
                title: Translation.tr("Tap Button Map")
                tooltip: Translation.tr("Finger mapping for two-finger and three-finger taps")

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    RippleButton {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36

                        readonly property bool isActive: (IidSocket.inputSettings?.touchpad?.tap_button_map ?? "lrm") === "lrm"

                        contentItem: StyledText {
                            text: Translation.tr("Left-Right-Middle")
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: parent.isActive ? Font.Bold : Font.Normal
                            color: parent.isActive ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            radius: Appearance.rounding.small
                            color: parent.isActive ? Appearance.m3colors.m3primary : Appearance.colors.colLayer1
                            border.width: 1
                            border.color: parent.isActive ? Appearance.m3colors.m3primary : Appearance.colors.colLayer0Border
                        }

                        onClicked: {
                            if (!isActive)
                                IidSocket.setTouchpad({ tap_button_map: "lrm" })
                        }
                    }

                    RippleButton {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36

                        readonly property bool isActive: (IidSocket.inputSettings?.touchpad?.tap_button_map ?? "lrm") === "lmr"

                        contentItem: StyledText {
                            text: Translation.tr("Left-Middle-Right")
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: parent.isActive ? Font.Bold : Font.Normal
                            color: parent.isActive ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            radius: Appearance.rounding.small
                            color: parent.isActive ? Appearance.m3colors.m3primary : Appearance.colors.colLayer1
                            border.width: 1
                            border.color: parent.isActive ? Appearance.m3colors.m3primary : Appearance.colors.colLayer0Border
                        }

                        onClicked: {
                            if (!isActive)
                                IidSocket.setTouchpad({ tap_button_map: "lmr" })
                        }
                    }
                }
            }
        }
    }

    // ── Section 3: Mouse ─────────────────────────────────────────────
    SettingsCardSection {
        expanded: true
        icon: "mouse"
        title: Translation.tr("Mouse")

        SettingsGroup {
            // Acceleration Profile
            ContentSubsection {
                title: Translation.tr("Acceleration Profile")
                tooltip: Translation.tr("Flat = 1:1 movement (gaming). Adaptive = speeds up with faster movement (desktop).")

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    RippleButton {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36

                        readonly property bool isActive: (IidSocket.inputSettings?.mouse?.accel_profile ?? "flat") === "flat"

                        contentItem: RowLayout {
                            spacing: 6
                            Item { Layout.fillWidth: true }
                            MaterialSymbol {
                                text: "linear_scale"
                                iconSize: Appearance.font.pixelSize.normal
                                color: parent.parent.isActive ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                text: Translation.tr("Flat")
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: parent.parent.isActive ? Font.Bold : Font.Normal
                                color: parent.parent.isActive ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1
                            }
                            Item { Layout.fillWidth: true }
                        }

                        background: Rectangle {
                            radius: Appearance.rounding.small
                            color: parent.isActive ? Appearance.m3colors.m3primary : Appearance.colors.colLayer1
                            border.width: 1
                            border.color: parent.isActive ? Appearance.m3colors.m3primary : Appearance.colors.colLayer0Border
                        }

                        onClicked: {
                            if (!isActive)
                                IidSocket.setMouse({ accel_profile: "flat" })
                        }
                    }

                    RippleButton {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36

                        readonly property bool isActive: (IidSocket.inputSettings?.mouse?.accel_profile ?? "flat") === "adaptive"

                        contentItem: RowLayout {
                            spacing: 6
                            Item { Layout.fillWidth: true }
                            MaterialSymbol {
                                text: "trending_up"
                                iconSize: Appearance.font.pixelSize.normal
                                color: parent.parent.isActive ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                text: Translation.tr("Adaptive")
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: parent.parent.isActive ? Font.Bold : Font.Normal
                                color: parent.parent.isActive ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1
                            }
                            Item { Layout.fillWidth: true }
                        }

                        background: Rectangle {
                            radius: Appearance.rounding.small
                            color: parent.isActive ? Appearance.m3colors.m3primary : Appearance.colors.colLayer1
                            border.width: 1
                            border.color: parent.isActive ? Appearance.m3colors.m3primary : Appearance.colors.colLayer0Border
                        }

                        onClicked: {
                            if (!isActive)
                                IidSocket.setMouse({ accel_profile: "adaptive" })
                        }
                    }
                }
            }

            SettingsDivider {}

            // Pointer Speed
            ContentSubsection {
                title: Translation.tr("Pointer Speed")
                tooltip: Translation.tr("Mouse pointer speed (-1.0 to 1.0)")

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    StyledText {
                        text: Translation.tr("Slow")
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        color: Appearance.colors.colSubtext
                    }

                    StyledSlider {
                        id: mouseSpeedSlider
                        from: -1.0; to: 1.0; stepSize: 0.1
                        value: IidSocket.inputSettings?.mouse?.speed ?? 0
                        onMoved: {
                            mouseSpeedTimer.pendingValue = value
                            mouseSpeedTimer.restart()
                        }
                    }

                    StyledText {
                        text: Translation.tr("Fast")
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        color: Appearance.colors.colSubtext
                    }

                    StyledText {
                        text: mouseSpeedSlider.value.toFixed(1)
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer1
                        font.weight: Font.DemiBold
                        Layout.preferredWidth: 36
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }
    }

    // ── Section 4: Daemon Status ─────────────────────────────────────
    SettingsCardSection {
        expanded: false
        icon: "dns"
        title: Translation.tr("Input Daemon")

        SettingsGroup {
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Layout.margins: 8

                MaterialSymbol {
                    text: IidSocket.connected ? "check_circle" : "error"
                    iconSize: Appearance.font.pixelSize.larger
                    color: IidSocket.connected ? Appearance.m3colors.m3tertiary : Appearance.colors.colError
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    StyledText {
                        text: IidSocket.connected
                            ? Translation.tr("Connected to iid daemon")
                            : Translation.tr("Not connected — input settings unavailable")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: IidSocket.connected ? Appearance.colors.colOnLayer1 : Appearance.colors.colError
                    }

                    StyledText {
                        visible: !IidSocket.connected
                        text: Translation.tr("Start the iid service: systemctl --user start iid")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                }
            }
        }
    }
}
