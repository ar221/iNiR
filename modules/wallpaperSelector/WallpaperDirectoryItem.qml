import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

MouseArea {
    id: root
    required property var fileModelData
    property bool isDirectory: fileModelData.fileIsDir
    property bool useThumbnail: Images.isValidMediaByName(fileModelData.fileName)
    property bool isFavorite: false
    signal favoriteToggled()

    property alias colBackground: background.color
    property alias colText: wallpaperItemName.color
    property alias radius: background.radius
    property alias margins: background.anchors.margins
    property alias padding: wallpaperItemColumnLayout.anchors.margins
    margins: Appearance.sizes.wallpaperSelectorItemMargins
    padding: Appearance.sizes.wallpaperSelectorItemPadding

    signal activated()

    hoverEnabled: true
    onClicked: root.activated()

    Rectangle {
        id: background
        anchors.fill: parent
        radius: Appearance.rounding.normal
        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        ColumnLayout {
            id: wallpaperItemColumnLayout
            anchors.fill: parent
            spacing: 4

            Item {
                id: wallpaperItemImageContainer
                Layout.fillHeight: true
                Layout.fillWidth: true

                Loader {
                    id: thumbnailShadowLoader
                    active: thumbnailImageLoader.active && thumbnailImageLoader.item.status === Image.Ready
                    anchors.fill: thumbnailImageLoader
                    sourceComponent: StyledRectangularShadow {
                        target: thumbnailImageLoader
                        anchors.fill: undefined
                        radius: Appearance.rounding.small
                    }
                }

                Loader {
                    id: thumbnailImageLoader
                    anchors.fill: parent
                    active: root.useThumbnail
                    sourceComponent: ThumbnailImage {
                        id: thumbnailImage
                        generateThumbnail: true
                        sourcePath: fileModelData.filePath

                        cache: false
                        fillMode: Image.PreserveAspectCrop
                        clip: true
                        sourceSize.width: wallpaperItemColumnLayout.width
                        sourceSize.height: wallpaperItemColumnLayout.height - wallpaperItemColumnLayout.spacing - wallpaperItemName.height

                        Connections {
                            target: Wallpapers
                            function onThumbnailGenerated(directory) {
                                if (thumbnailImage.status !== Image.Error) return;
                                if (FileUtils.parentDirectory(thumbnailImage.sourcePath) !== directory) return;
                                thumbnailImage.source = "";
                                thumbnailImage.source = thumbnailImage.thumbnailPath;
                            }
                            function onThumbnailGeneratedFile(filePath) {
                                if (thumbnailImage.status !== Image.Error) return;
                                if (Qt.resolvedUrl(thumbnailImage.sourcePath) !== Qt.resolvedUrl(filePath)) return;
                                thumbnailImage.source = "";
                                thumbnailImage.source = thumbnailImage.thumbnailPath;
                            }
                        }

                        layer.enabled: Appearance.effectsEnabled
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: wallpaperItemImageContainer.width
                                height: wallpaperItemImageContainer.height
                                radius: Appearance.rounding.small
                            }
                        }
                    }
                }

                Loader {
                    id: iconLoader
                    active: !root.useThumbnail
                    anchors.fill: parent
                    sourceComponent: DirectoryIcon {
                        fileModelData: root.fileModelData
                        sourceSize.width: wallpaperItemColumnLayout.width
                        sourceSize.height: wallpaperItemColumnLayout.height - wallpaperItemColumnLayout.spacing - wallpaperItemName.height
                    }
                }

                // Favorite heart overlay
                MouseArea {
                    id: heartButton
                    visible: !root.isDirectory && (root.containsMouse || root.isFavorite)
                    anchors {
                        top: parent.top
                        right: parent.right
                        margins: 4
                    }
                    width: 24
                    height: 24
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    z: 10

                    onClicked: root.favoriteToggled()

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: heartButton.containsMouse
                            ? ColorUtils.transparentize(Appearance.colors.colSurface, 0.2)
                            : ColorUtils.transparentize(Appearance.colors.colSurface, 0.4)
                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        iconSize: 18
                        text: root.isFavorite ? "favorite" : "favorite_border"
                        color: root.isFavorite ? Appearance.colors.colError : Appearance.colors.colOnSurface
                        fill: root.isFavorite ? 1 : 0
                    }
                }
            }

            StyledText {
                id: wallpaperItemName
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10

                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                font.pixelSize: Appearance.font.pixelSize.smaller
                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }
                text: fileModelData.fileName
            }
        }
    }
}
