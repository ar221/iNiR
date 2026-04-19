import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    property var bookmarks: []
    property real fontScale: 1.0

    signal bookmarkClicked(string path)

    ListView {
        id: listView
        anchors.fill: parent
        clip: true
        model: root.bookmarks
        spacing: 2

        delegate: FileItemDelegate {
            required property var modelData
            required property int index
            width: listView.width
            label: modelData.label ?? ""
            isFolder: true
            fontScale: root.fontScale
            accentIndex: index
            onActivated: root.bookmarkClicked(modelData.path ?? "")
        }

        ScrollBar.vertical: StyledScrollBar { }
    }
}
