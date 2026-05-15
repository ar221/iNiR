import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.dashboard
import qs.services

// Dispatch Packet hero band — the dashboard's focal landing zone.
// Full-width strip above the three columns. Answers, left to right:
//   STATE   — who/when (greeting + live clock + date)
//   STATUS  — synthesized system verdict (nominal / rising / elevated)
//   NEXT    — the single most relevant pending item (event or notifications)
// Deliberately telemetry-light: it sets attention, the columns carry detail.
Rectangle {
    id: root

    Layout.fillWidth: true
    implicitHeight: 116
    radius: Appearance.mission.radiusLarge
    color: Appearance.mission.colPanel
    border.width: Appearance.mission.borderWidth
    border.color: Appearance.mission.colBorderSubtle
    clip: true

    // ── Hot accent hairline (receipt grammar — shared with rail/cards) ──
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 1
        color: Appearance.mission.colBorderHot
    }

    // ── Scanline wash under the accent line ──
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 48
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: Appearance.mission.colScanline }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // ── Derived state ──
    readonly property int _hour: DateTime.clock.date.getHours()
    readonly property string _greeting: {
        if (_hour < 5) return "STILL UP"
        if (_hour < 12) return "GOOD MORNING"
        if (_hour < 17) return "GOOD AFTERNOON"
        if (_hour < 22) return "GOOD EVENING"
        return "GOOD NIGHT"
    }
    readonly property string _operator: {
        const configured = Config.options?.dashboard?.profile?.displayName ?? ""
        const raw = configured !== "" ? configured : "operator"
        const first = raw.split(" ")[0]
        return first.length > 0 ? first.charAt(0).toUpperCase() + first.slice(1) : "Operator"
    }

    readonly property int _cpu: Math.round(ResourceUsage.cpuUsage * 100)
    readonly property int _gpu: Math.round(ResourceUsage.gpuUsage * 100)
    readonly property int _ram: Math.round(ResourceUsage.memoryUsedPercentage * 100)
    readonly property int _temp: ResourceUsage.maxTemp

    readonly property bool _elevated: _cpu >= 90 || _gpu >= 90 || _ram >= 95 || _temp >= 85
    readonly property bool _caution: !_elevated && (_cpu >= 70 || _gpu >= 70 || _ram >= 80 || _temp >= 75)
    readonly property string _statusLabel: _elevated ? "SYSTEM ELEVATED"
        : _caution ? "LOAD RISING" : "ALL SYSTEMS NOMINAL"
    readonly property color _statusColor: _elevated ? Appearance.mission.colCritical
        : _caution ? Appearance.mission.colWaiting : Appearance.mission.colDone
    readonly property string _statusDetail: {
        if (_elevated || _caution)
            return "CPU " + _cpu + "%  ·  GPU " + _gpu + "%  ·  RAM " + _ram + "%  ·  " + _temp + "°"
        return "CPU " + _cpu + "%  ·  RAM " + _ram + "%  ·  " + _temp + "°  ·  up " + DateTime.uptime
    }

    readonly property var _nextEvent: (CalendarSync?.list?.length ?? 0) > 0 ? CalendarSync.list[0] : null
    readonly property int _notifCount: Notifications?.list?.length ?? 0
    readonly property string _nextLabel: {
        if (_nextEvent) return _nextEvent.title ?? _nextEvent.summary ?? _nextEvent.name ?? "Upcoming event"
        if (_notifCount > 0) return _notifCount + (_notifCount === 1 ? " notification pending" : " notifications pending")
        return "Awaiting operator input"
    }
    readonly property string _nextMeta: {
        if (_nextEvent) return (_nextEvent.time ?? _nextEvent.dateTime ?? "") !== "" ? (_nextEvent.time ?? _nextEvent.dateTime) : "scheduled"
        if (_notifCount > 0) return "review queue"
        return "channel clear"
    }
    readonly property string _nextTag: _nextEvent ? "EVENT" : (_notifCount > 0 ? "INBOX" : "IDLE")
    readonly property color _nextColor: _nextEvent ? Appearance.mission.colAccent
        : (_notifCount > 0 ? Appearance.mission.colWaiting : Appearance.mission.colTextMuted)

    RowLayout {
        anchors.fill: parent
        anchors.margins: 18
        anchors.topMargin: 16
        spacing: 0

        // ════════════ STATE — greeting + clock ════════════
        ColumnLayout {
            Layout.fillHeight: true
            Layout.preferredWidth: 340
            spacing: 2

            StyledText {
                text: root._greeting + ", " + root._operator.toUpperCase()
                font.pixelSize: 10
                font.weight: Font.Bold
                font.letterSpacing: 1.8
                font.family: Appearance.font.family.monospace
                color: Appearance.mission.colTextMuted
            }

            RowLayout {
                spacing: 10
                Layout.topMargin: 2

                StyledText {
                    text: DateTime.time
                    font.pixelSize: 44
                    font.weight: Font.Bold
                    font.family: Appearance.font.family.numbers
                    color: Appearance.mission.colText
                }

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: 1
                    implicitHeight: 30
                    color: Appearance.mission.colGrid
                }

                StyledText {
                    Layout.alignment: Qt.AlignVCenter
                    text: DateTime.date.toUpperCase()
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.8
                    font.family: Appearance.font.family.monospace
                    color: Appearance.mission.colTextSecondary
                    wrapMode: Text.WordWrap
                    Layout.maximumWidth: 130
                }
            }

            Item { Layout.fillHeight: true }
        }

        // ── divider ──
        Rectangle {
            Layout.fillHeight: true
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            implicitWidth: 1
            color: Appearance.mission.colGrid
        }

        // ════════════ STATUS — synthesized verdict ════════════
        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.leftMargin: 22
            Layout.rightMargin: 22
            spacing: 4

            StyledText {
                text: "STATUS"
                font.pixelSize: 9
                font.weight: Font.Bold
                font.letterSpacing: 1.8
                font.family: Appearance.font.family.monospace
                color: Appearance.mission.colTextFaint
            }

            RowLayout {
                spacing: 10
                Layout.topMargin: 2

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: 9
                    implicitHeight: 9
                    radius: 2
                    color: root._statusColor

                    SequentialAnimation on opacity {
                        running: !root._elevated
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.5; duration: 1100; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0; duration: 1100; easing.type: Easing.InOutSine }
                    }
                    SequentialAnimation on opacity {
                        running: root._elevated
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.25; duration: 420; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0; duration: 420; easing.type: Easing.InOutSine }
                    }
                }

                StyledText {
                    text: root._statusLabel
                    font.pixelSize: 22
                    font.weight: Font.Bold
                    font.family: Appearance.font.family.monospace
                    color: root._statusColor
                }
            }

            StyledText {
                text: root._statusDetail
                font.pixelSize: 11
                font.family: Appearance.font.family.monospace
                color: Appearance.mission.colTextMuted
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Item { Layout.fillHeight: true }
        }

        // ── divider ──
        Rectangle {
            Layout.fillHeight: true
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            implicitWidth: 1
            color: Appearance.mission.colGrid
        }

        // ════════════ NEXT — single most relevant pending item ════════════
        ColumnLayout {
            Layout.fillHeight: true
            Layout.preferredWidth: 300
            Layout.leftMargin: 22
            spacing: 4

            RowLayout {
                spacing: 8

                StyledText {
                    text: "NEXT"
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    font.letterSpacing: 1.8
                    font.family: Appearance.font.family.monospace
                    color: Appearance.mission.colTextFaint
                }

                Rectangle {
                    Layout.preferredHeight: 16
                    Layout.preferredWidth: tagText.implicitWidth + 14
                    radius: Appearance.mission.radiusSmall
                    color: Qt.rgba(root._nextColor.r, root._nextColor.g, root._nextColor.b, 0.16)
                    border.width: 1
                    border.color: Qt.rgba(root._nextColor.r, root._nextColor.g, root._nextColor.b, 0.45)

                    StyledText {
                        id: tagText
                        anchors.centerIn: parent
                        text: root._nextTag
                        font.pixelSize: 8
                        font.weight: Font.Bold
                        font.letterSpacing: 1.0
                        font.family: Appearance.font.family.monospace
                        color: Appearance.mission.colText
                    }
                }
            }

            StyledText {
                text: root._nextLabel
                font.pixelSize: 15
                font.weight: Font.DemiBold
                color: Appearance.mission.colText
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.topMargin: 2
            }

            StyledText {
                text: root._nextMeta
                font.pixelSize: 11
                font.family: Appearance.font.family.monospace
                color: Appearance.mission.colTextMuted
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Item { Layout.fillHeight: true }
        }
    }
}
