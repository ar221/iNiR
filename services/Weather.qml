pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

import qs.modules.common

Singleton {
    id: root

    readonly property bool enabled: Config.options?.bar?.weather?.enable ?? false
    readonly property int fetchInterval: (Config.options?.bar?.weather?.fetchInterval ?? 10) * 60 * 1000
    readonly property bool useUSCS: Config.options?.bar?.weather?.useUSCS ?? false
    readonly property bool hideLocation: Config.options?.waffles?.widgetsPanel?.weatherHideLocation ?? false

    // Manual location config
    readonly property string configCity: Config.options?.bar?.weather?.city ?? ""
    readonly property real configLat: Config.options?.bar?.weather?.manualLat ?? 0
    readonly property real configLon: Config.options?.bar?.weather?.manualLon ?? 0
    readonly property bool enableGPS: Config.options?.bar?.weather?.enableGPS ?? false
    readonly property bool hasManualCoords: configLat !== 0 || configLon !== 0
    readonly property bool hasManualCity: configCity.length > 0

    property int _requestCount: 0
    property bool _forceMode: false
    property bool _locationDirty: false
    readonly property bool active: root.enabled && Config.ready && root._requestCount > 0
    readonly property bool hasData: {
        const temp = String(root.data?.temp ?? "")
        return temp.length > 0 && !temp.startsWith("--")
    }
    readonly property bool readyForDisplay: root.hasData

    function _canRun(force: bool = false): bool {
        return root.enabled && Config.ready && (force || root.active || root._forceMode)
    }

    function ensureInitialized(): void {
        if (root._initialized)
            return
        root._initialized = true
        root._retryCount = 0
        root._lastCity = root.configCity
        root._lastLat = root.configLat
        root._lastLon = root.configLon
    }

    function _clearForceModeIfIdle(): void {
        if (root.active)
            return
        if (retryTimer.running || pendingForceRefreshTimer.running || locationDebounceTimer.running)
            return
        if (!root.hasRunningRequests())
            root._forceMode = false
    }

    function acquire(): void {
        root._requestCount = Math.max(0, root._requestCount + 1)
    }

    function release(): void {
        if (root._requestCount > 0)
            root._requestCount -= 1
    }

    function ensureRunning(): void {
        if (root._requestCount <= 0)
            root._requestCount = 1
    }

    function stop(force: bool = false): void {
        if (!force && root._requestCount > 0)
            return
        root._requestCount = 0
        retryTimer.stop()
        pendingForceRefreshTimer.stop()
        locationDebounceTimer.stop()
        fetchTimer.stop()
        if (force)
            root._forceMode = false
    }

    function _activate(): void {
        root.ensureInitialized()
        if (root.hasRunningRequests())
            return
        if (root._locationDirty) {
            root._locationDirty = false
            root.location = { valid: false, lat: 0, lon: 0, name: "" }
        }
        root.getData(true)
        root.fetchForecast(true)
    }

    function _deactivate(): void {
        retryTimer.stop()
        pendingForceRefreshTimer.stop()
        locationDebounceTimer.stop()
        fetchTimer.stop()
        root._clearForceModeIfIdle()
    }

    property var location: ({ valid: false, lat: 0, lon: 0, name: "" })

    property var data: ({
        uv: "0",
        humidity: "0%",
        sunrise: "--:--",
        sunset: "--:--",
        windDir: "N",
        wCode: "113",
        description: "",
        city: "City",
        wind: "0 km/h",
        precip: "0 mm",
        visib: "10 km",
        press: "1013 hPa",
        temp: "--°C",
        tempFeelsLike: "--°C"
    })

    // Hourly strip: next 12 hours
    // Each entry: { time: "3pm", hour: 15, temp: "21°C", tempRaw: 21, wCode: "113", isDay: true, precipChance: 10 }
    property var hourly: []

    // 7-day forecast
    // Each entry: { date: "2026-04-16", day: "Today"|"Mon", tempMaxRaw: 25, tempMax: "25°C",
    //               tempMinRaw: 14, tempMin: "14°C", wCode: "113", precipChance: 20, sunrise: "06:12", sunset: "19:44" }
    property var daily: []
    readonly property string visibleCity: {
        if (root.hideLocation)
            return ""
        const city = String(root.data?.city ?? "")
        if (city.length > 0 && city.toLowerCase() !== "unknown")
            return city
        return ""
    }
    readonly property bool showVisibleCity: root.visibleCity.length > 0

    function redactedLogCity(city): string {
        if (root.hideLocation)
            return "[hidden]"

        const value = String(city ?? "").trim()
        return value.length > 0 ? value : "Unknown"
    }

    function redactedLogLocationName(name): string {
        if (root.hideLocation)
            return "[hidden]"

        const value = String(name ?? "").trim()
        return value.length > 0 ? value : "Unknown"
    }

    function redactedLogCoordinates(lat, lon): string {
        if (root.hideLocation)
            return "[hidden]"

        const latNum = Number(lat)
        const lonNum = Number(lon)
        if (!isFinite(latNum) || !isFinite(lonNum))
            return "Unknown"
        return latNum.toFixed(5) + "," + lonNum.toFixed(5)
    }

    function isNightNow(): bool {
        const h = new Date().getHours();
        return h < 6 || h >= 18;
    }

    function describeWeather(code): string {
        const weatherCode = String(code ?? "113")
        const descriptions = {
            "113": Translation.tr("Sunny"),
            "116": Translation.tr("Partly cloudy"),
            "119": Translation.tr("Cloudy"),
            "122": Translation.tr("Overcast"),
            "143": Translation.tr("Mist"),
            "176": Translation.tr("Light rain"),
            "179": Translation.tr("Light sleet"),
            "182": Translation.tr("Light sleet"),
            "185": Translation.tr("Light sleet"),
            "200": Translation.tr("Thunderstorm"),
            "227": Translation.tr("Light snow"),
            "230": Translation.tr("Heavy snow"),
            "248": Translation.tr("Fog"),
            "260": Translation.tr("Fog"),
            "263": Translation.tr("Light drizzle"),
            "266": Translation.tr("Light drizzle"),
            "281": Translation.tr("Freezing drizzle"),
            "284": Translation.tr("Freezing drizzle"),
            "293": Translation.tr("Light rain"),
            "296": Translation.tr("Light rain"),
            "299": Translation.tr("Moderate rain"),
            "302": Translation.tr("Heavy rain"),
            "305": Translation.tr("Heavy rain"),
            "308": Translation.tr("Heavy rain"),
            "311": Translation.tr("Freezing rain"),
            "314": Translation.tr("Freezing rain"),
            "317": Translation.tr("Sleet"),
            "320": Translation.tr("Light snow"),
            "323": Translation.tr("Light snow"),
            "326": Translation.tr("Light snow"),
            "329": Translation.tr("Moderate snow"),
            "332": Translation.tr("Moderate snow"),
            "335": Translation.tr("Heavy snow"),
            "338": Translation.tr("Heavy snow"),
            "350": Translation.tr("Ice pellets"),
            "353": Translation.tr("Light showers"),
            "356": Translation.tr("Moderate showers"),
            "359": Translation.tr("Heavy showers"),
            "362": Translation.tr("Sleet showers"),
            "365": Translation.tr("Sleet showers"),
            "368": Translation.tr("Snow showers"),
            "371": Translation.tr("Snow showers"),
            "374": Translation.tr("Ice pellets"),
            "377": Translation.tr("Ice pellets"),
            "386": Translation.tr("Thunderstorm"),
            "389": Translation.tr("Thunderstorm"),
            "392": Translation.tr("Thunderstorm"),
            "395": Translation.tr("Snow storm")
        }
        return descriptions[weatherCode] ?? Translation.tr("Unknown")
    }

    function refineData(apiData) {
        if (!apiData?.current) return;
        
        const current = apiData.current;
        const astro = apiData.astronomy;
        
        let result = {};
        result.uv = current.uvIndex ?? "0";
        result.humidity = (current.humidity ?? 0) + "%";
        result.sunrise = astro?.sunrise ?? "--:--";
        result.sunset = astro?.sunset ?? "--:--";
        result.windDir = current.winddir16Point ?? "N";
        result.wCode = current.weatherCode ?? "113";
        result.description = root.describeWeather(result.wCode);
        result.city = root.location.name || "Unknown";

        if (root.useUSCS) {
            result.temp = (current.temp_F ?? 0) + "°F";
            result.tempFeelsLike = (current.FeelsLikeF ?? 0) + "°F";
            result.wind = (current.windspeedMiles ?? 0) + " mph";
            result.precip = (current.precipInches ?? 0) + " in";
            result.visib = (current.visibilityMiles ?? 0) + " mi";
            result.press = (current.pressureInches ?? 0) + " inHg";
        } else {
            result.temp = (current.temp_C ?? 0) + "°C";
            result.tempFeelsLike = (current.FeelsLikeC ?? 0) + "°C";
            result.wind = (current.windspeedKmph ?? 0) + " km/h";
            result.precip = (current.precipMM ?? 0) + " mm";
            result.visib = (current.visibility ?? 0) + " km";
            result.press = (current.pressure ?? 0) + " hPa";
        }

        root.data = result;
        console.info("[Weather] Updated:", result.temp, root.redactedLogCity(result.city));
    }

    function _degToCompass(deg): string {
        if (deg === undefined || deg === null || isNaN(deg)) return "N"
        const dirs = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        const idx = Math.round(((deg % 360) / 22.5)) % 16
        return dirs[idx]
    }

    // Translate WMO weather codes (0-99, used by Open-Meteo) to wttr.in codes (113-395)
    // so that Icons.getWeatherIcon() and describeWeather() work correctly.
    function _wmoToWttr(wmo): string {
        const code = Number(wmo ?? 0)
        if (code === 0)              return "113"  // Clear sky
        if (code === 1 || code === 2) return "116" // Mainly clear / partly cloudy
        if (code === 3)              return "119"  // Overcast
        if (code === 45 || code === 48) return "143" // Fog / rime fog
        if (code === 51)             return "263"  // Light drizzle
        if (code === 53)             return "266"  // Moderate drizzle
        if (code === 55)             return "266"  // Dense drizzle
        if (code === 56 || code === 57) return "281" // Freezing drizzle
        if (code === 61)             return "293"  // Light rain
        if (code === 63)             return "299"  // Moderate rain
        if (code === 65)             return "302"  // Heavy rain
        if (code === 66 || code === 67) return "311" // Freezing rain
        if (code === 71)             return "320"  // Light snow
        if (code === 73)             return "329"  // Moderate snow
        if (code === 75)             return "335"  // Heavy snow
        if (code === 77)             return "374"  // Snow grains → ice pellets
        if (code === 80)             return "353"  // Light showers
        if (code === 81)             return "356"  // Moderate showers
        if (code === 82)             return "359"  // Heavy showers
        if (code === 85)             return "368"  // Light snow showers
        if (code === 86)             return "371"  // Heavy snow showers
        if (code === 95)             return "200"  // Thunderstorm
        if (code === 96 || code === 99) return "386" // Thunderstorm + hail
        return "113"  // Fallback: clear
    }

    // Translate hour 0-23 to "12am"/"1pm" style label
    function _hourLabel(h): string {
        if (h === 0)  return "12am"
        if (h < 12)  return h + "am"
        if (h === 12) return "12pm"
        return (h - 12) + "pm"
    }

    // Translate YYYY-MM-DD date string to "Today" (index 0) or short day abbreviation
    function _dayLabel(dateStr, index): string {
        if (index === 0) return "Today"
        const d = new Date(dateStr + "T12:00:00")  // noon to avoid DST edge
        return ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"][d.getDay()]
    }

    function refineForecastData(apiData): void {
        const hourlyRaw = apiData?.hourly
        const dailyRaw = apiData?.daily
        const units = apiData?.hourly_units ?? {}
        const tempSuffix = root.useUSCS ? "°F" : "°C"

        // Build hourly strip — next 12 hours from now
        if (hourlyRaw?.time) {
            const nowH = new Date()
            nowH.setMinutes(0, 0, 0)
            const nowTs = nowH.getTime()

            let hourlyResult = []
            const times = hourlyRaw.time
            const temps = hourlyRaw.temperature_2m
            const codes = hourlyRaw.weather_code
            const isDay = hourlyRaw.is_day
            const precip = hourlyRaw.precipitation_probability

            for (let i = 0; i < times.length && hourlyResult.length < 12; i++) {
                // Open-Meteo returns "YYYY-MM-DDTHH:00" local time (timezone=auto)
                const entryTs = new Date(times[i]).getTime()
                if (entryTs < nowTs) continue

                const hour = new Date(times[i]).getHours()
                const tempRaw = Math.round(temps?.[i] ?? 0)
                const wmo = codes?.[i] ?? 0
                hourlyResult.push({
                    time: root._hourLabel(hour),
                    hour: hour,
                    temp: tempRaw + tempSuffix,
                    tempRaw: tempRaw,
                    wCode: root._wmoToWttr(wmo),
                    isDay: (isDay?.[i] ?? 1) === 1,
                    precipChance: precip?.[i] ?? 0
                })
            }
            root.hourly = hourlyResult
        }

        // Build 7-day row
        if (dailyRaw?.time) {
            const times7 = dailyRaw.time
            const maxTemps = dailyRaw.temperature_2m_max
            const minTemps = dailyRaw.temperature_2m_min
            const codes7 = dailyRaw.weather_code
            const precipMax = dailyRaw.precipitation_probability_max
            const sunrises = dailyRaw.sunrise
            const sunsets = dailyRaw.sunset

            let dailyResult = []
            for (let j = 0; j < Math.min(times7.length, 7); j++) {
                const maxRaw = Math.round(maxTemps?.[j] ?? 0)
                const minRaw = Math.round(minTemps?.[j] ?? 0)
                const wmo7 = codes7?.[j] ?? 0
                const riseStr = sunrises?.[j] ?? ""
                const setStr = sunsets?.[j] ?? ""
                dailyResult.push({
                    date: times7[j],
                    day: root._dayLabel(times7[j], j),
                    tempMaxRaw: maxRaw,
                    tempMax: maxRaw + tempSuffix,
                    tempMinRaw: minRaw,
                    tempMin: minRaw + tempSuffix,
                    wCode: root._wmoToWttr(wmo7),
                    precipChance: precipMax?.[j] ?? 0,
                    sunrise: riseStr ? riseStr.split("T")[1] ?? riseStr : "--:--",
                    sunset: setStr ? setStr.split("T")[1] ?? setStr : "--:--"
                })
            }
            root.daily = dailyResult
        }

        console.info("[Weather] Forecast updated — hourly:", root.hourly.length, "h, daily:", root.daily.length, "days")
    }

    function fetchForecast(force: bool = false): void {
        if (!root._canRun(force))
            return
        const lat = root.location.lat
        const lon = root.location.lon
        if (!root.location.valid || (lat === 0 && lon === 0) || forecastFetcher.running) return

        const tempUnit = root.useUSCS ? "fahrenheit" : "celsius"
        const url = "https://api.open-meteo.com/v1/forecast?latitude=" + lat
            + "&longitude=" + lon
            + "&hourly=temperature_2m,weather_code,is_day,precipitation_probability"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,sunrise,sunset"
            + "&forecast_days=7"
            + "&timezone=auto"
            + "&temperature_unit=" + tempUnit

        forecastFetcher.command = ["/usr/bin/curl", "-s", "--max-time", "15", url]
        forecastFetcher.running = true
    }

    function refineOpenMeteoData(apiData): void {
        const current = apiData?.current
        if (!current) return

        const units = apiData?.current_units ?? {}
        const daily = apiData?.daily ?? {}
        const sunrise = daily?.sunrise?.[0] ?? ""
        const sunset = daily?.sunset?.[0] ?? ""

        let result = {}
        result.uv = "0"
        result.humidity = (current.relative_humidity_2m ?? 0) + "%"
        result.sunrise = sunrise ? sunrise.split("T")[1] ?? sunrise : "--:--"
        result.sunset = sunset ? sunset.split("T")[1] ?? sunset : "--:--"
        result.windDir = root._degToCompass(current.wind_direction_10m)
        result.wCode = String(current.weather_code ?? 113)
        result.description = root.describeWeather(result.wCode)
        result.city = root.location.name || "Unknown"

        result.temp = (current.temperature_2m ?? 0) + (units.temperature_2m ?? (root.useUSCS ? "°F" : "°C"))
        result.tempFeelsLike = (current.apparent_temperature ?? 0) + (units.apparent_temperature ?? (root.useUSCS ? "°F" : "°C"))
        result.wind = (current.wind_speed_10m ?? 0) + " " + (units.wind_speed_10m ?? (root.useUSCS ? "mph" : "km/h"))
        result.precip = (current.precipitation ?? 0) + " " + (units.precipitation ?? (root.useUSCS ? "in" : "mm"))
        result.visib = (current.visibility ?? 0) + " " + (units.visibility ?? (root.useUSCS ? "mi" : "km"))
        result.press = (current.pressure_msl ?? 0) + " " + (units.pressure_msl ?? (root.useUSCS ? "inHg" : "hPa"))

        root.data = result
        console.info("[Weather] Updated via Open-Meteo:", result.temp, root.redactedLogCity(result.city))
    }

    function fetchWeatherFallback(force: bool = false): void {
        if (!root._canRun(force))
            return
        const lat = root.location.lat
        const lon = root.location.lon
        if ((lat === 0 && lon === 0) || openMeteoFetcher.running) {
            if (root._canRun(force))
                retryTimer.start()
            return
        }

        const tempUnit = root.useUSCS ? "fahrenheit" : "celsius"
        const windUnit = root.useUSCS ? "mph" : "kmh"
        const precipUnit = root.useUSCS ? "inch" : "mm"
        const visUnit = root.useUSCS ? "mile" : "km"
        const url = "https://api.open-meteo.com/v1/forecast?latitude=" + lat
            + "&longitude=" + lon
            + "&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,pressure_msl,wind_speed_10m,wind_direction_10m,weather_code,visibility"
            + "&daily=sunrise,sunset"
            + "&timezone=auto"
            + "&temperature_unit=" + tempUnit
            + "&wind_speed_unit=" + windUnit
            + "&precipitation_unit=" + precipUnit
            + "&visibility_unit=" + visUnit

        openMeteoFetcher.command = ["/usr/bin/curl", "-s", "--max-time", "15", url]
        openMeteoFetcher.running = true
    }

    function _queueRetry(force: bool = false): void {
        if (root._canRun(force))
            retryTimer.start()
    }

    // Resolve location: manual coords > manual city > GPS > IP auto-detect
    function resolveLocation(force: bool = false): void {
        if (!root._canRun(force))
            return
        if (gpsLocator.running || ipLocator.running || fallbackLocator.running
                || forwardGeocoder.running || reverseGeocoder.running || fetcher.running) {
            return;
        }

        if (root.hasManualCoords) {
            // User provided exact coordinates — reverse geocode for display name
            console.info("[Weather] Using manual coordinates:", root.redactedLogCoordinates(root.configLat, root.configLon));
            root.location = {
                valid: true,
                lat: root.configLat,
                lon: root.configLon,
                name: root.configCity || ""
            };
            if (!root.configCity) {
                // Reverse geocode to get a nice city name
                reverseGeocoder.command = ["/usr/bin/curl", "-s", "--max-time", "10",
                    "https://nominatim.openstreetmap.org/reverse?format=json&lat=" + root.configLat + "&lon=" + root.configLon + "&zoom=10&accept-language=en"];
                reverseGeocoder.running = true;
            } else {
                root.fetchWeather();
            }
            return;
        }

        if (root.hasManualCity) {
            // User provided city name — forward geocode for coordinates + validated name
            console.info("[Weather] Using manual city:", root.redactedLogLocationName(root.configCity));
            const q = encodeURIComponent(root.configCity);
            forwardGeocoder.command = ["/usr/bin/curl", "-s", "--max-time", "10",
                "https://nominatim.openstreetmap.org/search?format=jsonv2&q=" + q + "&limit=5&addressdetails=1&accept-language=es,en"];
            forwardGeocoder.running = true;
            return;
        }

        if (root.enableGPS) {
            console.info("[Weather] Trying GPS via geoclue...");
            gpsLocator.running = true;
            return;
        }

        // Auto-detect from IP
        getLocation(force);
    }

    // Step 1: Get location from IP (primary method)
    function getLocation(force: bool = false): void {
        if (!root._canRun(force))
            return
        if (ipLocator.running) return;
        console.info("[Weather] Getting location from IP...");
        ipLocator.running = true;
    }

    // Step 2: Fetch weather using coordinates (precise) or city name (fallback)
    function fetchWeather(force: bool = false): void {
        if (!root._canRun(force))
            return
        if (!root.location.valid || fetcher.running) return;

        // Skip primary provider (wttr.in) if it has failed repeatedly — go straight to Open-Meteo
        if (root._primaryFailCount >= 3 && Date.now() < root._primaryFailUntil) {
            root.fetchWeatherFallback(force);
            return;
        }
        
        let query;
        if (root.location.lat !== 0 || root.location.lon !== 0) {
            query = root.location.lat + "," + root.location.lon;
        } else {
            query = encodeURIComponent(root.location.name.split(',')[0].trim());
        }
        const cmd = `curl -s --max-time 15 'https://wttr.in/${query}?format=j1'`;
        fetcher.command = ["/usr/bin/bash", "-c", cmd];
        fetcher.running = true;
    }

    function hasRunningRequests(): bool {
        return gpsLocator.running || ipLocator.running || fallbackLocator.running
            || forwardGeocoder.running || reverseGeocoder.running
            || fetcher.running || openMeteoFetcher.running || forecastFetcher.running;
    }

    function getData(force: bool = false): void {
        if (!root._canRun(force))
            return
        root.ensureInitialized()
        if (root.location.valid && !root._locationDirty) {
            fetchWeather(force);
        } else {
            resolveLocation(force);
        }
    }

    // Force refresh (useful for settings UI "refresh now" button)
    function forceRefresh(): void {
        if (!root.enabled || !Config.ready)
            return
        root.ensureInitialized()
        console.info("[Weather] Force refresh requested");
        root._forceMode = true;
        root._locationDirty = false;
        root._forceRefreshPending = false;
        root.location = { valid: false, lat: 0, lon: 0, name: "" };
        root._retryCount = 0;
        root._emptyResponseCount = 0;
        root._primaryFailCount = 0;
        root._primaryFailUntil = 0;
        if (root.hasRunningRequests()) {
            root._forceRefreshPending = true;
            pendingForceRefreshTimer.restart();
            return;
        }
        resolveLocation(true);
    }

    // Retry timer for when network isn't ready at startup
    property int _retryCount: 0
    property int _emptyResponseCount: 0
    // Track consecutive primary provider failures to skip it after repeated timeouts
    property int _primaryFailCount: 0
    property double _primaryFailUntil: 0  // timestamp (ms) until which primary is skipped
    property bool _forceRefreshPending: false
    Timer {
        id: retryTimer
        // Exponential backoff: 5s, 10s, 20s, 40s, 80s
        interval: Math.min(5000 * Math.pow(2, root._retryCount), 80000)
        repeat: false
        onTriggered: {
            if (!root._canRun()) {
                retryTimer.stop()
                root._clearForceModeIfIdle()
                return
            }
            if (root._retryCount < 5) {
                root._retryCount++;
                console.info("[Weather] Retry attempt", root._retryCount);
                if (!root.location.valid) {
                    root.resolveLocation();
                } else {
                    // Location is valid but weather fetch failed — retry weather directly
                    root.fetchWeather();
                }
            }
        }
    }

    Timer {
        id: pendingForceRefreshTimer
        interval: 350
        repeat: true
        onTriggered: {
            if (!root._forceRefreshPending) {
                pendingForceRefreshTimer.stop();
                root._clearForceModeIfIdle()
                return;
            }
            if (!root._canRun()) {
                root._forceRefreshPending = false;
                pendingForceRefreshTimer.stop();
                root._clearForceModeIfIdle();
                return;
            }
            if (root.hasRunningRequests())
                return;
            root._forceRefreshPending = false;
            pendingForceRefreshTimer.stop();
            root.resolveLocation(true);
            root._clearForceModeIfIdle();
        }
    }

    // Debounce timer for manual location changes (wait for user to finish typing)
    Timer {
        id: locationDebounceTimer
        interval: 1500  // 1.5s after last keystroke
        repeat: false
        onTriggered: {
            if (!root._canRun()) {
                root._locationDirty = true
                locationDebounceTimer.stop()
                return
            }
            root._lastCity = root.configCity;
            root._lastLat = root.configLat;
            root._lastLon = root.configLon;
            root.location = { valid: false, lat: 0, lon: 0, name: "" };
            root.resolveLocation();
        }
    }

    property bool _initialized: false

    onActiveChanged: {
        if (root.active)
            root._activate()
        else
            root._deactivate()
    }

    onEnabledChanged: {
        if (!enabled)
            root.stop(true)
        else if (root.active)
            root._activate()
    }

    onUseUSCSChanged: {
        if (root._canRun() && root.location.valid) {
            fetchWeather();
            fetchForecast();
        }
    }

    // Fire forecast fetch whenever location becomes valid (covers all resolution paths)
    onLocationChanged: {
        if (root.location.valid && root._canRun()) {
            Qt.callLater(() => root.fetchForecast())
        }
    }

    // Re-resolve when manual location config changes (debounced)
    property string _lastCity: ""
    property real _lastLat: 0
    property real _lastLon: 0

    onConfigCityChanged: {
        if (!Config.ready || !root.enabled || !root._initialized) return;
        if (root.configCity === root._lastCity) return;
        if (!root._canRun()) {
            root._locationDirty = true
            root._lastCity = root.configCity
            return
        }
        locationDebounceTimer.restart();
    }
    onConfigLatChanged: {
        if (!Config.ready || !root.enabled || !root._initialized) return;
        if (root.configLat === root._lastLat) return;
        if (!root._canRun()) {
            root._locationDirty = true
            root._lastLat = root.configLat
            return
        }
        if (root.hasManualCoords) locationDebounceTimer.restart();
    }
    onConfigLonChanged: {
        if (!Config.ready || !root.enabled || !root._initialized) return;
        if (root.configLon === root._lastLon) return;
        if (!root._canRun()) {
            root._locationDirty = true
            root._lastLon = root.configLon
            return
        }
        if (root.hasManualCoords) locationDebounceTimer.restart();
    }

    Connections {
        target: Config
        function onReadyChanged() {
            if (!Config.ready)
                return
            root.ensureInitialized()
            if (root.active)
                root._activate()
        }
    }

    // Forward geocoder: city name → coordinates + validated name
    Process {
        id: forwardGeocoder
        command: ["/usr/bin/curl", "-s", "--max-time", "10", ""]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!root._canRun())
                    return
                if (text.length === 0) {
                    console.warn("[Weather] Forward geocode empty, falling back to city name");
                    root.location = { valid: true, lat: 0, lon: 0, name: root.configCity };
                    root.fetchWeather();
                    return;
                }
                try {
                    const results = JSON.parse(text);
                    if (Array.isArray(results) && results.length > 0) {
                        const queryLower = root.configCity.toLowerCase().trim();
                        let best = results[0];
                        let bestScore = -1;

                        for (let i = 0; i < results.length; i++) {
                            const r = results[i];
                            const type = String(r?.type ?? "").toLowerCase();
                            const cls = String(r?.class ?? "").toLowerCase();
                            const name = String(r?.name ?? r?.display_name ?? "").toLowerCase();
                            const cityLike = ["city", "town", "village", "municipality", "hamlet", "suburb", "county", "administrative"];

                            let score = 0;
                            if (name === queryLower) score += 5;
                            else if (name.startsWith(queryLower)) score += 4;
                            else if (name.includes(queryLower)) score += 3;
                            if (cityLike.includes(type)) score += 2;
                            if (cls === "boundary" || cls === "place") score += 1;

                            if (score > bestScore) {
                                bestScore = score;
                                best = r;
                            }
                        }

                        const lat = parseFloat(best.lat);
                        const lon = parseFloat(best.lon);
                        let displayName = root.configCity;
                        const addr = best.address ?? {};
                        const city = addr.city || addr.town || addr.village || addr.municipality || addr.county || "";
                        const state = addr.state || addr.region || "";
                        const country = addr.country || "";
                        if (city && state) displayName = city + ", " + state;
                        else if (city && country) displayName = city + ", " + country;
                        else if (best.display_name) {
                            const parts = best.display_name.split(",").map(s => s.trim());
                            displayName = parts.length > 2 ? parts[0] + ", " + parts[parts.length - 1] : parts.join(", ");
                        }

                        root.location = { valid: true, lat: lat, lon: lon, name: displayName };
                        console.info(
                            "[Weather] Geocoded:",
                            root.redactedLogLocationName(root.configCity),
                            "→",
                            root.redactedLogLocationName(displayName),
                            "(",
                            root.redactedLogCoordinates(lat, lon),
                            ")"
                        );
                        root.fetchWeather();
                    } else {
                        console.warn("[Weather] No geocode results for:", root.configCity);
                        root.location = { valid: true, lat: 0, lon: 0, name: root.configCity };
                        root.fetchWeather();
                    }
                } catch (e) {
                    console.error("[Weather] Geocode parse error:", e.message);
                    root.location = { valid: true, lat: 0, lon: 0, name: root.configCity };
                    root.fetchWeather();
                }
            }
        }
    }

    // Reverse geocoder: coordinates → city name
    Process {
        id: reverseGeocoder
        command: ["/usr/bin/curl", "-s", "--max-time", "10", ""]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!root._canRun())
                    return
                if (text.length === 0) {
                    root.fetchWeather();
                    return;
                }
                try {
                    const data = JSON.parse(text);
                    const addr = data.address;
                    if (addr) {
                        const city = addr.city || addr.town || addr.village || addr.municipality || "";
                        const state = addr.state || addr.region || "";
                        const name = city + (state ? `, ${state}` : "");
                        if (name) {
                            root.location = {
                                valid: true,
                                lat: root.location.lat,
                                lon: root.location.lon,
                                name: name
                            };
                            // Save the resolved name back to config for display
                            console.info("[Weather] Reverse geocoded:", root.redactedLogLocationName(name));
                        }
                    }
                } catch (e) {
                    console.warn("[Weather] Reverse geocode error:", e.message);
                }
                root.fetchWeather();
            }
        }
    }

    // GPS via geoclue (where-am-i command)
    Process {
        id: gpsLocator
        property bool _handledFallback: false
        command: ["/usr/bin/bash", "-c", "where-am-i -t 10 2>/dev/null | grep -oP '(Latitude|Longitude):\\s*\\K[\\d.-]+' | head -2 | paste -sd' '"]
        onRunningChanged: if (running) _handledFallback = false
        stdout: StdioCollector {
            onStreamFinished: {
                if (!root._canRun())
                    return
                if (text.trim().length === 0) {
                    console.warn("[Weather] GPS failed, falling back to IP");
                    gpsLocator._handledFallback = true;
                    root.getLocation();
                    return;
                }
                const parts = text.trim().split(/\s+/);
                if (parts.length >= 2) {
                    const lat = parseFloat(parts[0]);
                    const lon = parseFloat(parts[1]);
                    if (!isNaN(lat) && !isNaN(lon)) {
                        root.location = { valid: true, lat: lat, lon: lon, name: "" };
                        console.info("[Weather] GPS location:", root.redactedLogCoordinates(lat, lon));
                        // Reverse geocode for display name
                        reverseGeocoder.command = ["/usr/bin/curl", "-s", "--max-time", "10",
                            "https://nominatim.openstreetmap.org/reverse?format=json&lat=" + lat + "&lon=" + lon + "&zoom=10&accept-language=en"];
                        reverseGeocoder.running = true;
                        return;
                    }
                }
                console.warn("[Weather] GPS parse failed, falling back to IP");
                gpsLocator._handledFallback = true;
                root.getLocation();
            }
        }
        onExited: (code) => {
            if (!root._canRun())
                return
            if (code !== 0 && !root.location.valid && !gpsLocator._handledFallback) {
                console.warn("[Weather] GPS process failed (code " + code + "), falling back to IP");
                gpsLocator._handledFallback = true;
                root.getLocation();
            }
        }
    }

    // IP geolocation (ip-api.com - accurate)
    Process {
        id: ipLocator
        command: ["/usr/bin/curl", "-s", "--max-time", "10", "http://ip-api.com/json/?fields=lat,lon,city,regionName"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!root._canRun())
                    return
                if (text.length === 0) {
                    console.warn("[Weather] IP location empty, trying fallback");
                    fallbackLocator.running = true;
                    return;
                }
                try {
                    const data = JSON.parse(text);
                    if (data.lat && data.lon) {
                        root.location = {
                            valid: true,
                            lat: data.lat,
                            lon: data.lon,
                            name: data.city + (data.regionName ? `, ${data.regionName}` : "")
                        };
                        console.info("[Weather] Location:", root.redactedLogLocationName(root.location.name));
                        root.fetchWeather();
                    } else {
                        fallbackLocator.running = true;
                    }
                } catch (e) {
                    console.error("[Weather] IP location error:", e.message);
                    fallbackLocator.running = true;
                }
            }
        }
        onExited: (code) => {
            if (!root._canRun())
                return
            if (code !== 0) {
                console.warn("[Weather] IP location failed, trying fallback");
                fallbackLocator.running = true;
            }
        }
    }

    // Fallback: ipwho.is
    Process {
        id: fallbackLocator
        command: ["/usr/bin/curl", "-s", "--max-time", "10", "https://ipwho.is/"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!root._canRun())
                    return
                if (text.length === 0) return;
                try {
                    const data = JSON.parse(text);
                    if (data.latitude && data.longitude) {
                        root.location = {
                            valid: true,
                            lat: data.latitude,
                            lon: data.longitude,
                            name: data.city + (data.region ? `, ${data.region}` : "")
                        };
                        console.info("[Weather] Location (fallback):", root.location.name);
                        root.fetchWeather();
                    } else {
                        // Both methods failed, schedule retry
                        root._queueRetry();
                    }
                } catch (e) {
                    console.error("[Weather] Fallback location error:", e.message);
                    root._queueRetry();
                }
            }
        }
        onExited: (code) => {
            if (!root._canRun())
                return
            // If fallback also fails, schedule retry
            if (code !== 0 && !root.location.valid) {
                root._queueRetry();
            }
        }
    }

    // Weather fetcher
    Process {
        id: fetcher
        // Guard: prevent double fallback invocation from both onStreamFinished and onExited
        property bool _fallbackTriggered: false
        command: ["/usr/bin/bash", "-c", ""]
        onRunningChanged: if (running) _fallbackTriggered = false
        stdout: StdioCollector {
            onStreamFinished: {
                if (!root._canRun())
                    return
                const payload = text.trim();
                if (payload.length === 0) {
                    root._emptyResponseCount++;
                    if (root._emptyResponseCount >= 3) {
                        console.warn("[Weather] Empty response (x" + root._emptyResponseCount + "), retrying");
                    } else {
                        console.info("[Weather] Empty response, retrying");
                    }
                    if (!fetcher._fallbackTriggered) {
                        fetcher._fallbackTriggered = true;
                        root._primaryFailCount++;
                        root._primaryFailUntil = Date.now() + 30 * 60 * 1000; // Skip primary for 30min after 3 fails
                        root.fetchWeatherFallback();
                    }
                    return;
                }

                if (!(payload.startsWith("{") || payload.startsWith("["))) {
                    root._emptyResponseCount++;
                    if (root._emptyResponseCount >= 3) {
                        console.warn("[Weather] Non-JSON weather response, retrying");
                    } else {
                        console.info("[Weather] Transient weather response, retrying");
                    }
                    if (!fetcher._fallbackTriggered) {
                        fetcher._fallbackTriggered = true;
                        root._primaryFailCount++;
                        root._primaryFailUntil = Date.now() + 30 * 60 * 1000;
                        root.fetchWeatherFallback();
                    }
                    return;
                }

                try {
                    const parsed = JSON.parse(payload);
                    const weatherPayload = parsed?.data ?? parsed ?? {}
                    const normalized = {
                        current: weatherPayload?.current ?? weatherPayload?.current_condition?.[0],
                        astronomy: weatherPayload?.astronomy ?? weatherPayload?.weather?.[0]?.astronomy?.[0]
                    }
                    root.refineData(normalized);
                    root._emptyResponseCount = 0;
                    root._primaryFailCount = 0; // Reset on success
                    root._clearForceModeIfIdle();
                } catch (e) {
                    root._emptyResponseCount++;
                    if (root._emptyResponseCount >= 3) {
                        console.warn("[Weather] Parse error:", e.message);
                    } else {
                        console.info("[Weather] Parse error, retrying");
                    }
                    if (!fetcher._fallbackTriggered) {
                        fetcher._fallbackTriggered = true;
                        root._primaryFailCount++;
                        root._primaryFailUntil = Date.now() + 30 * 60 * 1000;
                        root.fetchWeatherFallback();
                    }
                }
            }
        }
        onExited: (code) => {
            if (!root._canRun())
                return
            if (code !== 0 && !fetcher._fallbackTriggered) {
                fetcher._fallbackTriggered = true;
                root._primaryFailCount++;
                root._primaryFailUntil = Date.now() + 30 * 60 * 1000;
                console.warn("[Weather] Primary provider failed, switching fallback. code:", code);
                root.fetchWeatherFallback();
            }
            root._clearForceModeIfIdle();
        }
    }

    Process {
        id: openMeteoFetcher
        command: ["/usr/bin/curl", "-s", "--max-time", "15", ""]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!root._canRun())
                    return
                const payload = text.trim()
                if (payload.length === 0) {
                    root._queueRetry()
                    return
                }
                try {
                    root.refineOpenMeteoData(JSON.parse(payload))
                    root._emptyResponseCount = 0
                    root._clearForceModeIfIdle()
                } catch (e) {
                    console.warn("[Weather] Open-Meteo parse error:", e.message)
                    root._queueRetry()
                }
            }
        }
        onExited: (code) => {
            if (!root._canRun())
                return
            if (code !== 0) {
                console.warn("[Weather] Open-Meteo fetch failed, code:", code)
                root._queueRetry()
            }
            root._clearForceModeIfIdle()
        }
    }

    // Parallel fetcher for hourly + 7-day forecast (Open-Meteo, keyless)
    Process {
        id: forecastFetcher
        command: ["/usr/bin/curl", "-s", "--max-time", "15", ""]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!root._canRun())
                    return
                const payload = text.trim()
                if (payload.length === 0) {
                    console.warn("[Weather] Forecast fetch returned empty response")
                    return
                }
                try {
                    root.refineForecastData(JSON.parse(payload))
                } catch (e) {
                    console.warn("[Weather] Forecast parse error:", e.message)
                }
            }
        }
        onExited: (code) => {
            if (!root._canRun())
                return
            if (code !== 0)
                console.warn("[Weather] Forecast fetch failed, code:", code)
            root._clearForceModeIfIdle()
        }
    }

    Timer {
        id: fetchTimer
        running: root.active || root._forceMode
        repeat: true
        interval: root.fetchInterval > 0 ? root.fetchInterval : 600000
        onTriggered: {
            if (!root._canRun())
                return
            root.getData()
            root.fetchForecast()
        }
        onRunningChanged: {
            if (running) Qt.callLater(() => {
                if (!root._canRun())
                    return
                root.getData()
                root.fetchForecast()
            })
            else
                root._clearForceModeIfIdle()
        }
    }
}
