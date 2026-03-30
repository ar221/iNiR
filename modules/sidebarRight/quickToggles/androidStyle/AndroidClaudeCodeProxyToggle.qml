import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import qs.services

AndroidQuickToggleButton {
    id: root

    name: "Claude Proxy"
    statusText: ClaudeCodeProxy.active ? "Running on :42069" : "Stopped"
    toggled: ClaudeCodeProxy.active
    buttonIcon: "dns"

    mainAction: () => {
        ClaudeCodeProxy.toggle()
    }

    StyledToolTip {
        text: ClaudeCodeProxy.active
            ? "Claude Code Proxy (active)"
            : "Claude Code Proxy (stopped)"
    }
}
