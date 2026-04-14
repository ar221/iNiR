import QtQuick
import QtQuick.Layouts
import qs.modules.common

/**
 * StaggeredReveal — wraps a single child and reveals it with a fade-in + slight
 * slide after (index * baseDelay) ms. Intended for cards inside a ColumnLayout
 * that opens/closes — e.g. sidebar contents. Resets when `active` goes false so
 * a re-open plays the entrance again.
 *
 * Usage:
 *   ColumnLayout {
 *     StaggeredReveal { Layout.fillWidth: true; index: 0; active: sidebarOpen
 *       SomeCard { width: parent.width }
 *     }
 *     ...
 *   }
 *
 * The wrapper forwards implicitWidth/implicitHeight from its single child so
 * the enclosing layout measures correctly. Default property fills into an
 * internal Item that does NOT anchor-fill the wrapper (avoids circular
 * sizing); you should width: parent.width (or anchors.left/right: parent.*)
 * on the wrapped child if you want it to fill horizontally.
 */
Item {
    id: root

    /** Position in the stagger sequence (0-based). Higher = longer delay. */
    property int index: 0
    /** Per-item delay in ms. 40ms feels snappy; 60–80ms for dramatic. */
    property int baseDelay: 40
    /** When false, the reveal is torn down (returns to pre-reveal state). */
    property bool active: true
    /** Small upward slide distance for the entrance (px). */
    property int slideDistance: 10

    default property alias contents: container.data

    property bool _revealed: false

    // Forward child sizing so the parent layout can measure correctly before/after reveal.
    // childrenRect picks up the first child's size; works for single-child usage.
    implicitWidth: container.childrenRect.width
    implicitHeight: container.childrenRect.height

    opacity: _revealed ? 1.0 : 0.0
    Behavior on opacity {
        enabled: Appearance.animationsEnabled
        NumberAnimation {
            duration: Appearance.animation.elementMoveEnter.duration
            easing.type: Appearance.animation.elementMoveEnter.type
            easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
        }
    }

    // Slide via transform so it doesn't fight layout.
    transform: Translate {
        y: root._revealed ? 0 : root.slideDistance
        Behavior on y {
            enabled: Appearance.animationsEnabled
            NumberAnimation {
                duration: Appearance.animation.elementMoveEnter.duration
                easing.type: Appearance.animation.elementMoveEnter.type
                easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
            }
        }
    }

    Item {
        id: container
        width: root.width
        height: root.height
    }

    Timer {
        id: revealTimer
        interval: Math.max(0, root.index * root.baseDelay)
        repeat: false
        onTriggered: root._revealed = true
    }

    function _sync() {
        if (root.active) {
            revealTimer.restart()
        } else {
            revealTimer.stop()
            root._revealed = false
        }
    }

    onActiveChanged: _sync()
    Component.onCompleted: _sync()
}
