pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common.functions
import qs.modules.common
import QtQuick
import Quickshell

/**
 * Renders LaTeX snippets with MicroTeX.
 * For every request:
 *   1. Hash it
 *   2. Check if the hash is already processed
 *   3. If not, render it with MicroTeX and mark as processed
 */
Singleton {
    id: root
    
    readonly property var renderPadding: 4 // This is to prevent cutoff in the rendered images
    property int maxCachedRenders: Math.max(32, Config.options?.ai?.maxLatexCacheEntries ?? 300)

    property list<string> processedHashes: []
    property var processedExpressions: ({})
    property var renderedImagePaths: ({})
    property var _activeProcessByHash: ({})
    property string microtexBinaryDir: "/opt/MicroTeX"
    property string microtexBinaryName: "LaTeX"
    property string latexOutputPath: Directories.latexOutput

    signal renderFinished(string hash, string imagePath)

    function _trimCacheIfNeeded(): void {
        const overflow = processedHashes.length - maxCachedRenders
        if (overflow <= 0)
            return
        const drop = processedHashes.slice(0, overflow)
        processedHashes = processedHashes.slice(overflow)
        const nextExpr = Object.assign({}, processedExpressions)
        const nextPaths = Object.assign({}, renderedImagePaths)
        for (let i = 0; i < drop.length; i++) {
            const h = drop[i]
            delete nextExpr[h]
            delete nextPaths[h]
        }
        processedExpressions = nextExpr
        renderedImagePaths = nextPaths
    }

    /**
    * Requests rendering of a LaTeX expression.
    * Returns the [hash, isNew]
    */
    function requestRender(expression) {
        // 1. Hash it and initialize necessary variables
        const hash = Qt.md5(expression)
        const imagePath = `${latexOutputPath}/${hash}.svg`
        
        // 2. Check if the hash is already processed
        if (processedHashes.includes(hash)) {
            // console.log("Already processed: " + hash)
            renderFinished(hash, imagePath)
            return [hash, false]
        } else {
            root.processedHashes = [...root.processedHashes, hash]
            root._trimCacheIfNeeded()
            root.processedExpressions[hash] = expression
            // console.log("Rendering expression: " + expression)
        }

        if (root._activeProcessByHash[hash])
            return [hash, false]

        // 3. If not, render it with MicroTeX and mark as processed
        // console.log(`[LatexRenderer] Rendering expression: ${expression} with hash: ${hash}`)
        // console.log(`                to file: ${imagePath}`)
        // console.log(`                with command: cd ${microtexBinaryDir} && ./${microtexBinaryName} -headless -input=${StringUtils.shellSingleQuoteEscape(expression)} -output=${imagePath} -textsize=${Appearance.font.pixelSize.normal} -padding=${renderPadding} -background=${Appearance.m3colors.m3tertiary} -foreground=${Appearance.m3colors.m3onTertiary} -maxwidth=0.85`)
        const processQml = `
            import Quickshell.Io
            Process {
                id: microtexProcess${hash}
                running: true
                command: [
                    "${root.microtexBinaryDir}/${root.microtexBinaryName}",
                    "-headless",
                    "-input=${StringUtils.escapeBackslashes(expression)}",
                    "-output=${imagePath}",
                    "-textsize=${Appearance.font.pixelSize.normal}",
                    "-padding=${renderPadding}",
                    // "-background=${Appearance.m3colors.m3tertiary}",
                    "-foreground=${Appearance.colors.colOnLayer1}",
                    "-maxwidth=0.85"
                ]
                // stdout: SplitParser {
                //     onRead: data => { console.log("MicroTeX: " + data) }
                // }
                onExited: (exitCode, exitStatus) => {
                    // console.log("[LatexRenderer] MicroTeX process exited with code: " + exitCode + ", status: " + exitStatus)
                    renderedImagePaths["${hash}"] = "${imagePath}"
                    const active = Object.assign({}, root._activeProcessByHash)
                    delete active["${hash}"]
                    root._activeProcessByHash = active
                    root.renderFinished("${hash}", "${imagePath}")
                    microtexProcess${hash}.destroy()
                }
            }
        `
        // console.log("MicroTeX: " + processQml)
        const proc = Qt.createQmlObject(processQml, root, `MicroTeXProcess_${hash}`)
        root._activeProcessByHash[hash] = proc
        return [hash, true]
    }
}
