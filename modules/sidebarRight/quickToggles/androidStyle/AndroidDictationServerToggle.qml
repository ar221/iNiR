import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import qs.services

AndroidQuickToggleButton {
    id: root

    name: "Dictation"
    statusText: DictationServer.active ? "Running on :8384" : "Stopped"
    toggled: DictationServer.active
    buttonIcon: "mic"

    mainAction: () => {
        DictationServer.toggle()
    }

    StyledToolTip {
        text: DictationServer.active
            ? "Dictation Server (active)"
            : "Dictation Server (stopped)"
    }
}
