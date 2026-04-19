import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.folderlistmodel
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.models

Item {
    id: root

    property string currentPath: ""
    property real fontScale: 1.0
    property string fileManager: "dolphin"
    property string terminal: "kitty"
    property bool showHiddenFiles: false

    signal navigateInto(string path)
    signal navigateUp()

    FolderListModelWithHistory {
        id: folderModel
        folder: root.currentPath ? ("file://" + root.currentPath) : ""
        showHidden: root.showHiddenFiles
        showDirsFirst: true
        sortField: FolderListModel.Name
        nameFilters: []
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        BreadcrumbBar {
            id: breadcrumb
            Layout.fillWidth: true
            pathText: root.currentPath
            fontScale: root.fontScale
            onBackClicked: root.navigateUp()
        }

        // File list
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: folderModel
            spacing: 2

            delegate: FileItemDelegate {
                required property string fileName
                required property string filePath
                required property bool fileIsDir

                width: listView.width
                label: fileName
                isFolder: fileIsDir
                fontScale: root.fontScale

                onActivated: {
                    if (fileIsDir) {
                        root.navigateInto(filePath)
                    } else {
                        Quickshell.execDetached(["xdg-open", filePath])
                    }
                }
            }

            ScrollBar.vertical: StyledScrollBar { }
        }

        // Action bar
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: actionRow.implicitHeight + 10
            color: Appearance.colors.colLayer2

            RowLayout {
                id: actionRow
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: 8
                    rightMargin: 8
                }
                spacing: 8

                RippleButton {
                    Layout.fillWidth: true
                    buttonText: Translation.tr("Open FM")
                    onClicked: Quickshell.execDetached([root.fileManager, root.currentPath])
                }

                RippleButton {
                    Layout.fillWidth: true
                    buttonText: Translation.tr("$ Terminal")
                    onClicked: Quickshell.execDetached([root.terminal, "--working-directory", root.currentPath])
                }
            }
        }
    }
}
