pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.modules.common
import qs.services

/**
 * ContextCards — rotating system info cards for the Deck SystemView.
 *
 * Cards: Uptime · Kernel · Packages · Load Avg · Shell Sessions
 * 8s cycle (configurable), 120ms crossfade, tap to advance.
 *
 * Processes are triggered by a timer and use StdioCollector for one-shot output.
 * Gate: only poll when active = true AND sidebar is open.
 */
Item {
    id: root

    property bool active: false

    Layout.fillWidth: true

    // ── Data stores ───────────────────────────────────────────────────
    property string _uptime:   "..."
    property string _kernel:   "..."
    property string _packages: "..."
    property string _loadavg:  "..."
    property string _sessions: "..."

    readonly property var _cards: [
        { title: "UPTIME",   value: root._uptime   },
        { title: "KERNEL",   value: root._kernel   },
        { title: "PKGS",     value: root._packages },
        { title: "LOAD AVG", value: root._loadavg  },
        { title: "SESSIONS", value: root._sessions },
    ]

    property int _currentIndex: 0

    // ── Processes ─────────────────────────────────────────────────────
    readonly property bool _shouldPoll: root.active && GlobalStates.sidebarLeftOpen

    Process {
        id: uptimeProc
        command: ["uptime", "-p"]
        running: false
        stdout: StdioCollector {
            id: uptimeCollector
            onStreamFinished: root._uptime = uptimeCollector.text.trim().replace(/^up /, "")
        }
    }

    Process {
        id: kernelProc
        command: ["uname", "-r"]
        running: false
        stdout: StdioCollector {
            id: kernelCollector
            onStreamFinished: root._kernel = kernelCollector.text.trim()
        }
    }

    Process {
        id: packagesProc
        command: ["bash", "-c", "pacman -Q | wc -l"]
        running: false
        stdout: StdioCollector {
            id: packagesCollector
            onStreamFinished: root._packages = packagesCollector.text.trim() + " pkgs"
        }
    }

    Process {
        id: loadavgProc
        command: ["bash", "-c", "cat /proc/loadavg | cut -d' ' -f1-3"]
        running: false
        stdout: StdioCollector {
            id: loadavgCollector
            onStreamFinished: root._loadavg = loadavgCollector.text.trim()
        }
    }

    Process {
        id: sessionsProc
        command: ["bash", "-c", "who | wc -l"]
        running: false
        stdout: StdioCollector {
            id: sessionsCollector
            onStreamFinished: root._sessions = sessionsCollector.text.trim()
        }
    }

    // ── Poll trigger: run all processes once per cycle ────────────────
    function _triggerPoll() {
        if (!root._shouldPoll) return
        if (!uptimeProc.running)   uptimeProc.running   = true
        if (!kernelProc.running)   kernelProc.running   = true
        if (!packagesProc.running) packagesProc.running = true
        if (!loadavgProc.running)  loadavgProc.running  = true
        if (!sessionsProc.running) sessionsProc.running = true
    }

    // ── Card cycle timer ──────────────────────────────────────────────
    readonly property int _cycleInterval: Config.options?.sidebar?.deck?.system?.contextInterval ?? 8000

    Timer {
        id: cycleTimer
        interval: root._cycleInterval
        repeat: true
        running: root._shouldPoll
        onTriggered: {
            root._currentIndex = (root._currentIndex + 1) % root._cards.length
            root._triggerPoll()
        }
    }

    // Initial poll when activated
    on_ShouldPollChanged: {
        if (root._shouldPoll) {
            root._triggerPoll()
        }
    }

    // ── UI ────────────────────────────────────────────────────────────
    Item {
        id: cardContainer
        anchors.left: parent.left
        anchors.right: parent.right
        implicitHeight: 64

        // Previous card (fades out)
        Rectangle {
            id: prevCard
            anchors.fill: parent
            radius: 2
            color: Appearance.colors.colLayer0
            border.width: 1
            border.color: Appearance.colors.colLayer1
            opacity: 0

            property int _cardIndex: 0
            readonly property var _data: root._cards[_cardIndex % root._cards.length]

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 1

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: prevCard._data?.title ?? ""
                    font.pixelSize: 10
                    font.letterSpacing: 1.5
                    font.capitalization: Font.AllUppercase
                    color: Appearance.colors.colOnLayer1Inactive
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: prevCard._data?.value ?? "..."
                    font.family: Appearance.font.family.monospace
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer1
                }
            }
        }

        // Current card (fades in)
        Rectangle {
            id: currentCard
            anchors.fill: parent
            radius: 2
            color: Appearance.colors.colLayer0
            border.width: 1
            border.color: Appearance.colors.colLayer1
            opacity: 1

            property int _cardIndex: root._currentIndex
            readonly property var _data: root._cards[_cardIndex % root._cards.length]

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 1

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: currentCard._data?.title ?? ""
                    font.pixelSize: 10
                    font.letterSpacing: 1.5
                    font.capitalization: Font.AllUppercase
                    color: Appearance.colors.colOnLayer1Inactive
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: currentCard._data?.value ?? "..."
                    font.family: Appearance.font.family.monospace
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer1
                }
            }

            Behavior on opacity {
                enabled: Appearance.animationsEnabled
                NumberAnimation { duration: 120 }
            }
        }

        // Tap to advance
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root._currentIndex = (root._currentIndex + 1) % root._cards.length
                root._triggerPoll()
            }
        }
    }

    // Dot indicators
    RowLayout {
        anchors.top: cardContainer.bottom
        anchors.topMargin: 4
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 4

        Repeater {
            model: root._cards.length
            Rectangle {
                required property int index
                width: index === root._currentIndex ? 16 : 6
                height: 6
                radius: 2
                color: index === root._currentIndex
                    ? Appearance.colors.colPrimary
                    : Appearance.colors.colLayer1
                Behavior on width {
                    enabled: Appearance.animationsEnabled
                    NumberAnimation { duration: 200 }
                }
                Behavior on color {
                    enabled: Appearance.animationsEnabled
                    ColorAnimation { duration: 200 }
                }
            }
        }
    }

    implicitHeight: cardContainer.implicitHeight + 16
}
