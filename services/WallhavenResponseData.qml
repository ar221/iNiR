import qs.modules.common
import QtQuick;

/**
 * A Wallhaven response page (renamed from BooruResponseData when the Booru
 * stack was dropped). The struct is intentionally generic so Wallhaven.qml
 * can populate it without further indirection.
 */
QtObject {
    property string provider
    property var tags
    property var page
    property var images
    property string message
}
