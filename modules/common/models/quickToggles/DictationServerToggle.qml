import QtQuick
import qs.services
import qs.modules.common

QuickToggleModel {
    name: "Dictation"
    toggled: DictationServer.active
    icon: "mic"
    statusText: DictationServer.active ? "Running on :" + DictationServer.port : "Stopped"
    hasStatusText: true
    mainAction: () => DictationServer.toggle()
    tooltipText: "Dictation Server (:8384)"
}
