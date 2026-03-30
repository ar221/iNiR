import QtQuick
import qs.services
import qs.modules.common

QuickToggleModel {
    name: "Claude Proxy"
    toggled: ClaudeCodeProxy.active
    icon: "dns"
    statusText: ClaudeCodeProxy.active ? "Running on :" + ClaudeCodeProxy.port : "Stopped"
    hasStatusText: true
    mainAction: () => ClaudeCodeProxy.toggle()
    tooltipText: "Claude Code Proxy (:42069)"
}
