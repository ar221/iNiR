pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.modules.common
import qs.modules.common.widgets
import qs.services

/**
 * QueuePreview — Shows next tracks from the YtMusic queue.
 *
 * Data source: YtMusic.queue (only available when YtMusic is active).
 * Each item has: { title, artist, duration, thumbnail }.
 * Skip: YtMusic.playFromQueue(index).
 *
 * Collapses to height 0 when YtMusic is not active or queue is empty.
 * For non-YtMusic players there is no queue API — component stays collapsed.
 */
Item {
    id: root

    Layout.fillWidth: true
    Layout.preferredHeight: _visible ? _listView.contentHeight : 0

    clip: true

    readonly property bool _visible: MprisController.isYtMusicActive && YtMusic.queue.length > 0

    Behavior on Layout.preferredHeight {
        enabled: Appearance.animationsEnabled
        NumberAnimation {
            duration: _visible ? 150 : 80
            easing.type: Easing.InOutQuad
        }
    }

    // ── Helper: format seconds to m:ss ───────────────────────────────────
    function _fmt(secs): string {
        if (!secs || secs <= 0) return "—"
        const s = Math.floor(secs)
        const m = Math.floor(s / 60)
        const sec = s % 60
        return m + ":" + String(sec).padStart(2, "0")
    }

    ListView {
        id: _listView
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        // Cap at 5 items; each row is 44px
        height: Math.min(contentHeight, 5 * 44)
        clip: true
        model: root._visible ? YtMusic.queue : []
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds

        delegate: Item {
            id: _row
            required property var modelData
            required property int index

            width: _listView.width
            height: 44

            readonly property bool _isCurrent: false  // queue items are not-yet-playing

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                radius: 2

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 4
                    anchors.rightMargin: 6
                    spacing: 8

                    // Track number
                    Text {
                        text: String(_row.index + 1).padStart(2, "0")
                        font.pixelSize: 9
                        font.family: Appearance.font.numbers?.family ?? Appearance.font.family.main
                        color: Qt.rgba(
                            Appearance.colors.colOnSurfaceVariant.r,
                            Appearance.colors.colOnSurfaceVariant.g,
                            Appearance.colors.colOnSurfaceVariant.b,
                            0.35
                        )
                        Layout.preferredWidth: 20
                        horizontalAlignment: Text.AlignRight
                    }

                    // Mini art
                    Rectangle {
                        implicitWidth: 28
                        implicitHeight: 28
                        radius: 2
                        color: Appearance.colors.colSecondaryContainer
                        clip: true

                        StyledImage {
                            anchors.fill: parent
                            source: _row.modelData?.thumbnail ?? ""
                            fillMode: Image.PreserveAspectCrop
                        }
                    }

                    // Title + artist column
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            Layout.fillWidth: true
                            text: _row.modelData?.title ?? ""
                            font.pixelSize: 11
                            color: Appearance.colors.colOnLayer1
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            wrapMode: Text.NoWrap
                        }

                        Text {
                            Layout.fillWidth: true
                            text: _row.modelData?.artist ?? ""
                            font.pixelSize: 9
                            color: ColorUtils.applyAlpha(Appearance.colors.colOnSurfaceVariant, 0.55)
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            wrapMode: Text.NoWrap
                        }
                    }

                    // Duration
                    Text {
                        text: root._fmt(_row.modelData?.duration ?? 0)
                        font.pixelSize: 9
                        font.family: Appearance.font.numbers?.family ?? Appearance.font.family.main
                        color: Qt.rgba(
                            Appearance.colors.colOnSurfaceVariant.r,
                            Appearance.colors.colOnSurfaceVariant.g,
                            Appearance.colors.colOnSurfaceVariant.b,
                            0.40
                        )
                        Layout.preferredWidth: 32
                        horizontalAlignment: Text.AlignRight
                    }
                }

                // Click to play from queue
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onContainsMouseChanged: {
                        parent.color = containsMouse
                            ? ColorUtils.applyAlpha("#ff1100", 0.06)
                            : "transparent"
                    }

                    onClicked: YtMusic.playFromQueue(_row.index)
                }
            }
        }

        // Scroll fade mask — bottom edge
        layer.enabled: _listView.contentHeight > _listView.height
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: _listView.width
                height: _listView.height
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "white" }
                    GradientStop { position: 0.75; color: "white" }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }
        }
    }
}
