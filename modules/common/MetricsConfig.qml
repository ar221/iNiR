pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Dedicated config file for metrics scale factors.
 * Separate from Config.qml to avoid JsonAdapter deserialization crashes
 * when nested metric objects are written to config.json.
 *
 * File: ~/.config/illogical-impulse/metrics.json
 */
Singleton {
    id: root

    property alias options: metricsJsonAdapter
    property bool ready: false
    property int readWriteDelay: 50

    signal metricsChanged()

    function flushWrites(): void {
        fileWriteTimer.stop()
        metricsFileView.writeAdapter()
    }

    Timer {
        id: fileReloadTimer
        interval: root.readWriteDelay
        repeat: false
        onTriggered: {
            metricsFileView.reload()
            root.metricsChanged()
        }
    }

    Timer {
        id: fileWriteTimer
        interval: root.readWriteDelay
        repeat: false
        onTriggered: metricsFileView.writeAdapter()
    }

    FileView {
        id: metricsFileView
        path: Directories.metricsConfigPath
        watchChanges: true
        onFileChanged: fileReloadTimer.restart()
        onAdapterUpdated: fileWriteTimer.restart()
        onLoaded: {
            root.ready = true
            root.metricsChanged()
        }
        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {
                console.log("[MetricsConfig] File not found, creating with defaults.")
                writeAdapter()
            }
            root.ready = true
        }

        JsonAdapter {
            id: metricsJsonAdapter

            property real spacingScale: 1.0
            property real roundingScale: 1.0
            property real fontScale: 1.0
            property real durationScale: 1.0
        }
    }
}
