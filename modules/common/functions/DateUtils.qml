pragma Singleton
import Quickshell

Singleton {
    id: root

    function getFirstDayOfWeek(date, firstDay = 1) {
        const d = new Date(date); // Copy
        const day = d.getDay();   // 0 = Sunday, 1 = Monday, ..., 6 = Saturday

        // Calculate difference to firstDay
        const diff = (day - firstDay + 7) % 7;
        d.setDate(d.getDate() - diff);
        return d;
    }

    function sameDate(d1, d2) {
        return (d1.getFullYear() === d2.getFullYear() && d1.getMonth() === d2.getMonth() && d1.getDate() === d2.getDate());
    }

    function getIthDayDateOfSameWeek(date, i, firstDay = 1) {
        const firstDayDate = root.getFirstDayOfWeek(date, firstDay);
        const targetDate = new Date(firstDayDate);
        targetDate.setDate(firstDayDate.getDate() + i);
        return targetDate;
    }

    function formatLastSignal(epochMs, density) {
        if (!epochMs || isNaN(epochMs) || epochMs <= 0)
            return "";

        const isCompact = density === "compact";
        const now = Date.now();
        const deltaMs = now - epochMs;

        if (deltaMs < 0)
            return isCompact ? "" : "-";

        const deltaSec = Math.floor(deltaMs / 1000);
        const deltaMin = Math.floor(deltaSec / 60);
        const deltaHr = Math.floor(deltaMin / 60);
        const deltaDay = Math.floor(deltaHr / 24);

        if (isCompact) {
            if (deltaSec < 60)
                return "now";
            if (deltaMin < 60)
                return deltaMin + "m";
            if (deltaHr < 24)
                return deltaHr + "h";
            return deltaDay + "d";
        }

        const d = new Date(epochMs);
        const hh = String(d.getHours()).padStart(2, "0");
        const mm = String(d.getMinutes()).padStart(2, "0");
        const clock = hh + ":" + mm;

        if (deltaSec < 60)
            return clock + " · just now";
        if (deltaMin < 60)
            return clock + " · " + deltaMin + " min ago";
        if (deltaHr < 24)
            return clock + " · " + deltaHr + " h ago";
        if (deltaDay === 1)
            return clock + " · yesterday";
        return clock + " · " + deltaDay + " d ago";
    }
}
