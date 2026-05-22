import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower

Rectangle {
    id: root

    property var screen: root.QsWindow.window?.screen
    // Brightness monitor may be undefined (e.g. Niri without matching monitor); guard it.
    property var brightnessMonitor: screen ? Brightness.getMonitorForScreen(screen) : null

    implicitWidth: contentItem.implicitWidth + root.horizontalPadding * 2
    implicitHeight: contentItem.implicitHeight + root.verticalPadding * 2
    radius: Appearance.sidebar.radiusCard
    color: Appearance.sidebar.colCard
    border.width: Appearance.sidebar.borderWidth
    border.color: Appearance.sidebar.colCardBorder
    property real verticalPadding: 10
    property real horizontalPadding: 14

    AngelPartialBorder {
        targetRadius: root.radius
        coverage: 0.5
    }

    RowLayout {
        id: contentItem
        anchors {
            fill: parent
            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
            topMargin: root.verticalPadding
            bottomMargin: root.verticalPadding
        }
        spacing: 12

        Loader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: active
            active: (Config.options?.sidebar?.quickSliders?.showBrightness ?? true) && !!root.brightnessMonitor
            sourceComponent: QuickSlider {
                materialSymbol: "brightness_6"
                modelValue: root.brightnessMonitor?.brightness ?? 0
                onMoved: root.brightnessMonitor?.setBrightness(value)
            }
        }

        Loader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: active
            active: Config.options?.sidebar?.quickSliders?.showVolume ?? true
            sourceComponent: QuickSlider {
                materialSymbol: "volume_up"
                modelValue: Audio.sink?.audio?.volume ?? 0
                onMoved: {
                    if (Audio.sink?.audio)
                        Audio.sink.audio.volume = value
                }
            }
        }

        Loader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: active
            active: Config.options?.sidebar?.quickSliders?.showMic ?? false
            sourceComponent: QuickSlider {
                materialSymbol: "mic"
                modelValue: Audio.micVolume
                onMoved: Audio.setSourceVolume(value)
            }
        }
    }

    component QuickSlider: StyledSlider { 
        id: quickSlider
        required property string materialSymbol
        property real modelValue: 0
        configuration: StyledSlider.Configuration.M
        stopIndicatorValues: []
        scrollable: true

        // Sync from model only when not interacting, with threshold to avoid micro-jumps
        onModelValueChanged: {
            if (!pressed && !_userInteracting) {
                if (Math.abs(value - modelValue) > 0.005) {
                    value = modelValue
                }
            }
        }
        
        MaterialSymbol {
            id: icon
            property bool nearFull: quickSlider.value >= 0.9
            anchors {
                verticalCenter: parent.verticalCenter
                right: nearFull ? quickSlider.handle.right : parent.right
                rightMargin: nearFull ? 14 : 8
            }
            iconSize: 22
            color: nearFull
                ? Appearance.sidebar.colOnAccent
                : Appearance.sidebar.colTextOnSubCard
            text: quickSlider.materialSymbol

            Behavior on color {
                animation: ColorAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
            }
            Behavior on anchors.rightMargin {
                animation: NumberAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
            }

        }
    }
}
