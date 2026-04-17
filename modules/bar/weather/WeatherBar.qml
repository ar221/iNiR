pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services
import Quickshell
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property bool hovered: false
    implicitWidth: rowLayout.implicitWidth + 10 * 2
    implicitHeight: Appearance.sizes.barHeight

    hoverEnabled: true

    /**
     * Maps a weather temperature to a heat-encoded color.
     * Only applies on the Material You path (else branch). Angel/inir themes stay flat.
     *
     * Scale (°C): ≤0 → cold (colTertiary), 20 → neutral (colOnLayer1), ≥30 → warm (colPrimary)
     * Scale (°F): ≤32 → cold (colTertiary), 68 → neutral (colOnLayer1), ≥86 → warm (colPrimary)
     *
     * colTertiary carries the "cool" role in Material You palettes (often blue/cyan).
     * colPrimary carries the "accent" role — warm on most wallpapers.
     */
    function weatherTempColor(): color {
        const tempStr = Weather.data?.temp ?? ""
        const numeric = parseFloat(tempStr)
        if (isNaN(numeric)) return Appearance.colors.colOnLayer1

        const usUSCS = Weather.useUSCS ?? false
        const coldStop    = usUSCS ? 32  : 0
        const neutralStop = usUSCS ? 68  : 20
        const warmStop    = usUSCS ? 86  : 30

        const coldColor    = Appearance.colors.colTertiary
        const neutralColor = Appearance.colors.colOnLayer1
        const warmColor    = Appearance.colors.colPrimary

        if (numeric <= coldStop)
            return coldColor
        if (numeric >= warmStop)
            return warmColor

        if (numeric <= neutralStop) {
            // cold..neutral: t=0 at cold, t=1 at neutral
            const t = (numeric - coldStop) / (neutralStop - coldStop)
            return ColorUtils.mix(neutralColor, coldColor, t)
        } else {
            // neutral..warm: t=0 at neutral, t=1 at warm
            const t = (numeric - neutralStop) / (warmStop - neutralStop)
            return ColorUtils.mix(warmColor, neutralColor, 1.0 - t)
        }
    }

    onPressed: {
        Weather.getData();
        Quickshell.execDetached(["/usr/bin/notify-send",
            Translation.tr("Weather"),
            Translation.tr("Refreshing (manually triggered)")
            , "-a", "Shell"
        ])
    }

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent

        MaterialSymbol {
            fill: 0
            text: Icons.getWeatherIcon(Weather.data?.wCode, Weather.isNightNow()) ?? "cloud"
            iconSize: Appearance.font.pixelSize.large
            color: Appearance.angelEverywhere ? Appearance.angel.colText
                : Appearance.inirEverywhere ? Appearance.inir.colText : Appearance.colors.colOnLayer1
            Layout.alignment: Qt.AlignVCenter
        }

        StyledText {
            visible: true
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.angelEverywhere ? Appearance.angel.colText
                : Appearance.inirEverywhere ? Appearance.inir.colText : root.weatherTempColor()
            text: Weather.data?.temp ?? "--°"
            Layout.alignment: Qt.AlignVCenter

            Behavior on color {
                enabled: Appearance.animationsEnabled
                animation: ColorAnimation {
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Appearance.animation.elementMoveFast.type
                }
            }
        }
    }

    WeatherPopup {
        id: weatherPopup
        hoverTarget: root
    }
}
