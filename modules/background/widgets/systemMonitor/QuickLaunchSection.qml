import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

GridLayout {
    id: root

    property var configEntry: ({})

    readonly property var defaultApps: [
        { icon: "language", label: "Browser", cmd: "xdg-open https://" },
        { icon: "folder", label: "Files", cmd: "xdg-open ~" },
        { icon: "terminal", label: "Terminal", cmd: "kitty" },
        { icon: "settings", label: "Settings", cmd: "" },
    ]

    readonly property var apps: {
        const custom = root.configEntry.quickLaunchApps
        if (custom && custom.length > 0) {
            try {
                return JSON.parse(custom)
            } catch (e) {
                return root.defaultApps
            }
        }
        return root.defaultApps
    }

    columns: Math.min(apps.length, 4)
    rowSpacing: 8
    columnSpacing: 8

    Repeater {
        model: root.apps

        RippleButton {
            id: launchBtn
            required property var modelData
            required property int index

            Layout.preferredWidth: 48
            Layout.preferredHeight: 48
            buttonRadius: Appearance.rounding.small

            colBackground: ColorUtils.transparentize(Appearance.colors.colSurfaceContainer, 0.4)
            colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colSurfaceContainer, 0.15)

            onClicked: {
                if (modelData.cmd && modelData.cmd !== "")
                    Quickshell.execDetached(["/usr/bin/bash", "-lc", modelData.cmd])
            }

            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                text: launchBtn.modelData.icon ?? "apps"
                iconSize: 24
                color: index === 0 ? Appearance.colors.colPrimary
                     : index === 1 ? Appearance.colors.colSecondary
                     : index === 2 ? Appearance.colors.colTertiary
                     : Appearance.colors.colOnLayer0
            }

            StyledToolTip {
                text: launchBtn.modelData.label ?? ""
            }
        }
    }
}
