import QtQuick 2.15
import QtQuick.Layouts 1.15
import SddmComponents 2.0
import "."

MouseArea {
    id: root
    width: 640; height: 480
    focus: true; hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    property int currentUserIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property int currentSessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property bool loginInProgress: false
    property bool loginFailed: false
    property bool keyboardOpen: false
    property string currentView: "clock"
    property bool showLoginView: currentView === "login"
    property bool sessionPopupOpen: false
    property int _failCount: 0
    readonly property var _failMessages: ["Wrong password", "Nope", "Are you sure?"]

    readonly property int _nameRole: Qt.UserRole + 1
    readonly property int _realNameRole: Qt.UserRole + 2
    readonly property int _iconRole: Qt.UserRole + 4
    readonly property int _sessNameRole: Qt.UserRole + 4

    readonly property string currentUserLogin: {
        if (userModel.count <= 0) return userModel.lastUser || ""
        var v = userModel.data(userModel.index(root.currentUserIndex, 0), root._nameRole)
        return (v !== undefined && v !== null) ? String(v) : (userModel.lastUser || "")
    }
    readonly property string currentSessionName: {
        if (sessionModel.count <= 0) return "Desktop"
        var v = sessionModel.data(sessionModel.index(root.currentSessionIndex, 0), root._sessNameRole)
        return (v !== undefined && v !== null && String(v).length > 0) ? String(v) : "Desktop"
    }

    readonly property color colPrimary: config.primaryColor || "#cba6f7"
    readonly property color colOnPrimary: config.onPrimaryColor || "#1e1e2e"
    readonly property color colSurface: config.surfaceColor || "#1e1e2e"
    readonly property color colSurfaceContainer: config.surfaceContainerColor || "#313244"
    readonly property color colOnSurface: config.onSurfaceColor || "#cdd6f4"
    readonly property color colOnSurfaceVariant: config.onSurfaceVariantColor || "#9399b2"
    readonly property color colBackground: config.backgroundColor || "#1e1e2e"

    property string timeStr: "00:00"
    property string dateStr: ""

    Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: root.timeStr = Qt.formatTime(new Date(), "hh:mm") }
    Timer { interval: 60000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: root.dateStr = Qt.formatDate(new Date(), "dddd, d MMMM") }

    function attemptLogin() {
        root.loginInProgress = true
        root.loginFailed = false
        sddm.login(root.currentUserLogin, passwordBox.text, root.currentSessionIndex)
    }
    function switchToLogin() { root.currentView = "login"; passwordBox.forceActiveFocus() }

    TextConstants { id: textConstants }
    FontLoader { id: materialSymbolsFont; source: "fonts/MaterialSymbolsRounded.ttf" }
    function symFont() { return materialSymbolsFont.status === FontLoader.Ready ? materialSymbolsFont.name : "" }

    Connections {
        target: sddm
        function onLoginSucceeded() { }
        function onLoginFailed() {
            root.loginInProgress = false
            root.loginFailed = true
            root._failCount = Math.min(root._failCount + 1, root._failMessages.length)
            passwordBox.text = ""
        }
    }

    // Background
    Rectangle { anchors.fill: parent; color: root.colBackground; z: -1 }
    Image {
        anchors.fill: parent
        source: config.background || ""
        fillMode: Image.PreserveAspectCrop
    }

    // Clock view
    Item {
        id: clockView
        anchors.fill: parent
        visible: !root.showLoginView
        opacity: root.showLoginView ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 400 } }

        Column {
            anchors.centerIn: parent
            spacing: 8
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.timeStr
                font.pixelSize: 108; font.family: "Gabarito"; color: root.colOnSurface
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.dateStr
                font.pixelSize: 22; color: root.colOnSurface
            }
        }
        Text {
            anchors.bottom: parent.bottom; anchors.bottomMargin: 40
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Press any key or click to login"
            font.pixelSize: 15; color: root.colOnSurfaceVariant
        }
    }

    // Login view  
    Item {
        id: loginView
        anchors.fill: parent
        visible: root.showLoginView
        opacity: root.showLoginView ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 400 } }

        Column {
            anchors.centerIn: parent
            spacing: 16

            // Avatar placeholder
            Rectangle {
                width: 100; height: 100; radius: 50
                color: root.colSurfaceContainer
                anchors.horizontalCenter: parent.horizontalCenter
                Text {
                    anchors.centerIn: parent
                    text: root.currentUserLogin.charAt(0).toUpperCase()
                    font.pixelSize: 48; color: root.colOnSurface
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.currentUserLogin
                font.pixelSize: 24; color: root.colOnSurface
            }

            // Password field
            Rectangle {
                width: 300; height: 50; radius: 25
                color: Qt.rgba(root.colSurface.r, root.colSurface.g, root.colSurface.b, 0.8)
                border.color: root.loginFailed ? "#f38ba8" : root.colOnSurfaceVariant
                border.width: 1
                anchors.horizontalCenter: parent.horizontalCenter

                Row {
                    anchors.fill: parent; anchors.margins: 12
                    spacing: 8

                    TextInput {
                        id: passwordBox
                        width: parent.width - 50; height: parent.height
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        color: root.colOnSurface
                        font.pixelSize: 16
                        focus: root.showLoginView

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.loginFailed 
                                ? root._failMessages[Math.min(root._failCount - 1, root._failMessages.length - 1)]
                                : "Password"
                            color: root.loginFailed ? "#f38ba8" : root.colOnSurfaceVariant
                            font.pixelSize: 16
                            visible: passwordBox.text.length === 0
                        }

                        Keys.onReturnPressed: root.attemptLogin()
                        Keys.onEscapePressed: { root.currentView = "clock"; root._failCount = 0; root.loginFailed = false }
                    }

                    Rectangle {
                        width: 36; height: 36; radius: 18
                        color: root.colPrimary
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            anchors.centerIn: parent
                            text: "→"; font.pixelSize: 20; color: root.colOnPrimary
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.attemptLogin()
                        }
                    }
                }
            }
        }
    }

    // Session selector (bottom left)
    Text {
        id: sessionButton
        anchors.bottom: parent.bottom; anchors.left: parent.left
        anchors.margins: 24
        text: "⚙ " + root.currentSessionName
        color: root.colOnSurfaceVariant; font.pixelSize: 14
        MouseArea {
            anchors.fill: parent
            onClicked: root.sessionPopupOpen = !root.sessionPopupOpen
        }
    }

    // Session popup
    Rectangle {
        id: sessionPopup
        visible: root.sessionPopupOpen
        x: sessionButton.x; y: sessionButton.y - height - 8
        width: 220; height: sessionCol.implicitHeight + 16
        radius: 12
        color: Qt.rgba(root.colSurface.r, root.colSurface.g, root.colSurface.b, 0.95)
        border.color: Qt.rgba(root.colOnSurface.r, root.colOnSurface.g, root.colOnSurface.b, 0.15)
        z: 50

        Column {
            id: sessionCol
            anchors { fill: parent; margins: 8 }
            spacing: 2
            Repeater {
                model: sessionModel
                delegate: Rectangle {
                    width: sessionCol.width; height: 36; radius: 6
                    color: index === root.currentSessionIndex ? Qt.rgba(root.colPrimary.r, root.colPrimary.g, root.colPrimary.b, 0.2) : "transparent"
                    Text {
                        anchors.verticalCenter: parent.verticalCenter; x: 12
                        text: sessionModel.data(sessionModel.index(index, 0), Qt.UserRole + 4) || "Session"
                        color: root.colOnSurface; font.pixelSize: 14
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { root.currentSessionIndex = index; root.sessionPopupOpen = false }
                    }
                }
            }
        }
    }

    // Power buttons (bottom right)
    Row {
        anchors.bottom: parent.bottom; anchors.right: parent.right
        anchors.margins: 24; spacing: 8
        Repeater {
            model: [
                { icon: "⏾", action: function() { sddm.suspend() }, enabled: sddm.canSuspend },
                { icon: "⏻", action: function() { sddm.powerOff() }, enabled: sddm.canPowerOff },
                { icon: "↻", action: function() { sddm.reboot() }, enabled: sddm.canReboot }
            ]
            delegate: Rectangle {
                width: 40; height: 40; radius: 20
                color: ma.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                opacity: modelData.enabled ? 1 : 0.3
                Text { anchors.centerIn: parent; text: modelData.icon; font.pixelSize: 18; color: root.colOnSurface }
                MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: if (modelData.enabled) modelData.action() }
            }
        }
    }

    // Click anywhere to login (when in clock view)
    MouseArea {
        anchors.fill: parent; z: -1
        onClicked: {
            if (!root.showLoginView) root.switchToLogin()
            else if (root.sessionPopupOpen) root.sessionPopupOpen = false
        }
    }

    Keys.onPressed: function(event) {
        if (!root.showLoginView) root.switchToLogin()
    }
}
