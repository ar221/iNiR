import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: root
    required property bool isSink
    readonly property list<var> appPwNodes: isSink ? Audio.outputAppNodes : Audio.inputAppNodes
    readonly property list<var> devices: isSink ? Audio.outputDevices : Audio.inputDevices
    readonly property bool hasApps: appPwNodes.length > 0
    readonly property var currentDevice: isSink ? Audio.defaultSink : Audio.source
    spacing: 16

    // Device selector button
    RippleButton {
        id: deviceButton
        Layout.fillWidth: true
        Layout.topMargin: 8
        implicitHeight: 48
        
        colBackground: Appearance.sidebar.colSubCard
        colBackgroundHover: Appearance.sidebar.colSubCardHover
        colRipple: Appearance.sidebar.colSubCardActive
        buttonRadius: Appearance.sidebar.radiusCard

        contentItem: RowLayout {
            anchors {
                fill: parent
                leftMargin: 16
                rightMargin: 16
            }
            spacing: 12

            MaterialSymbol {
                text: root.isSink ? "speaker" : "mic"
                iconSize: 24
                color: Appearance.sidebar.colAccent
            }

            StyledText {
                Layout.fillWidth: true
                text: Audio.friendlyDeviceName(root.currentDevice) || (root.isSink ? Translation.tr("Select output...") : Translation.tr("Select input..."))
                font.pixelSize: Appearance.font.pixelSize.normal
                elide: Text.ElideRight
                color: Appearance.sidebar.colText
            }

            MaterialSymbol {
                text: devicePopup.visible ? "expand_less" : "expand_more"
                iconSize: Appearance.font.pixelSize.normal
                color: Appearance.sidebar.colTextSecondary
            }
        }

        onClicked: devicePopup.visible ? devicePopup.close() : devicePopup.open()
    }

    // Device selection popup
    Popup {
        id: devicePopup
        y: deviceButton.y + deviceButton.height + 4
        width: deviceButton.width
        height: Math.min(250, deviceList.contentHeight + 16)
        padding: 8

        background: Rectangle {
            color: Appearance.angelEverywhere ? Appearance.angel.colGlassPopup
                : Appearance.auroraEverywhere ? Appearance.aurora.colPopupSurface : Appearance.sidebar.colCard
            radius: Appearance.sidebar.radiusCard
            border.width: Appearance.angelEverywhere ? Appearance.angel.cardBorderWidth : 1
            border.color: Appearance.angelEverywhere ? Appearance.angel.colCardBorder
                : Appearance.auroraEverywhere ? Appearance.aurora.colTooltipBorder : Appearance.sidebar.colCardBorder
        }

        ListView {
            id: deviceList
            anchors.fill: parent
            clip: true
            spacing: 4
            model: root.devices

            delegate: RippleButton {
                required property var modelData
                required property int index
                width: deviceList.width
                implicitHeight: 44

                property bool isSelected: modelData.id === root.currentDevice?.id

                colBackground: isSelected ? Appearance.sidebar.colAccentSurface : "transparent"
                colBackgroundHover: Appearance.sidebar.colSubCardHover
                colRipple: Appearance.sidebar.colSubCardActive
                buttonRadius: Appearance.sidebar.radiusSmall

                contentItem: RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 12
                        rightMargin: 12
                    }
                    spacing: 8

                    MaterialSymbol {
                        text: isSelected ? "check" : (root.isSink ? "speaker" : "mic")
                        iconSize: Appearance.font.pixelSize.normal
                        color: isSelected ? Appearance.sidebar.colOnAccent : Appearance.sidebar.colTextSecondary
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Audio.friendlyDeviceName(modelData)
                        font.pixelSize: Appearance.font.pixelSize.normal
                        elide: Text.ElideRight
                        color: isSelected ? Appearance.sidebar.colOnAccent : Appearance.sidebar.colText
                    }
                }

                onClicked: {
                    if (root.isSink) Audio.setDefaultSink(modelData)
                    else Audio.setDefaultSource(modelData)
                    devicePopup.close()
                }
            }
        }
    }

    // Apps list
    DialogSectionListView {
        Layout.fillHeight: true
        topMargin: 14

        model: ScriptModel {
            values: root.appPwNodes
        }
        delegate: VolumeMixerEntry {
            anchors {
                left: parent?.left
                right: parent?.right
            }
            required property var modelData
            node: modelData
        }
        MaterialPlaceholderMessage {
            anchors.centerIn: parent
            maximumWidth: 320
            shown: !root.hasApps
            icon: "widgets"
            text: Translation.tr("No applications")
            explanation: root.isSink
                ? Translation.tr("Apps playing audio will appear here")
                : Translation.tr("Apps using the microphone will appear here")
            shape: MaterialShape.Shape.Clover4Leaf
        }
    }

    component DialogSectionListView: StyledListView {
        Layout.fillWidth: true
        Layout.topMargin: -22
        Layout.bottomMargin: -16
        Layout.leftMargin: -Appearance.sidebar.radiusCard
        Layout.rightMargin: -Appearance.sidebar.radiusCard
        topMargin: 12
        bottomMargin: 12
        leftMargin: 20
        rightMargin: 20

        clip: true
        spacing: 4
        animateAppearance: false

        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: height * 0.5 - 34
        preferredHighlightEnd: height * 0.5 + 34
        highlightMoveDuration: Appearance.animationsEnabled ? Appearance.calcEffectiveDuration(180) : 0
        highlightFollowsCurrentItem: true
    }
}
