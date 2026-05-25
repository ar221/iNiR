import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

ColumnLayout {
    id: root

    property var configEntry: ({})
    readonly property bool hasWeather: Weather.readyForDisplay

    visible: hasWeather
    spacing: 4
    Layout.alignment: Qt.AlignHCenter

    // Icon + temperature on one line, centered
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 6

        MaterialSymbol {
            text: Icons.getWeatherIcon(Weather.data?.wCode, Weather.isNightNow()) ?? "cloud"
            iconSize: 32
            color: Appearance.mission.colAccent
        }

        StyledText {
            text: Weather.data?.temp ?? "--°C"
            font.pixelSize: Appearance.font.pixelSize.huge
            font.weight: Font.Medium
            font.family: Appearance.font.family.numbers
            color: Appearance.mission.colText
        }
    }

    // Description centered below
    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: Weather.data?.description ?? ""
        font.pixelSize: Appearance.font.pixelSize.small
        color: Appearance.mission.colText
        visible: text !== ""
    }

    // Detail line: feels-like, humidity, wind
    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: {
            const parts = []
            if (Weather.data?.feelsLike)
                parts.push("Feels " + Weather.data.feelsLike)
            if (Weather.data?.humidity)
                parts.push(Weather.data.humidity + " humidity")
            if (Weather.data?.wind)
                parts.push(Weather.data.wind + (Weather.data?.windDir ? " " + Weather.data.windDir : ""))
            return parts.join("  ·  ")
        }
        font.pixelSize: Appearance.font.pixelSize.smallest
        color: Appearance.mission.colTextSecondary
        visible: text !== ""
    }
}
