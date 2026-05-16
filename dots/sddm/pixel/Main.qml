import QtQuick 2.15
import QtQuick.Layouts 1.15
import SddmComponents 2.0
import "."

MouseArea {
    id: root
    focus: true; hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    // ── SDDM state ─────────────────────────────────────────────────────────
    property int currentSessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property int currentUserIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property bool loginInProgress: false
    property bool loginFailed: false
    property bool keyboardOpen: false
    property string greeterState: "READY"
    property var receipts: []
    property string footerTimestamp: Qt.formatDateTime(new Date(), "yyyy-MM-dd hh:mm:ss")
    property bool cursorOn: true

    readonly property int _nameRole:     Qt.UserRole + 1
    readonly property int _realNameRole: Qt.UserRole + 2
    readonly property int _sessNameRole: Qt.UserRole + 4

    readonly property string currentUserLogin: {
        if (userModel.count <= 0) return userModel.lastUser || ""
        var v = userModel.data(userModel.index(root.currentUserIndex, 0), root._nameRole)
        return (v !== undefined && v !== null) ? String(v) : (userModel.lastUser || "")
    }
    readonly property string currentUserName: {
        if (userModel.count <= 0) return root.currentUserLogin
        var v = userModel.data(userModel.index(root.currentUserIndex, 0), root._realNameRole)
        var s = (v !== undefined && v !== null) ? String(v) : ""
        return s.length > 0 ? s : root.currentUserLogin
    }
    readonly property bool multiUser: userModel.count > 1

    readonly property string currentSessionName: {
        if (sessionModel.count <= 0) return "Desktop"
        var v = sessionModel.data(sessionModel.index(root.currentSessionIndex, 0), root._sessNameRole)
        return (v !== undefined && v !== null && String(v).length > 0) ? String(v) : "Desktop"
    }

    readonly property color colPrimary:          config.primaryColor          || "#cba6f7"
    readonly property color colOnPrimary:        config.onPrimaryColor        || "#1e1e2e"
    readonly property color colSurface:          config.surfaceColor          || "#1e1e2e"
    readonly property color colSurfaceContainer: config.surfaceContainerColor || "#181825"
    readonly property color colOnSurface:        config.onSurfaceColor        || "#cdd6f4"
    readonly property color colOnSurfaceVariant: config.onSurfaceVariantColor || "#9399b2"
    readonly property color colBackground:       config.backgroundColor       || "#1e1e2e"
    readonly property color colError:            config.errorColor            || "#f38ba8"
    readonly property real  blurRadius:          isNaN(Number(config.blurRadius)) ? 64 : Number(config.blurRadius)
    readonly property bool materialShapeChars:   String(config.materialShapeChars || "false").toLowerCase() === "true"

    readonly property color colCanvas:        config.colCanvas        || "#0E0B06"
    readonly property color colSurfaceHover:  config.colSurfaceHover  || "#21170A"
    readonly property color colSurfaceActive: config.colSurfaceActive || "#2A1C08"
    readonly property color colBorder:        config.colBorder        || "#C98A2E"
    readonly property color colBorderDim:     config.colBorderDim     || "#5E7A48"
    readonly property color colText:          config.colText          || "#D7B56D"
    readonly property color colTextStrong:    config.colTextStrong    || "#E8B54A"
    readonly property color colTextDim:       config.colTextDim       || "#8A9A72"
    readonly property color colDivider:       config.colDivider       || "#74A39A"
    readonly property string hostnameStr:     config.hostname         || "host"
    readonly property string lastSessionStr:  config.lastSession      || "-"

    readonly property color stateColor: {
        if (root.greeterState === "DENIED") return "#D86A3C"
        if (root.greeterState === "AUTH") return root.colBorder
        return root.colTextStrong
    }

    function symFont(): string {
        return materialSymbolsFont.status === FontLoader.Ready ? materialSymbolsFont.name : ""
    }

    function makeFileUrl(p): string {
        if (!p || p.length === 0) return ""
        return p.startsWith("file://") ? p : "file://" + p
    }

    // Avatar paths — dynamic based on selected user
    readonly property string _avatarPath0: root.currentUserLogin ? "/home/" + root.currentUserLogin + "/.face" : ""
    readonly property string _avatarPath1: root.currentUserLogin ? "/var/lib/AccountsService/icons/" + root.currentUserLogin : ""
    readonly property string _avatarPath2: Qt.resolvedUrl("assets/user-face.png")
    readonly property string _avatarPath3: ""

    function switchToLogin(captureChar) {
        Qt.callLater(function() {
            passwordBox.forceActiveFocus()
            if (captureChar && captureChar.length === 1 && captureChar.charCodeAt(0) >= 32)
                passwordBox.text += captureChar
        })
    }

    function attemptLogin() {
        if (root.loginInProgress || passwordBox.text.length === 0) return
        root.loginInProgress = true
        root.loginFailed = false
        root.greeterState = "AUTH"
        sddm.login(root.currentUserLogin, passwordBox.text, root.currentSessionIndex)
    }

    TextConstants { id: textConstants }
    FontLoader { id: materialSymbolsFont; source: "fonts/MaterialSymbolsRounded.ttf" }

    Connections {
        target: sddm
        function onLoginSucceeded() { unlockFadeAnim.start() }
        function onLoginFailed() {
            root.loginInProgress = false
            root.loginFailed = true
            root.greeterState = "DENIED"
            passwordBox.text = ""
        }
    }

    Rectangle { anchors.fill: parent; color: root.colCanvas; z: -1 }

    Rectangle {
        id: unlockOverlay; anchors.fill: parent; color: root.colBackground; opacity: 0; z: 100
        NumberAnimation { id: unlockFadeAnim; target: unlockOverlay; property: "opacity"
            from: 0; to: 1; duration: 300; easing.type: Easing.InQuad }
    }

    Rectangle {
        id: sessionStrip
        anchors.top: parent.top
        anchors.topMargin: 48
        anchors.left: parent.left
        anchors.leftMargin: 64
        anchors.right: parent.right
        anchors.rightMargin: 64
        height: 96
        radius: 0
        color: root.colSurface
        border.color: root.colBorder
        border.width: 1

        Repeater {
            model: 4
            delegate: Item {
                property bool leftSide: index === 0 || index === 2
                property bool topSide: index === 0 || index === 1
                anchors {
                    left: leftSide ? parent.left : undefined
                    right: leftSide ? undefined : parent.right
                    top: topSide ? parent.top : undefined
                    bottom: topSide ? undefined : parent.bottom
                    leftMargin: leftSide ? 8 : 0
                    rightMargin: leftSide ? 0 : 8
                    topMargin: topSide ? 8 : 0
                    bottomMargin: topSide ? 0 : 8
                }
                width: 12
                height: 12
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    width: 8
                    height: 1
                    color: root.colBorder
                }
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    width: 1
                    height: 8
                    color: root.colBorder
                }
            }
        }

        GridLayout {
            anchors.fill: parent
            anchors.margins: 16
            columns: 4
            rowSpacing: 6
            columnSpacing: 16

            Text { text: "HOSTNAME"; color: root.colTextDim; font.family: "JetBrains Mono"; font.pixelSize: 11; font.letterSpacing: 1.4 }
            Text { text: root.hostnameStr; color: root.colText; font.family: "JetBrains Mono"; font.pixelSize: 14 }
            Text { text: "OPERATOR"; color: root.colTextDim; font.family: "JetBrains Mono"; font.pixelSize: 11; font.letterSpacing: 1.4 }
            Text { text: root.currentUserLogin; color: root.colTextStrong; font.family: "JetBrains Mono"; font.pixelSize: 14 }

            Text { text: "LAST SESSION"; color: root.colTextDim; font.family: "JetBrains Mono"; font.pixelSize: 11; font.letterSpacing: 1.4 }
            Text { text: root.lastSessionStr; color: root.colText; font.family: "JetBrains Mono"; font.pixelSize: 14 }
            Text { text: "STATE"; color: root.colTextDim; font.family: "JetBrains Mono"; font.pixelSize: 11; font.letterSpacing: 1.4 }
            Text { text: root.greeterState; color: root.stateColor; font.family: "JetBrains Mono"; font.pixelSize: 14 }
        }
    }

    Rectangle {
        id: promptBlock
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -8
        width: 480
        height: 280
        radius: 0
        color: root.colSurface
        border.color: root.colBorder
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 32
            spacing: 24

            Rectangle {
                id: promptField
                Layout.alignment: Qt.AlignHCenter
                width: 360
                height: 52
                radius: 0
                color: root.colSurfaceHover
                border.color: root.greeterState === "DENIED" ? "#D86A3C" : root.colBorder
                border.width: passwordBox.activeFocus || root.greeterState === "AUTH" ? 2 : 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 12

                    Text {
                        text: ">"
                        color: root.colBorder
                        font.family: "JetBrains Mono"
                        font.pixelSize: 18
                    }

                    PixelDots {
                        Layout.fillWidth: true
                        dotCount: passwordBox.text.length
                        dotColor: root.colText
                        animColor: root.colBorder
                        opacity: root.greeterState === "AUTH" ? 0.7 : 1
                    }

                    TextInput {
                        id: passwordBox
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        echoMode: TextInput.Password
                        color: "transparent"
                        selectionColor: root.colBorder
                        selectedTextColor: root.colTextStrong
                        cursorVisible: false
                        cursorDelegate: Item {}
                        inputMethodHints: Qt.ImhSensitiveData
                        enabled: !root.loginInProgress
                        focus: true
                        font.pixelSize: 16
                        onTextChanged: {
                            root.loginFailed = false
                            if (passwordBox.text.length > 0 && root.greeterState === "DENIED") root.greeterState = "READY"
                        }
                        Keys.onReturnPressed: root.attemptLogin()
                        Keys.onEnterPressed: root.attemptLogin()
                    }

                    Rectangle {
                        width: 2
                        height: 24
                        color: root.colBorder
                        visible: !root.loginInProgress && root.cursorOn
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 16

                Rectangle {
                    id: authButton
                    width: 184
                    height: 44
                    radius: 0
                    color: authMouse.pressed ? Qt.darker(root.colSurfaceActive, 1.1) : root.colSurfaceActive
                    border.color: root.colBorder
                    border.width: authMouse.containsMouse ? 2 : 1

                    Text {
                        anchors.centerIn: parent
                        text: "[ AUTHENTICATE ]"
                        color: root.colTextStrong
                        font.family: "JetBrains Mono"
                        font.pixelSize: 12
                        font.letterSpacing: 0.8
                    }

                    MouseArea {
                        id: authMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.attemptLogin()
                    }
                }

                Rectangle {
                    id: powerButton
                    width: 130
                    height: 44
                    radius: 0
                    color: "transparent"
                    border.color: root.colBorderDim
                    border.width: 1
                    opacity: sddm.canPowerOff ? 1 : 0.4

                    Text {
                        anchors.centerIn: parent
                        text: "[ POWER ]"
                        color: root.colText
                        font.family: "JetBrains Mono"
                        font.pixelSize: 12
                        font.letterSpacing: 0.8
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: sddm.canPowerOff
                        onClicked: sddm.powerOff()
                    }
                }
            }
        }
    }

    Rectangle {
        id: receiptsStrip
        anchors.left: parent.left
        anchors.leftMargin: 64
        anchors.right: parent.right
        anchors.rightMargin: 64
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 96
        height: Math.max(96, 40 + Math.min(root.receipts.length, 5) * 22)
        radius: 0
        color: root.colSurface
        border.color: root.colBorder
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 4

            Text {
                text: "RECEIPTS"
                color: root.colTextDim
                font.family: "JetBrains Mono"
                font.pixelSize: 11
                font.letterSpacing: 1.4
            }

            Repeater {
                model: Math.min(root.receipts.length, 5)
                delegate: RowLayout {
                    width: receiptsStrip.width - 32
                    spacing: 24
                    property var rowData: root.receipts[index]

                    Text { text: rowData.time || ""; color: root.colTextDim; font.family: "JetBrains Mono"; font.pixelSize: 12; Layout.preferredWidth: 60 }
                    Text { text: rowData.event || ""; color: root.colText; font.family: "JetBrains Mono"; font.pixelSize: 12; elide: Text.ElideRight; Layout.preferredWidth: 160 }
                    Text { text: rowData.actor || ""; color: root.colTextStrong; font.family: "JetBrains Mono"; font.pixelSize: 12; elide: Text.ElideRight; Layout.preferredWidth: 100 }
                    Text { text: rowData.verb || ""; color: root.colTextDim; font.family: "JetBrains Mono"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                }
            }
        }
    }

    Text {
        anchors.right: parent.right
        anchors.rightMargin: 64
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 32
        text: root.footerTimestamp
        color: root.colTextDim
        font.family: "JetBrains Mono"
        font.pixelSize: 12
        horizontalAlignment: Text.AlignRight
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.footerTimestamp = Qt.formatDateTime(new Date(), "yyyy-MM-dd hh:mm:ss")
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: root.cursorOn = !root.cursorOn
    }

    // ── VIRTUAL KEYBOARD ───────────────────────────────────────────────────
    VirtualKeyboard {
        id: virtualKeyboard
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
        anchors.bottomMargin: 8; anchors.leftMargin: 24; anchors.rightMargin: 24
        z: 20
        visible: root.keyboardOpen
        bgColor: root.colSurfaceContainer
        btnColor: Qt.lighter(root.colSurfaceContainer, 1.3)
        funcBgColor: root.colSurface
        accentColor: root.colPrimary
        accentTextColor: root.colOnPrimary
        textColor: root.colOnSurface
        onKeyClicked: function(key) { passwordBox.text += key; passwordBox.forceActiveFocus() }
        onBackspaceClicked: { if (passwordBox.text.length > 0) passwordBox.text = passwordBox.text.slice(0, -1); passwordBox.forceActiveFocus() }
        onEnterClicked: root.attemptLogin()
        onCloseRequested: root.keyboardOpen = false
    }

    onClicked: function(mouse) {
        passwordBox.forceActiveFocus()
    }
    onPositionChanged: { passwordBox.forceActiveFocus() }

    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
            if (root.keyboardOpen) { root.keyboardOpen = false; return }
            if (passwordBox.text.length > 0) passwordBox.text = ""
            return
        }
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (passwordBox.text.length > 0) root.attemptLogin()
            event.accepted = true
            return
        }
        if (!passwordBox.activeFocus) passwordBox.forceActiveFocus()
    }

    Component.onCompleted: {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", Qt.resolvedUrl("assets/receipts.json"))
        xhr.onreadystatechange = function() {
            if (xhr.readyState === 4 && xhr.status === 200) {
                try { root.receipts = JSON.parse(xhr.responseText) }
                catch (e) { root.receipts = [] }
            }
        }
        xhr.send()

        Qt.callLater(function() { root.forceActiveFocus() })
    }

    // ── LockIconButton — matches LockSurface component exactly ─────────────
    component LockIconButton: Rectangle {
        id: lockBtn
        required property string icon
        property string tooltip: ""
        property bool toggled: false
        signal clicked()

        width: 44; height: 44; radius: 12
        color: {
            if (!enabled) return Qt.rgba(root.colSurface.r, root.colSurface.g, root.colSurface.b, 0.2)
            if (toggled)  return root.colPrimary
            if (lockBtnMouse.pressed)       return Qt.rgba(root.colOnSurface.r, root.colOnSurface.g, root.colOnSurface.b, 0.3)
            if (lockBtnMouse.containsMouse) return Qt.rgba(root.colOnSurface.r, root.colOnSurface.g, root.colOnSurface.b, 0.15)
            return Qt.rgba(root.colSurface.r, root.colSurface.g, root.colSurface.b, 0.3)
        }
        opacity: enabled ? 1 : 0.4
        Behavior on color { ColorAnimation { duration: 150 } }
        layer.enabled: true
        layer.effect: DropShadow { horizontalOffset: 0; verticalOffset: 2; radius: 8; samples: 17; color: Qt.rgba(0,0,0,0.3) }

        MSymbol {
            anchors.centerIn: parent; text: lockBtn.icon; iconSize: 22
            iconColor: lockBtn.toggled ? root.colOnPrimary : root.colOnSurface
            symFont: root.symFont()
        }
        MouseArea {
            id: lockBtnMouse; anchors.fill: parent; hoverEnabled: true
            cursorShape: Qt.PointingHandCursor; onClicked: lockBtn.clicked()
        }
        Rectangle {
            visible: lockBtnMouse.containsMouse && lockBtn.tooltip.length > 0
            anchors.bottom: parent.top; anchors.bottomMargin: 6
            anchors.horizontalCenter: parent.horizontalCenter
            color: Qt.rgba(root.colSurface.r, root.colSurface.g, root.colSurface.b, 0.95)
            border.color: Qt.rgba(root.colOnSurface.r, root.colOnSurface.g, root.colOnSurface.b, 0.2)
            border.width: 1; radius: 6
            width: tipLabel.implicitWidth + 16; height: tipLabel.implicitHeight + 10
            z: 99
            Text { id: tipLabel; anchors.centerIn: parent; text: lockBtn.tooltip
                font.pixelSize: 12; color: root.colOnSurface }
        }
    }
}
