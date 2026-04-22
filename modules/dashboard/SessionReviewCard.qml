import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

DashboardCard {
    id: root

    headerText: "Session Review"

    property var events: []

    function riskLevelFor(entry) {
        const src = String(entry?.source ?? "")
        const summary = String(entry?.summary ?? "").toLowerCase()
        if (src === "system" || summary.includes("error") || summary.includes("failed")) return "high"
        if (src === "pacman" || summary.includes("warning") || summary.includes("update")) return "medium"
        return "low"
    }

    function reversibleFor(entry) {
        const src = String(entry?.source ?? "")
        return src === "git" || src === "claude"
    }

    function iconFor(entry) {
        switch (String(entry?.source ?? "")) {
        case "git": return "commit"
        case "pacman": return "inventory_2"
        case "system": return "warning"
        case "claude": return "smart_toy"
        default: return "fact_check"
        }
    }

    function riskColor(level) {
        if (level === "high")
            return Appearance.colors.colError
        if (level === "medium")
            return Appearance.colors.colWarn
        return Appearance.colors.colDone
    }

    function parseFeed(text) {
        if (!text || text.trim() === "") {
            root.events = []
            return
        }

        const rows = []
        const lines = text.trim().split("\n")
        for (let i = 0; i < lines.length && rows.length < 5; i++) {
            const line = lines[i]
            if (!line || !line.trim()) continue
            try {
                const entry = JSON.parse(line)
                const risk = riskLevelFor(entry)
                rows.push({
                    icon: iconFor(entry),
                    title: entry.summary ?? "Activity event",
                    risk: risk,
                    reversible: reversibleFor(entry),
                    source: String(entry.source ?? ""),
                })
            } catch (e) {
                // skip malformed lines
            }
        }
        root.events = rows
    }

    FileView {
        id: feedFile
        path: Qt.resolvedUrl("file://" + Quickshell.env("HOME") + "/.local/state/inir/activity-feed.jsonl")
        watchChanges: true
        onLoaded: root.parseFeed(feedFile.text())
        onLoadFailed: (error) => {
            if (error !== FileViewError.FileNotFound)
                console.warn("[SessionReviewCard] Failed to read feed:", error)
            root.events = []
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6

        Repeater {
            model: root.events

            Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 38
                radius: 10
                color: Qt.rgba(1, 1, 1, 0.03)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.06)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8

                    MaterialSymbol {
                        text: modelData.icon
                        iconSize: 15
                        color: Appearance.colors.colSubtext
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: modelData.title
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer1
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        implicitWidth: 52
                        implicitHeight: 22
                        radius: 11
                        color: ColorUtils.transparentize(root.riskColor(modelData.risk), 0.82)
                        border.width: 1
                        border.color: ColorUtils.transparentize(root.riskColor(modelData.risk), 0.58)

                        StyledText {
                            anchors.centerIn: parent
                            text: modelData.risk.toUpperCase()
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            color: root.riskColor(modelData.risk)
                        }
                    }

                    MaterialSymbol {
                        text: modelData.reversible ? "undo" : "lock"
                        iconSize: 14
                        color: modelData.reversible ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                    }
                }
            }
        }

        StyledText {
            visible: root.events.length === 0
            Layout.fillWidth: true
            text: "No activity events yet"
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colSubtext
            horizontalAlignment: Text.AlignHCenter
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        RippleButton {
            Layout.fillWidth: true
            implicitHeight: 34
            buttonRadius: 10
            colBackground: Qt.rgba(1, 1, 1, 0.04)
            colBackgroundHover: Qt.rgba(1, 1, 1, 0.08)
            onClicked: Quickshell.execDetached(["kitty", "--hold", "-e", "tail", "-n", "120", Quickshell.env("HOME") + "/.local/state/inir/activity-feed.jsonl"])

            contentItem: StyledText {
                anchors.centerIn: parent
                text: "Open Feed"
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer1
            }
        }

        RippleButton {
            Layout.fillWidth: true
            implicitHeight: 34
            buttonRadius: 10
            colBackground: Qt.rgba(1, 0.35, 0.35, 0.14)
            colBackgroundHover: Qt.rgba(1, 0.35, 0.35, 0.22)
            onClicked: Quickshell.execDetached(["kitty", "--hold", "-e", "bash", "-lc", "cd ~/Github/inir && git status --short && echo && git log --oneline -n 8"])

            contentItem: StyledText {
                anchors.centerIn: parent
                text: "Revert Path"
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colError
            }
        }
    }
}