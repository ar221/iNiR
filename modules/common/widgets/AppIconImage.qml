import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.services

// Shared dock/bar app-icon resolver. Waterfall:
//   1. Absolute path (smartIconName / Papirus overrides) → file:// direct.
//   2. IconThemeService.dockIconCandidates(name) → walk on Image.Error.
//   3. Exhausted → Quickshell.iconPath(name, fallback) via system theme.
// Consumers compute `iconName` themselves (desktop-entry lookup, smartIconName,
// per-app overrides) — this component only owns the candidate walker + retry.
// Lifted from CourierRail.qml + BarTaskbarButton.qml (b9cd8b8b followup).
IconImage {
    id: root

    required property string iconName
    // Fallback icon name passed to Quickshell.iconPath when candidates are
    // exhausted. Dock uses "application-x-executable", bar uses "image-missing".
    property string systemFallbackIcon: "application-x-executable"

    readonly property bool isAbsolutePath: iconName.startsWith("/") || iconName.startsWith("file://")
    property var candidates: isAbsolutePath ? [] : IconThemeService.dockIconCandidates(iconName)

    property int _candidateIdx: 0
    property bool _useSystemFallback: false
    property string _systemFallbackName: ""

    mipmap: true
    smooth: true

    onIconNameChanged: {
        _candidateIdx = 0
        _useSystemFallback = false
        _systemFallbackName = ""
    }

    source: {
        if (_useSystemFallback && _systemFallbackName)
            return Quickshell.iconPath(_systemFallbackName, systemFallbackIcon)
        if (isAbsolutePath)
            return iconName.startsWith("file://") ? iconName : `file://${iconName}`
        if (candidates.length > 0 && _candidateIdx < candidates.length)
            return candidates[_candidateIdx]
        return Quickshell.iconPath(iconName, systemFallbackIcon)
    }

    onStatusChanged: {
        if (status === Image.Error) {
            Qt.callLater(() => {
                if (isAbsolutePath && !_useSystemFallback) {
                    const path = iconName.startsWith("file://") ? iconName.substring(7) : iconName
                    const fileName = path.split("/").pop()
                    let baseName = fileName
                    if (baseName.includes(".")) baseName = baseName.split(".").slice(0, -1).join(".")
                    _systemFallbackName = baseName
                    _useSystemFallback = true
                    return
                }
                if (candidates.length > 0 && _candidateIdx < candidates.length - 1) {
                    _candidateIdx++
                } else if (!_useSystemFallback) {
                    _systemFallbackName = iconName
                    _useSystemFallback = true
                }
            })
        }
    }
}
