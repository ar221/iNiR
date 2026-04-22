import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

DashboardCard {
    id: root

    headerText: "Mobile Companion"

    property string snapshotPath: Quickshell.env("HOME") + "/.local/state/inir/agent-companion.json"
    property string handoffPath: Quickshell.env("HOME") + "/.local/state/inir/hermes-telegram-handoff.jsonl"
    property string lastExportStatus: "Not exported yet"
    property string lastHandoffStatus: "Not sent yet"

    readonly property string runState: Ai.waitingForApproval
        ? "Awaiting approval"
        : (Ai.requestRunning ? "Request in flight" : "Idle")
    readonly property bool compactPayload: Config.options?.dashboard?.agentCockpit?.mobilePayloadCompact ?? true

    function actionHints() {
        const hints = []
        if (Ai.waitingForApproval)
            hints.push("approve_or_deny_tool_call")
        if (Ai.requestRunning)
            hints.push("interrupt_request_if_needed")
        if (ClaudeCodeProxy.active || GptProxy.active)
            hints.push("stop_proxy_if_stuck")
        if (hints.length === 0)
            hints.push("ready_for_next_prompt")
        return hints
    }

    function snapshotPayload() {
        const nowIso = new Date().toISOString()
        const modelId = String(Ai.currentModelId ?? "")
        const provider = String(Ai.providerLabel ?? "unknown")
        const trustMode = String(Config.options?.dashboard?.agentTrust?.mode ?? "balanced")
        const hints = root.actionHints()

        if (root.compactPayload) {
            return JSON.stringify({
                schema: "inir.agent-companion.compact.v1",
                timestamp: nowIso,
                status: root.runState,
                route: `${modelId} · ${provider}`,
                trustMode: trustMode,
                pendingApproval: !!Ai.waitingForApproval,
                running: !!Ai.requestRunning,
                proxies: `claude:${ClaudeCodeProxy.active ? "on" : "off"},gpt:${GptProxy.active ? "on" : "off"}`,
                nextActions: hints,
                summary: `State=${root.runState}; Route=${modelId}; Trust=${trustMode}; Proxies C:${ClaudeCodeProxy.active ? "ON" : "OFF"}/G:${GptProxy.active ? "ON" : "OFF"}`
            })
        }

        return JSON.stringify({
            schema: "inir.agent-companion.full.v1",
            timestamp: nowIso,
            modelId: modelId,
            provider: provider,
            requestRunning: !!Ai.requestRunning,
            waitingForApproval: !!Ai.waitingForApproval,
            claudeProxyActive: !!ClaudeCodeProxy.active,
            gptProxyActive: !!GptProxy.active,
            trustMode: trustMode,
            actionHints: hints
        })
    }

    Process {
        id: exportProc
        property bool hadError: false
        command: []
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                if (data.trim().length > 0)
                    root.lastExportStatus = data.trim()
            }
        }
        stderr: SplitParser {
            splitMarker: ""
            onRead: data => {
                if (data.trim().length > 0)
                    root.lastExportStatus = `Export failed: ${data.trim()}`
                exportProc.hadError = true
            }
        }
        onExited: exitCode => {
            if (!exportProc.hadError && exitCode === 0)
                root.lastExportStatus = `Exported · ${new Date().toLocaleTimeString()}`
            exportProc.hadError = false
        }
    }

    Process {
        id: handoffProc
        property bool hadError: false
        command: []
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                if (data.trim().length > 0)
                    root.lastHandoffStatus = data.trim()
            }
        }
        stderr: SplitParser {
            splitMarker: ""
            onRead: data => {
                if (data.trim().length > 0)
                    root.lastHandoffStatus = `Send failed: ${data.trim()}`
                handoffProc.hadError = true
            }
        }
        onExited: exitCode => {
            if (!handoffProc.hadError && exitCode === 0)
                root.lastHandoffStatus = `Queued for Hermes · ${new Date().toLocaleTimeString()}`
            handoffProc.hadError = false
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 92
        radius: 10
        color: Qt.rgba(1, 1, 1, 0.03)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 4

            StyledText {
                Layout.fillWidth: true
                text: `State: ${root.runState}`
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer1
            }

            StyledText {
                Layout.fillWidth: true
                text: `Route: ${Ai.currentModelId ?? "n/a"} · ${Ai.providerLabel ?? "unknown"}`
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colSubtext
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: `Payload: ${root.compactPayload ? "compact.telegram.v1" : "full.v1"}`
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colSubtext
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: `Proxies: Claude ${ClaudeCodeProxy.active ? "ON" : "OFF"} · GPT ${GptProxy.active ? "ON" : "OFF"}`
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colSubtext
                elide: Text.ElideRight
            }
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
            enabled: !exportProc.running
            onClicked: {
                exportProc.hadError = false
                exportProc.command = [
                    "/usr/bin/python3",
                    "-c",
                    "import json, os, pathlib, sys; p=pathlib.Path(os.path.expanduser('~/.local/state/inir/agent-companion.json')); p.parent.mkdir(parents=True, exist_ok=True); p.write_text(sys.argv[1]); print(str(p))",
                    root.snapshotPayload()
                ]
                exportProc.running = true
            }

            contentItem: StyledText {
                anchors.centerIn: parent
                text: exportProc.running ? "Exporting…" : "Export Snapshot"
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer1
            }
        }

        RippleButton {
            Layout.fillWidth: true
            implicitHeight: 34
            buttonRadius: 10
            colBackground: Qt.rgba(1, 1, 1, 0.04)
            colBackgroundHover: Qt.rgba(1, 1, 1, 0.08)
            onClicked: Quickshell.execDetached(["kitty", "--hold", "-e", "bash", "-lc", `test -f ${root.snapshotPath} && cat ${root.snapshotPath} || echo 'No snapshot yet'`])

            contentItem: StyledText {
                anchors.centerIn: parent
                text: "Open Snapshot"
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer1
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        RippleButton {
            Layout.fillWidth: true
            implicitHeight: 34
            buttonRadius: 10
            colBackground: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.82)
            colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.7)
            enabled: !handoffProc.running
            onClicked: {
                handoffProc.hadError = false
                handoffProc.command = [
                    "/usr/bin/python3",
                    "-c",
                    "import datetime, json, os, pathlib, sys; p=pathlib.Path(os.path.expanduser('~/.local/state/inir/hermes-telegram-handoff.jsonl')); p.parent.mkdir(parents=True, exist_ok=True); payload=json.loads(sys.argv[1]); entry={'timestamp': datetime.datetime.now().isoformat(), 'source': 'inir-agent-companion', 'target': 'telegram:@ayaz_hermes_bot', 'payload': payload}; f=p.open('a', encoding='utf-8'); f.write(json.dumps(entry, ensure_ascii=False)+'\\n'); f.close(); print(str(p))",
                    root.snapshotPayload()
                ]
                handoffProc.running = true
            }

            contentItem: StyledText {
                anchors.centerIn: parent
                text: handoffProc.running ? "Sending…" : "Send to Hermes Now"
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer0
            }
        }

        RippleButton {
            Layout.fillWidth: true
            implicitHeight: 34
            buttonRadius: 10
            colBackground: Qt.rgba(1, 1, 1, 0.04)
            colBackgroundHover: Qt.rgba(1, 1, 1, 0.08)
            onClicked: Quickshell.execDetached(["kitty", "--hold", "-e", "bash", "-lc", `test -f ${root.handoffPath} && tail -n 20 ${root.handoffPath} || echo 'No handoffs yet'`])

            contentItem: StyledText {
                anchors.centerIn: parent
                text: "Open Hermes Queue"
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer1
            }
        }
    }

    StyledText {
        Layout.fillWidth: true
        text: root.lastExportStatus
        font.pixelSize: Appearance.font.pixelSize.smallest
        color: Appearance.colors.colSubtext
        elide: Text.ElideRight
    }

    StyledText {
        Layout.fillWidth: true
        text: root.lastHandoffStatus
        font.pixelSize: Appearance.font.pixelSize.smallest
        color: Appearance.colors.colSubtext
        elide: Text.ElideRight
    }
}
