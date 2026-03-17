import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

MouseArea {
    id: root
    required property var weData // {id, title, type, tags, preview, active}

    property alias colBackground: background.color
    property alias colText: titleText.color

    signal activated()

    hoverEnabled: true
    onClicked: root.activated()

    Rectangle {
        id: background
        anchors {
            fill: parent
            margins: Appearance.sizes.wallpaperSelectorItemMargins
        }
        radius: Appearance.rounding.normal
        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        ColumnLayout {
            id: contentLayout
            anchors {
                fill: parent
                margins: Appearance.sizes.wallpaperSelectorItemPadding
            }
            spacing: 4

            Item {
                id: imageContainer
                Layout.fillHeight: true
                Layout.fillWidth: true

                StyledRectangularShadow {
                    target: previewImage
                    visible: previewImage.status === Image.Ready
                    anchors.fill: undefined
                    radius: Appearance.rounding.small
                }

                Image {
                    id: previewImage
                    anchors.fill: parent
                    source: root.weData.preview ? ("file://" + root.weData.preview) : ""
                    fillMode: Image.PreserveAspectCrop
                    clip: true
                    cache: true
                    asynchronous: true
                    sourceSize.width: contentLayout.width
                    sourceSize.height: contentLayout.height - contentLayout.spacing - titleText.height

                    layer.enabled: Appearance.effectsEnabled
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: imageContainer.width
                            height: imageContainer.height
                            radius: Appearance.rounding.small
                        }
                    }
                }

                // Type badge
                Rectangle {
                    anchors {
                        top: parent.top
                        right: parent.right
                        margins: 4
                    }
                    visible: previewImage.status === Image.Ready
                    color: ColorUtils.setAlpha(Appearance.colors.colSurfaceContainer, 0.85)
                    radius: height / 2
                    width: badgeText.implicitWidth + 12
                    height: badgeText.implicitHeight + 6

                    StyledText {
                        id: badgeText
                        anchors.centerIn: parent
                        text: root.weData.type
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        color: Appearance.colors.colOnSurface
                    }
                }
            }

            StyledText {
                id: titleText
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                font.pixelSize: Appearance.font.pixelSize.smaller
                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }
                text: root.weData.title
            }
        }
    }
}
