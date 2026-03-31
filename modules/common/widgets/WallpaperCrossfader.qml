import QtQuick
import QtQuick.Effects

Item {
    id: root
    clip: true

    property string source
    property int fillMode: Image.PreserveAspectCrop
    property size sourceSize

    property int transitionDuration: 800
    property int easingType: Easing.InOutQuad
    property list<real> easingBezierCurve: []

    property string transitionType: "crossfade"
    property string transitionDirection: "right"
    property bool transitionEnabled: true

    property bool ready: {
        const aw = internal.activeIndex === 0 ? wrapper0 : wrapper1
        const ai = internal.activeIndex === 0 ? img0 : img1
        return ai.status === Image.Ready
    }
    readonly property alias activeIndex: internal.activeIndex

    // ── helpers ──

    function _easingType() {
        return easingBezierCurve.length === 6 ? Easing.BezierSpline : easingType
    }
    function _easingCurve() {
        return easingBezierCurve.length === 6 ? easingBezierCurve : []
    }

    // ── internal state ──

    QtObject {
        id: internal
        property int activeIndex: 0
        property bool transitioning: false

        function wrapperFor(idx) { return idx === 0 ? wrapper0 : wrapper1 }
        function imgFor(idx)     { return idx === 0 ? img0 : img1 }

        function updateSource() {
            if (root.source === "") {
                img0.source = ""
                img1.source = ""
                return
            }

            var currentImg = imgFor(activeIndex)
            if (currentImg.source == root.source && currentImg.status === Image.Ready)
                return

            // If mid-transition, cancel it first
            if (transitioning)
                cancelTransition()

            var nextIdx = activeIndex === 0 ? 1 : 0
            var targetImg = imgFor(nextIdx)

            if (targetImg.source == root.source && targetImg.status === Image.Ready) {
                startTransition(nextIdx)
            } else {
                if (targetImg.source != root.source)
                    targetImg.source = root.source
            }
        }

        function onImageReady(imgIndex) {
            var img = imgFor(imgIndex)
            if (img.status === Image.Ready && imgIndex !== activeIndex && img.source == root.source) {
                startTransition(imgIndex)
            }
        }

        function startTransition(newIndex) {
            var oldIdx = activeIndex
            var newIdx = newIndex
            var oldW = wrapperFor(oldIdx)
            var newW = wrapperFor(newIdx)

            // Ensure new wrapper is on top
            newW.z = 1
            oldW.z = 0

            if (!root.transitionEnabled || root.transitionDuration <= 0) {
                // Instant swap
                snapToFinal(oldW, newW)
                activeIndex = newIdx
                return
            }

            transitioning = true
            activeIndex = newIdx

            // Reset new wrapper to starting state
            newW.opacity = 0
            newW.x = 0
            newW.y = 0
            newW.scale = 1.0
            newW._clipX = 0
            newW._clipY = 0
            newW._clipW = root.width
            newW._clipH = root.height
            newW._useClip = false
            newW._blurAmount = 0

            // Reset old wrapper to fully visible
            oldW.opacity = 1
            oldW.x = 0
            oldW.y = 0
            oldW.scale = 1.0
            oldW._blurAmount = 0

            switch (root.transitionType) {
            case "fadeThrough":
                runFadeThrough(oldW, newW)
                break
            case "wipe":
                runWipe(oldW, newW)
                break
            case "slide":
                runSlide(oldW, newW)
                break
            case "push":
                runPush(oldW, newW)
                break
            case "zoom":
                runZoom(oldW, newW)
                break
            case "blurFade":
                runBlurFade(oldW, newW)
                break
            default: // crossfade
                runCrossfade(oldW, newW)
                break
            }
        }

        function cancelTransition() {
            transitionAnim.stop()
            transitioning = false

            var activeW = wrapperFor(activeIndex)
            var otherIdx = activeIndex === 0 ? 1 : 0
            var otherW = wrapperFor(otherIdx)
            snapToFinal(otherW, activeW)
        }

        function snapToFinal(oldW, newW) {
            oldW.opacity = 0
            oldW.x = 0
            oldW.y = 0
            oldW.scale = 1.0
            oldW._blurAmount = 0
            oldW._useClip = false

            newW.opacity = 1
            newW.x = 0
            newW.y = 0
            newW.scale = 1.0
            newW._clipX = 0
            newW._clipY = 0
            newW._clipW = root.width
            newW._clipH = root.height
            newW._useClip = false
            newW._blurAmount = 0
            newW.z = 1
            oldW.z = 0
        }

        function finishTransition() {
            var oldIdx = activeIndex === 0 ? 1 : 0
            var oldW = wrapperFor(oldIdx)
            var newW = wrapperFor(activeIndex)
            snapToFinal(oldW, newW)
            transitioning = false
        }

        // ── transition runners ──

        function runCrossfade(oldW, newW) {
            animOldOpacity.target = oldW
            animOldOpacity.from = 1; animOldOpacity.to = 0
            animOldOpacity.duration = root.transitionDuration

            animNewOpacity.target = newW
            animNewOpacity.from = 0; animNewOpacity.to = 1
            animNewOpacity.duration = root.transitionDuration

            crossfadeAnim.restart()
        }

        function runFadeThrough(oldW, newW) {
            var dur = root.transitionDuration
            // Phase 1: old fades out (40%)
            fadeOutPhase.target = oldW
            fadeOutPhase.from = 1; fadeOutPhase.to = 0
            fadeOutPhase.duration = Math.round(dur * 0.4)

            // Pause (10%)
            fadePause.duration = Math.round(dur * 0.1)

            // Phase 2: new fades in (50%)
            fadeInPhase.target = newW
            fadeInPhase.from = 0; fadeInPhase.to = 1
            fadeInPhase.duration = Math.round(dur * 0.5)

            fadeThroughAnim.restart()
        }

        function runWipe(oldW, newW) {
            newW._useClip = true
            // Old stays underneath, new reveals via clip
            oldW.z = 0
            newW.z = 1

            var dir = root.transitionDirection
            var dur = root.transitionDuration

            // Starting clip: zero-size at the edge the wipe comes from
            // Ending clip: full size
            if (dir === "left") {
                newW._clipX = root.width; newW._clipY = 0
                newW._clipW = 0; newW._clipH = root.height
                animClipX.target = newW; animClipX.from = root.width; animClipX.to = 0; animClipX.duration = dur
                animClipW.target = newW; animClipW.from = 0; animClipW.to = root.width; animClipW.duration = dur
                animClipY.target = newW; animClipY.from = 0; animClipY.to = 0; animClipY.duration = 0
                animClipH.target = newW; animClipH.from = root.height; animClipH.to = root.height; animClipH.duration = 0
            } else if (dir === "top") {
                newW._clipX = 0; newW._clipY = root.height
                newW._clipW = root.width; newW._clipH = 0
                animClipY.target = newW; animClipY.from = root.height; animClipY.to = 0; animClipY.duration = dur
                animClipH.target = newW; animClipH.from = 0; animClipH.to = root.height; animClipH.duration = dur
                animClipX.target = newW; animClipX.from = 0; animClipX.to = 0; animClipX.duration = 0
                animClipW.target = newW; animClipW.from = root.width; animClipW.to = root.width; animClipW.duration = 0
            } else if (dir === "bottom") {
                newW._clipX = 0; newW._clipY = 0
                newW._clipW = root.width; newW._clipH = 0
                animClipH.target = newW; animClipH.from = 0; animClipH.to = root.height; animClipH.duration = dur
                animClipX.target = newW; animClipX.from = 0; animClipX.to = 0; animClipX.duration = 0
                animClipY.target = newW; animClipY.from = 0; animClipY.to = 0; animClipY.duration = 0
                animClipW.target = newW; animClipW.from = root.width; animClipW.to = root.width; animClipW.duration = 0
            } else { // right (default)
                newW._clipX = 0; newW._clipY = 0
                newW._clipW = 0; newW._clipH = root.height
                animClipW.target = newW; animClipW.from = 0; animClipW.to = root.width; animClipW.duration = dur
                animClipX.target = newW; animClipX.from = 0; animClipX.to = 0; animClipX.duration = 0
                animClipY.target = newW; animClipY.from = 0; animClipY.to = 0; animClipY.duration = 0
                animClipH.target = newW; animClipH.from = root.height; animClipH.to = root.height; animClipH.duration = 0
            }

            newW.opacity = 1
            wipeAnim.restart()
        }

        function runSlide(oldW, newW) {
            var dir = root.transitionDirection
            var dur = root.transitionDuration

            // New slides in over old from the specified direction
            oldW.z = 0; newW.z = 1
            newW.opacity = 1

            var isHorizontal = (dir === "left" || dir === "right")
            var anim = isHorizontal ? animNewX : animNewY

            if (dir === "right") {
                newW.x = root.width
                anim.target = newW; anim.from = root.width; anim.to = 0
            } else if (dir === "left") {
                newW.x = -root.width
                anim.target = newW; anim.from = -root.width; anim.to = 0
            } else if (dir === "bottom") {
                newW.y = root.height
                anim.target = newW; anim.from = root.height; anim.to = 0
            } else { // top
                newW.y = -root.height
                anim.target = newW; anim.from = -root.height; anim.to = 0
            }
            anim.duration = dur
            slideAnim.restart()
        }

        function runPush(oldW, newW) {
            var dir = root.transitionDirection
            var dur = root.transitionDuration

            newW.opacity = 1
            var isHorizontal = (dir === "left" || dir === "right")

            if (isHorizontal) {
                var sign = (dir === "right") ? 1 : -1
                newW.x = sign * root.width
                animNewX.target = newW; animNewX.from = sign * root.width; animNewX.to = 0; animNewX.duration = dur
                animOldX.target = oldW; animOldX.from = 0; animOldX.to = -sign * root.width; animOldX.duration = dur
            } else {
                var signV = (dir === "bottom") ? 1 : -1
                newW.y = signV * root.height
                animNewY.target = newW; animNewY.from = signV * root.height; animNewY.to = 0; animNewY.duration = dur
                animOldY.target = oldW; animOldY.from = 0; animOldY.to = -signV * root.height; animOldY.duration = dur
            }

            pushAnim.restart()
        }

        function runZoom(oldW, newW) {
            var dur = root.transitionDuration

            animOldScale.target = oldW; animOldScale.from = 1.0; animOldScale.to = 0.85; animOldScale.duration = dur
            animOldOpacity.target = oldW; animOldOpacity.from = 1; animOldOpacity.to = 0; animOldOpacity.duration = dur
            animNewScale.target = newW; animNewScale.from = 1.15; animNewScale.to = 1.0; animNewScale.duration = dur
            animNewOpacity.target = newW; animNewOpacity.from = 0; animNewOpacity.to = 1; animNewOpacity.duration = dur

            newW.scale = 1.15
            zoomAnim.restart()
        }

        function runBlurFade(oldW, newW) {
            var dur = root.transitionDuration

            // Activate blur on old wrapper
            oldW._blurActive = true

            animOldBlur.target = oldW; animOldBlur.from = 0; animOldBlur.to = 1.0; animOldBlur.duration = dur
            animOldOpacity.target = oldW; animOldOpacity.from = 1; animOldOpacity.to = 0; animOldOpacity.duration = dur
            animNewOpacity.target = newW; animNewOpacity.from = 0; animNewOpacity.to = 1; animNewOpacity.duration = dur

            blurFadeAnim.restart()
        }
    }

    onSourceChanged: internal.updateSource()

    // ── animation objects ──

    // Shared NumberAnimation building blocks
    NumberAnimation {
        id: animOldOpacity; property: "opacity"
        easing.type: root._easingType(); easing.bezierCurve: root._easingCurve()
    }
    NumberAnimation {
        id: animNewOpacity; property: "opacity"
        easing.type: root._easingType(); easing.bezierCurve: root._easingCurve()
    }
    NumberAnimation {
        id: animOldX; property: "x"
        easing.type: root._easingType(); easing.bezierCurve: root._easingCurve()
    }
    NumberAnimation {
        id: animNewX; property: "x"
        easing.type: root._easingType(); easing.bezierCurve: root._easingCurve()
    }
    NumberAnimation {
        id: animOldY; property: "y"
        easing.type: root._easingType(); easing.bezierCurve: root._easingCurve()
    }
    NumberAnimation {
        id: animNewY; property: "y"
        easing.type: root._easingType(); easing.bezierCurve: root._easingCurve()
    }
    NumberAnimation {
        id: animOldScale; property: "scale"
        easing.type: root._easingType(); easing.bezierCurve: root._easingCurve()
    }
    NumberAnimation {
        id: animNewScale; property: "scale"
        easing.type: root._easingType(); easing.bezierCurve: root._easingCurve()
    }
    NumberAnimation {
        id: animOldBlur; property: "_blurAmount"
        easing.type: root._easingType(); easing.bezierCurve: root._easingCurve()
    }

    // Wipe clip animations
    NumberAnimation {
        id: animClipX; property: "_clipX"
        easing.type: root._easingType(); easing.bezierCurve: root._easingCurve()
    }
    NumberAnimation {
        id: animClipY; property: "_clipY"
        easing.type: root._easingType(); easing.bezierCurve: root._easingCurve()
    }
    NumberAnimation {
        id: animClipW; property: "_clipW"
        easing.type: root._easingType(); easing.bezierCurve: root._easingCurve()
    }
    NumberAnimation {
        id: animClipH; property: "_clipH"
        easing.type: root._easingType(); easing.bezierCurve: root._easingCurve()
    }

    // fadeThrough phase animations
    NumberAnimation {
        id: fadeOutPhase; property: "opacity"
        easing.type: root._easingType(); easing.bezierCurve: root._easingCurve()
    }
    NumberAnimation {
        id: fadeInPhase; property: "opacity"
        easing.type: root._easingType(); easing.bezierCurve: root._easingCurve()
    }
    PauseAnimation { id: fadePause }

    // ── composite animations ──

    // Generic finish handler
    property var _onFinished: function() { internal.finishTransition() }

    ParallelAnimation {
        id: transitionAnim
        // Placeholder — individual types use specific animations below
    }

    ParallelAnimation {
        id: crossfadeAnim
        animations: [animOldOpacity, animNewOpacity]
        onFinished: internal.finishTransition()
    }

    SequentialAnimation {
        id: fadeThroughAnim
        animations: [fadeOutPhase, fadePause, fadeInPhase]
        onFinished: internal.finishTransition()
    }

    ParallelAnimation {
        id: wipeAnim
        animations: [animClipX, animClipY, animClipW, animClipH]
        onFinished: internal.finishTransition()
    }

    // Slide uses a single animation — we pick X or Y in runSlide
    // But we need a wrapper to get onFinished
    ParallelAnimation {
        id: slideAnim
        animations: [animNewX, animNewY]
        onFinished: internal.finishTransition()
    }

    ParallelAnimation {
        id: pushAnim
        animations: [animNewX, animNewY, animOldX, animOldY]
        onFinished: internal.finishTransition()
    }

    ParallelAnimation {
        id: zoomAnim
        animations: [animOldScale, animOldOpacity, animNewScale, animNewOpacity]
        onFinished: internal.finishTransition()
    }

    ParallelAnimation {
        id: blurFadeAnim
        animations: [animOldBlur, animOldOpacity, animNewOpacity]
        onFinished: {
            wrapper0._blurActive = false
            wrapper1._blurActive = false
            internal.finishTransition()
        }
    }

    // ── image wrappers ──

    Item {
        id: wrapper0
        width: root.width
        height: root.height
        transformOrigin: Item.Center
        opacity: 1

        property real _blurAmount: 0
        property bool _blurActive: false

        // Clip properties for wipe
        property bool _useClip: false
        property real _clipX: 0
        property real _clipY: 0
        property real _clipW: root.width
        property real _clipH: root.height

        // Clip layer — only used during wipe transitions
        Item {
            id: clipContainer0
            x: wrapper0._useClip ? wrapper0._clipX : 0
            y: wrapper0._useClip ? wrapper0._clipY : 0
            width: wrapper0._useClip ? wrapper0._clipW : root.width
            height: wrapper0._useClip ? wrapper0._clipH : root.height
            clip: wrapper0._useClip

            Image {
                id: img0
                // Position relative to clip container so image stays stationary
                x: wrapper0._useClip ? -wrapper0._clipX : 0
                y: wrapper0._useClip ? -wrapper0._clipY : 0
                width: root.width
                height: root.height
                fillMode: root.fillMode
                sourceSize: root.sourceSize
                asynchronous: true
                cache: true
                mipmap: true
                smooth: true
                visible: !blur0Loader.active

                onStatusChanged: internal.onImageReady(0)
            }
        }

        Loader {
            id: blur0Loader
            anchors.fill: clipContainer0
            active: wrapper0._blurActive && wrapper0._blurAmount > 0
            sourceComponent: MultiEffect {
                source: img0
                anchors.fill: parent
                blurEnabled: true
                blurMax: 64
                blur: wrapper0._blurAmount
            }
        }
    }

    Item {
        id: wrapper1
        width: root.width
        height: root.height
        transformOrigin: Item.Center
        opacity: 0

        property real _blurAmount: 0
        property bool _blurActive: false

        property bool _useClip: false
        property real _clipX: 0
        property real _clipY: 0
        property real _clipW: root.width
        property real _clipH: root.height

        Item {
            id: clipContainer1
            x: wrapper1._useClip ? wrapper1._clipX : 0
            y: wrapper1._useClip ? wrapper1._clipY : 0
            width: wrapper1._useClip ? wrapper1._clipW : root.width
            height: wrapper1._useClip ? wrapper1._clipH : root.height
            clip: wrapper1._useClip

            Image {
                id: img1
                x: wrapper1._useClip ? -wrapper1._clipX : 0
                y: wrapper1._useClip ? -wrapper1._clipY : 0
                width: root.width
                height: root.height
                fillMode: root.fillMode
                sourceSize: root.sourceSize
                asynchronous: true
                cache: true
                mipmap: true
                smooth: true
                visible: !blur1Loader.active

                onStatusChanged: internal.onImageReady(1)
            }
        }

        Loader {
            id: blur1Loader
            anchors.fill: clipContainer1
            active: wrapper1._blurActive && wrapper1._blurAmount > 0
            sourceComponent: MultiEffect {
                source: img1
                anchors.fill: parent
                blurEnabled: true
                blurMax: 64
                blur: wrapper1._blurAmount
            }
        }
    }

    Component.onCompleted: {
        if (root.source !== "") {
            img0.source = root.source
            wrapper0.opacity = 1
            wrapper1.opacity = 0
        }
    }
}
