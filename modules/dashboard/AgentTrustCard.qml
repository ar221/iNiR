import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

DashboardCard {
    id: root

    headerText: "Trust Policy"

    readonly property string mode: {
        const value = String(Config.options?.dashboard?.agentTrust?.mode ?? "balanced").toLowerCase()
        return (value === "strict" || value === "open") ? value : "balanced"
    }

    readonly property bool allowSafeInBalanced: Config.options?.dashboard?.agentTrust?.allowSafeInBalanced ?? true

    readonly property string summary: {
        if (root.mode === "strict")
            return "Strict · Manual approval for command tool calls"
        if (root.mode === "open")
            return "Open · Auto-approves command tool calls"
        return root.allowSafeInBalanced
            ? "Balanced · Auto-approves configured safe prefixes"
            : "Balanced · Manual unless toggled"
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 34
        radius: 9
        color: Qt.rgba(1, 1, 1, 0.03)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            MaterialSymbol {
                text: root.mode === "open" ? "lock_open" : (root.mode === "strict" ? "lock" : "verified_user")
                iconSize: 16
                color: root.mode === "open" ? Appearance.colors.colWarn : Appearance.colors.colPrimary
            }

            StyledText {
                Layout.fillWidth: true
                text: root.summary
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer1
                elide: Text.ElideRight
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Repeater {
            model: [
                { key: "strict", label: "Strict", icon: "gpp_bad" },
                { key: "balanced", label: "Balanced", icon: "gpp_maybe" },
                { key: "open", label: "Open", icon: "gpp_good" }
            ]

            RippleButton {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 34
                buttonRadius: 9
                colBackground: root.mode === modelData.key
                    ? ColorUtils.transparentize(Appearance.colors.colPrimary, 0.78)
                    : Qt.rgba(1, 1, 1, 0.03)
                colBackgroundHover: root.mode === modelData.key
                    ? ColorUtils.transparentize(Appearance.colors.colPrimary, 0.65)
                    : Qt.rgba(1, 1, 1, 0.08)
                onClicked: Config.setNestedValue("dashboard.agentTrust.mode", modelData.key)

                contentItem: RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 4

                    MaterialSymbol {
                        text: parent.parent.modelData.icon
                        iconSize: 14
                        color: root.mode === parent.parent.modelData.key
                            ? Appearance.colors.colOnLayer0
                            : Appearance.colors.colSubtext
                    }

                    StyledText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: parent.parent.modelData.label
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        color: root.mode === parent.parent.modelData.key
                            ? Appearance.colors.colOnLayer0
                            : Appearance.colors.colOnLayer1
                    }
                }
            }
        }
    }

    SettingsSwitch {
        buttonIcon: "rule_settings"
        text: "Auto-approve safe commands in Balanced"
        checked: root.allowSafeInBalanced
        enabled: root.mode === "balanced"
        onCheckedChanged: Config.setNestedValue("dashboard.agentTrust.allowSafeInBalanced", checked)
    }

    StyledText {
        Layout.fillWidth: true
        text: `Safe prefixes: ${(Config.options?.dashboard?.agentTrust?.safeCommandPrefixes ?? []).slice(0, 4).join(", ")}${(Config.options?.dashboard?.agentTrust?.safeCommandPrefixes ?? []).length > 4 ? "…" : ""}`
        font.pixelSize: Appearance.font.pixelSize.smallest
        color: Appearance.colors.colSubtext
        wrapMode: Text.Wrap
    }
}
