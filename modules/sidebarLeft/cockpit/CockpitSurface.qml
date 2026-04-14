import qs.modules.common
import QtQuick
import QtQuick.Layouts

/**
 * CockpitSurface — the left sidebar's composed ambient surface.
 *
 * Replaces the old TabBar + SwipeView drawer. Stacks four visible slot widgets
 * (NowPlayingHero / SystemPulse / WallpaperPalette / ContextStrip) on top of
 * AmbientBackground (the shell's skin, at z:0).
 *
 * Session A: scaffolding only. Each slot is a placeholder rectangle. Sessions
 * B–H fill in the actual content, expand-in-place mechanism, and polish.
 */
Item {
    id: root

    // Ambient surface sits behind everything.
    AmbientBackground {
        id: ambient
        z: 0
    }

    // Cockpit slots — vertical stack, tight composition.
    ColumnLayout {
        id: slots
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8
        z: 1

        NowPlayingHero {}
        SystemPulse {}
        WallpaperPalette {}
        ContextStrip {}
    }
}
