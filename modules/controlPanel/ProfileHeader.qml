pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Qt5Compat.GraphicalEffects as GE
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root
    implicitHeight: 56
    Layout.fillWidth: true
    
    readonly property bool inirEverywhere: Appearance.inirEverywhere
    readonly property bool auroraEverywhere: Appearance.auroraEverywhere

    function getGreeting(): string {
        const hour = new Date().getHours()
        if (hour < 5) return Translation.tr("Good Night")
        if (hour < 12) return Translation.tr("Good Morning")
        if (hour < 18) return Translation.tr("Good Afternoon")
        return Translation.tr("Good Evening")
    }

    function openAccountSettings(): void {
        AppLauncher.launch("manageUser")
        GlobalStates.controlPanelOpen = false
    }

    function lockScreen(): void {
        GlobalStates.controlPanelOpen = false
        Quickshell.execDetached([Quickshell.shellPath("scripts/inir"), "lock", "activate"])
    }

    RowLayout {
        anchors.fill: parent
        spacing: 12

        // Avatar - themed circle with border using OpacityMask
        Item {
            id: avatarContainer
            Layout.preferredWidth: 48
            Layout.preferredHeight: 48

            // Border ring
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.width: 2
                border.color: Appearance.controlPanel.colAccent
            }

            // Avatar with OpacityMask for proper circular clipping
            Item {
                anchors.centerIn: parent
                width: 42
                height: 42

                Rectangle {
                    id: avatarMask
                    anchors.fill: parent
                    radius: width / 2
                    visible: false
                }

                Image {
                    id: avatarImg
                    anchors.fill: parent
                    source: profileAvatarResolver.resolvedSource
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    smooth: true
                    mipmap: true
                    sourceSize.width: 84
                    sourceSize.height: 84
                    visible: status === Image.Ready
                    layer.enabled: visible
                    layer.effect: GE.OpacityMask {
                        maskSource: avatarMask
                    }
                }

                // Reactive avatar resolver — retries fallback paths without breaking bindings
                QtObject {
                    id: profileAvatarResolver
                    property int avatarIndex: 0
                    readonly property string resolvedSource: Directories.avatarSourceAt(avatarIndex)

                    readonly property string primaryWatch: Directories.userAvatarSourcePrimary
                    onPrimaryWatchChanged: avatarIndex = 0

                    property bool _errorAdvanceScheduled: false
                    function _advanceOnError(): void {
                        if (profileAvatarResolver._errorAdvanceScheduled)
                            return
                        profileAvatarResolver._errorAdvanceScheduled = true
                        Qt.callLater(() => {
                            profileAvatarResolver._errorAdvanceScheduled = false
                            if (avatarImg.status !== Image.Error)
                                return
                            const nextIdx = profileAvatarResolver.avatarIndex + 1
                            if (nextIdx < Directories.availableUserAvatarPaths.length)
                                profileAvatarResolver.avatarIndex = nextIdx
                        })
                    }
                }

                Connections {
                    target: avatarImg
                    function onStatusChanged() {
                        if (avatarImg.status === Image.Error)
                            profileAvatarResolver._advanceOnError()
                    }
                }
                
                // Fallback
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: Appearance.controlPanel.colTrack
                    visible: avatarImg.status !== Image.Ready

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "person"
                        iconSize: 22
                        color: Appearance.controlPanel.colAccent
                    }
                }
            }
        }

        // Text
        ColumnLayout {
            spacing: 0
            StyledText {
                text: root.getGreeting()
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.controlPanel.colTextMuted
            }
            StyledText {
                text: SystemInfo.displayName || SystemInfo.username
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.Medium
                font.capitalization: Font.Capitalize
                color: Appearance.controlPanel.colText
            }
        }

        Item { Layout.fillWidth: true }

        // Action Buttons
        RowLayout {
            spacing: 4

            RippleButton {
                implicitWidth: 32
                implicitHeight: 32
                buttonRadius: Appearance.controlPanel.radiusButton
                colBackground: "transparent"
                colBackgroundHover: Appearance.controlPanel.colButtonHover
                onClicked: root.lockScreen()
                contentItem: MaterialSymbol { 
                    anchors.centerIn: parent
                    text: "lock"
                    iconSize: 18
                    color: Appearance.controlPanel.colText
                }
                StyledToolTip { text: Translation.tr("Lock") }
            }

            RippleButton {
                implicitWidth: 32
                implicitHeight: 32
                buttonRadius: Appearance.controlPanel.radiusButton
                colBackground: "transparent"
                colBackgroundHover: Appearance.controlPanel.colButtonHover
                onClicked: root.openAccountSettings()
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: "manage_accounts"
                    iconSize: 18
                    color: Appearance.controlPanel.colText
                }
                StyledToolTip { text: Translation.tr("Manage my account") }
            }

            RippleButton {
                implicitWidth: 32
                implicitHeight: 32
                buttonRadius: Appearance.controlPanel.radiusButton
                colBackground: "transparent"
                colBackgroundHover: Appearance.controlPanel.colButtonHover
                onClicked: {
                    GlobalStates.controlPanelOpen = false
                    GlobalStates.sessionOpen = true
                }
                contentItem: MaterialSymbol { 
                    anchors.centerIn: parent
                    text: "power_settings_new"
                    iconSize: 18
                    color: Appearance.controlPanel.colStatusCritical
                }
                StyledToolTip { text: Translation.tr("Power") }
            }
            
            RippleButton {
                implicitWidth: 32
                implicitHeight: 32
                buttonRadius: Appearance.controlPanel.radiusButton
                colBackground: "transparent"
                colBackgroundHover: Appearance.controlPanel.colButtonHover
                onClicked: GlobalStates.controlPanelOpen = false
                contentItem: MaterialSymbol { 
                    anchors.centerIn: parent
                    text: "close"
                    iconSize: 18
                    color: Appearance.controlPanel.colTextMuted
                }
                StyledToolTip { text: Translation.tr("Close") }
            }
        }
    }

}
