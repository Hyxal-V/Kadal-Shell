import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import Quickshell.Bluetooth

PanelWindow {
    id: controlPanelWindow

    property bool isOpen: false
    signal closeRequested()
    signal openNotificationCenterRequested()
    signal dndToggleRequested()

    // Theme properties matching Bar and FullMediaPlayer
    property color bgColor: "#121213"
    property color bgColor2: "#1E1E1E"
    property color fgColor: "#B5B5B5"
    property color accentColor: "#F2E5BC"
    property color accentColorGlow: "#FFF7DA"
    property string mainFont: "Rowdies"
    property string iconFont: "JetBrains Mono"
    property int barHeight: 40

    // ─── Network & System States ──────────────────────────────
    property bool wifiEnabled: true
    property string wifiSsid: "Wi-Fi"
    property bool btEnabled: false
    property bool dndEnabled: false
    property real brightnessPercent: 0.5 // 0.0 to 1.0

    readonly property real volumePercent: Pipewire.defaultAudioSink?.audio?.volume ?? 0
    readonly property bool volumeMuted: Pipewire.defaultAudioSink?.audio?.muted ?? false

    // ─── Window Configuration ─────────────────────────────────
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    visible: isOpen || slideAnim.running

    // Dismiss on click outside
    MouseArea {
        id: backdrop
        anchors.fill: parent
        hoverEnabled: false
        onClicked: controlPanelWindow.closeRequested()
    }

    // Keyboard shortcut (Escape to close)
    Item {
        focus: controlPanelWindow.isOpen
        Keys.onEscapePressed: controlPanelWindow.closeRequested()
    }

    // Refresh state when opened
    onIsOpenChanged: {
        if (isOpen) {
            wifiStatusProc.running = true
            wifiSsidProc.running = true
            btStatusProc.running = true
            brightGetProc.running = true
            dndStatusProc.running = true
        }
    }

    // ─── Backend Processes ────────────────────────────────────
    // 1. Wi-Fi Check
    Process {
        id: wifiStatusProc
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                let s = text.trim().toLowerCase()
                controlPanelWindow.wifiEnabled = (s === "enabled")
            }
        }
    }

    // 2. Wi-Fi SSID
    Process {
        id: wifiSsidProc
        command: ["sh", "-c", "nmcli -t -f ACTIVE,SSID dev wifi | awk -F: '$1==\"yes\"{print $2}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let s = text.trim()
                controlPanelWindow.wifiSsid = s !== "" ? s : "Disconnected"
            }
        }
    }

    // 3. Wi-Fi Toggle
    Process {
        id: wifiToggleProc
        command: ["nmcli", "radio", "wifi", controlPanelWindow.wifiEnabled ? "off" : "on"]
        onExited: {
            wifiStatusProc.running = true
            wifiSsidProc.running = true
        }
    }

    // 4. Bluetooth Check
    Process {
        id: btStatusProc
        command: ["sh", "-c", "rfkill list bluetooth | grep -i 'Soft blocked: yes'"]
        onExited: (code) => {
            controlPanelWindow.btEnabled = (code !== 0)
        }
    }

    // 5. Bluetooth Toggle
    Process {
        id: btToggleProc
        command: ["rfkill", "toggle", "bluetooth"]
        onExited: {
            btStatusProc.running = true
        }
    }

    // 6. Brightness Query
    Process {
        id: brightGetProc
        command: ["sh", "-c", "brightnessctl -m | awk -F, '{print $4}' | tr -d '%'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let val = parseInt(text.trim())
                if (!isNaN(val) && !brightMouseArea.pressed) {
                    controlPanelWindow.brightnessPercent = Math.max(0.01, Math.min(1.0, val / 100.0))
                }
            }
        }
    }

    // Helper functions
    function toggleWifi() {
        wifiToggleProc.running = true
    }

    function toggleBluetooth() {
        if (Bluetooth.defaultAdapter) {
            Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
            controlPanelWindow.btEnabled = Bluetooth.defaultAdapter.enabled
        }
        btToggleProc.running = true
    }

    function toggleDnd() {
        controlPanelWindow.dndToggleRequested()
    }

    function setBrightness(ratio) {
        let pct = Math.max(1, Math.min(100, Math.round(ratio * 100)))
        controlPanelWindow.brightnessPercent = pct / 100.0
        Quickshell.execDetached(["brightnessctl", "set", pct + "%"])
    }

    function setVolume(ratio) {
        let val = Math.max(0.0, Math.min(1.0, ratio))
        if (Pipewire.defaultAudioSink?.audio) {
            Pipewire.defaultAudioSink.audio.volume = val
            if (val > 0 && Pipewire.defaultAudioSink.audio.muted) {
                Pipewire.defaultAudioSink.audio.muted = false
            }
        }
    }

    function toggleMute() {
        if (Pipewire.defaultAudioSink?.audio) {
            Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted
        }
    }

    // ─── THE PANEL ROOT ITEM ──────────────────────────────────
    Item {
        id: panelRootItem
        width: cardContainer.width
        height: cardContainer.height

        // Aligned to the right side above the status pill
        x: Math.round(controlPanelWindow.width - width - 16)

        // Docked seamlessly into the bottom bar, extending down to the screen edge
        y: controlPanelWindow.isOpen ? (controlPanelWindow.height - height) : controlPanelWindow.height
        opacity: controlPanelWindow.isOpen ? 1.0 : 0.0

        Behavior on y {
            NumberAnimation {
                id: slideAnim
                duration: controlPanelWindow.isOpen ? 38 : 25
                easing.type: controlPanelWindow.isOpen ? Easing.OutBack : Easing.InQuad
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: controlPanelWindow.isOpen ? 220 : 180
                easing.type: Easing.InOutQuad
            }
        }

        // Left curved fillet joining the card smoothly into the bottom bar
        Shape {
            width: 16
            height: 16
            anchors {
                right: cardContainer.left
                bottom: cardContainer.bottom
            }
            preferredRendererType: Shape.CurveRenderer
            
            // Solid fill
            ShapePath {
                strokeWidth: 0
                fillColor: controlPanelWindow.bgColor
                startX: 16
                startY: 0
                PathLine { x: 16; y: 16 }
                PathLine { x: 0; y: 16 }
                PathCubic {
                    x: 16
                    y: 0
                    control1X: 8.836
                    control1Y: 16
                    control2X: 16
                    control2Y: 8.836
                }
            }
            
            // Border line
            ShapePath {
                strokeWidth: 1
                strokeColor: "#2C2C30"
                fillColor: "transparent"
                startX: 0
                startY: 16
                PathCubic {
                    x: 16
                    y: 0
                    control1X: 8.836
                    control1Y: 16
                    control2X: 16
                    control2Y: 8.836
                }
            }
        }

        // Right curved fillet joining the card smoothly into the bottom bar
        Shape {
            width: 16
            height: 16
            anchors {
                left: cardContainer.right
                bottom: cardContainer.bottom
            }
            preferredRendererType: Shape.CurveRenderer
            
            // Solid fill
            ShapePath {
                strokeWidth: 0
                fillColor: controlPanelWindow.bgColor
                startX: 0
                startY: 0
                PathLine { x: 0; y: 16 }
                PathLine { x: 16; y: 16 }
                PathCubic {
                    x: 0
                    y: 0
                    control1X: 7.164
                    control1Y: 16
                    control2X: 0
                    control2Y: 8.836
                }
            }
            
            // Border line
            ShapePath {
                strokeWidth: 1
                strokeColor: "#2C2C30"
                fillColor: "transparent"
                startX: 16
                startY: 16
                PathCubic {
                    x: 0
                    y: 0
                    control1X: 7.164
                    control1Y: 16
                    control2X: 0
                    control2Y: 8.836
                }
            }
        }

        // ─── CARD CONTAINER ───────────────────────────────────
        Rectangle {
            id: cardContainer
            width: 360
            height: 280 + controlPanelWindow.barHeight
            topLeftRadius: 24
            topRightRadius: 24
            bottomLeftRadius: 0
            bottomRightRadius: 0
            color: controlPanelWindow.bgColor
            border.width: 0
            border.color: "#2C2C30"

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#000000"
                shadowOpacity: 0.55
                shadowBlur: 0.5
                shadowVerticalOffset: -4
            }

            // Cover the 1px bottom border so the card blends completely into the bar
            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                height: 2
                color: controlPanelWindow.bgColor
            }

            // Absorbs clicks on the card itself so clicking empty space won't close it
            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            ColumnLayout {
                anchors {
                    fill: parent
                    topMargin: 20
                    bottomMargin: 10
                    leftMargin: 16
                    rightMargin: 16
                }
                spacing: 14

                // ─── 1. Header Row (Battery & Actions) ─────────
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28

                    // Battery status pill
                    Rectangle {
                        implicitWidth: batteryRow.implicitWidth + 20
                        implicitHeight: 28
                        radius: 14
                        color: controlPanelWindow.bgColor2

                        Row {
                            id: batteryRow
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: {
                                    let pct = Math.round(UPower.displayDevice.percentage * 100)
                                    if (UPower.onBattery) {
                                        if (pct <= 20) return "\uf244" // empty
                                        if (pct <= 50) return "\uf243" // quarter
                                        if (pct <= 75) return "\uf242" // half
                                        return "\uf240" // full
                                    }
                                    return "\uf0e7" // bolt / charging
                                }
                                font { family: "Font Awesome 6 Free"; weight: Font.Bold; pixelSize: 12 }
                                color: controlPanelWindow.accentColor
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: {
                                    let pct = Math.round(UPower.displayDevice.percentage * 100)
                                    return `${pct}%`
                                }
                                font { family: "Inter"; pixelSize: 12; weight: Font.Bold }
                                color: controlPanelWindow.fgColor
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Lock Screen button
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 14
                        color: lockArea.containsMouse ? Qt.lighter(controlPanelWindow.bgColor2, 1.4) : controlPanelWindow.bgColor2

                        Text {
                            anchors.centerIn: parent
                            text: "\uf023" // lock
                            font { family: "Font Awesome 6 Free"; weight: Font.Bold; pixelSize: 11 }
                            color: controlPanelWindow.fgColor
                        }

                        MouseArea {
                            id: lockArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Quickshell.execDetached(["loginctl", "lock-session"])
                                controlPanelWindow.closeRequested()
                            }
                        }
                    }

                    // Power off button
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 14
                        color: powerArea.containsMouse ? Qt.lighter(controlPanelWindow.bgColor2, 1.4) : controlPanelWindow.bgColor2

                        Text {
                            anchors.centerIn: parent
                            text: "\uf011" // power-off
                            font { family: "Font Awesome 6 Free"; weight: Font.Bold; pixelSize: 11 }
                            color: controlPanelWindow.fgColor
                        }

                        MouseArea {
                            id: powerArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Quickshell.execDetached(["wlogout"])
                                controlPanelWindow.closeRequested()
                            }
                        }
                    }

                    // Close button
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 14
                        color: closeArea.containsMouse ? Qt.lighter(controlPanelWindow.bgColor2, 1.4) : controlPanelWindow.bgColor2

                        Text {
                            anchors.centerIn: parent
                            text: "\uf00d" // times
                            font { family: "Font Awesome 6 Free"; weight: Font.Bold; pixelSize: 11 }
                            color: closeArea.containsMouse ? "#FFFFFF" : controlPanelWindow.fgColor
                        }

                        MouseArea {
                            id: closeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: controlPanelWindow.closeRequested()
                        }
                    }
                }

                // ─── 2. GNOME-Style Quick Toggles Grid (2x2) ──
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 10

                    // ── Wi-Fi Toggle Pill ──
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 52
                        radius: 16
                        color: controlPanelWindow.wifiEnabled ? controlPanelWindow.accentColor : controlPanelWindow.bgColor2

                        Behavior on color { ColorAnimation { duration: 180 } }

                        MouseArea {
                            id: wifiArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: controlPanelWindow.toggleWifi()
                        }

                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: 14
                                rightMargin: 14
                            }
                            spacing: 12

                            Text {
                                text: controlPanelWindow.wifiEnabled ? "\uf1eb" : "\uf1eb" // wifi
                                font { family: "Font Awesome 6 Free"; weight: Font.Bold; pixelSize: 16 }
                                color: controlPanelWindow.wifiEnabled ? controlPanelWindow.bgColor : controlPanelWindow.fgColor
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    text: "Wi-Fi"
                                    font { family: "Inter"; pixelSize: 13; weight: Font.Bold }
                                    color: controlPanelWindow.wifiEnabled ? controlPanelWindow.bgColor : "#FFFFFF"
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: controlPanelWindow.wifiEnabled ? controlPanelWindow.wifiSsid : "Off"
                                    font { family: "Inter"; pixelSize: 11 }
                                    color: controlPanelWindow.wifiEnabled ? Qt.darker(controlPanelWindow.bgColor, 1.4) : controlPanelWindow.fgColor
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }

                    // ── Bluetooth Toggle Pill ──
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 52
                        radius: 16
                        color: controlPanelWindow.btEnabled ? controlPanelWindow.accentColor : controlPanelWindow.bgColor2

                        Behavior on color { ColorAnimation { duration: 180 } }

                        MouseArea {
                            id: btArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: controlPanelWindow.toggleBluetooth()
                        }

                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: 14
                                rightMargin: 14
                            }
                            spacing: 12

                            Text {
                                text: "\uf294" // bluetooth
                                font { family: "Font Awesome 6 Free"; weight: Font.Bold; pixelSize: 16 }
                                color: controlPanelWindow.btEnabled ? controlPanelWindow.bgColor : controlPanelWindow.fgColor
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    text: "Bluetooth"
                                    font { family: "Inter"; pixelSize: 13; weight: Font.Bold }
                                    color: controlPanelWindow.btEnabled ? controlPanelWindow.bgColor : "#FFFFFF"
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: controlPanelWindow.btEnabled ? "On" : "Off"
                                    font { family: "Inter"; pixelSize: 11 }
                                    color: controlPanelWindow.btEnabled ? Qt.darker(controlPanelWindow.bgColor, 1.4) : controlPanelWindow.fgColor
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }

                    // ── Do Not Disturb Toggle Pill ──
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 52
                        radius: 16
                        color: controlPanelWindow.dndEnabled ? controlPanelWindow.accentColor : controlPanelWindow.bgColor2

                        Behavior on color { ColorAnimation { duration: 180 } }

                        MouseArea {
                            id: dndArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: controlPanelWindow.toggleDnd()
                        }

                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: 14
                                rightMargin: 14
                            }
                            spacing: 12

                            Text {
                                text: controlPanelWindow.dndEnabled ? "\uf1f6" : "\uf0f3" // bell-slash or bell
                                font { family: "Font Awesome 6 Free"; weight: Font.Bold; pixelSize: 15 }
                                color: controlPanelWindow.dndEnabled ? controlPanelWindow.bgColor : controlPanelWindow.fgColor
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    text: "Do Not Disturb"
                                    font { family: "Inter"; pixelSize: 12; weight: Font.Bold }
                                    color: controlPanelWindow.dndEnabled ? controlPanelWindow.bgColor : "#FFFFFF"
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: controlPanelWindow.dndEnabled ? "Silent" : "Off"
                                    font { family: "Inter"; pixelSize: 11 }
                                    color: controlPanelWindow.dndEnabled ? Qt.darker(controlPanelWindow.bgColor, 1.4) : controlPanelWindow.fgColor
                                }
                            }
                        }
                    }

                    // ── Notification Center Toggle Pill ──
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 52
                        radius: 16
                        color: controlPanelWindow.bgColor2

                        MouseArea {
                            id: notifArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                controlPanelWindow.closeRequested()
                                controlPanelWindow.openNotificationCenterRequested()
                            }
                        }

                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: 14
                                rightMargin: 14
                            }
                            spacing: 12

                            Text {
                                text: "\uf0f3" // bell
                                font { family: "Font Awesome 6 Free"; weight: Font.Bold; pixelSize: 15 }
                                color: controlPanelWindow.fgColor
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    text: "Notifications"
                                    font { family: "Inter"; pixelSize: 12; weight: Font.Bold }
                                    color: "#FFFFFF"
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "Open Center"
                                    font { family: "Inter"; pixelSize: 11 }
                                    color: controlPanelWindow.fgColor
                                }
                            }
                        }
                    }
                }

                // ─── 3. Sliders Section (GNOME Pill Sliders) ───
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    // ── Sound / Volume Bar ──
                    Rectangle {
                        id: volumeSliderContainer
                        Layout.fillWidth: true
                        Layout.preferredHeight: 46
                        radius: 23
                        color: controlPanelWindow.bgColor2

                        // Filled portion
                        Rectangle {
                            anchors {
                                left: parent.left
                                top: parent.top
                                bottom: parent.bottom
                            }
                            width: parent.width * Math.min(1.0, Math.max(0.0, controlPanelWindow.volumeMuted ? 0 : controlPanelWindow.volumePercent))
                            radius: 23
                            color: controlPanelWindow.volumeMuted ? "#404040" : controlPanelWindow.accentColor

                            Behavior on width { NumberAnimation { duration: 100 } }
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        // Content inside slider (Icon left, Percentage right)
                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: 16
                                rightMargin: 16
                            }

                            // Speaker mute/unmute icon button
                            Item {
                                width: 24
                                height: 24

                                Text {
                                    anchors.centerIn: parent
                                    text: {
                                        if (controlPanelWindow.volumeMuted || controlPanelWindow.volumePercent <= 0) return "\uf026" // mute
                                        if (controlPanelWindow.volumePercent < 0.5) return "\uf027" // down
                                        return "\uf028" // up
                                    }
                                    font { family: "Font Awesome 6 Free"; weight: Font.Bold; pixelSize: 15 }
                                    color: (!controlPanelWindow.volumeMuted && controlPanelWindow.volumePercent > 0.15) ? controlPanelWindow.bgColor : controlPanelWindow.fgColor
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: controlPanelWindow.toggleMute()
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: controlPanelWindow.volumeMuted ? "Muted" : `${Math.round(controlPanelWindow.volumePercent * 100)}%`
                                font { family: "Inter"; pixelSize: 12; weight: Font.Bold }
                                color: (!controlPanelWindow.volumeMuted && controlPanelWindow.volumePercent > 0.85) ? controlPanelWindow.bgColor : controlPanelWindow.fgColor
                            }
                        }

                        // Drag & click handler for volume slider
                        MouseArea {
                            id: volumeMouseArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor

                            onClicked: (mouse) => {
                                let ratio = Math.max(0.0, Math.min(1.0, mouse.x / width))
                                controlPanelWindow.setVolume(ratio)
                            }

                            onPositionChanged: (mouse) => {
                                if (pressed) {
                                    let ratio = Math.max(0.0, Math.min(1.0, mouse.x / width))
                                    controlPanelWindow.setVolume(ratio)
                                }
                            }
                        }
                    }

                    // ── Brightness Bar ──
                    Rectangle {
                        id: brightnessSliderContainer
                        Layout.fillWidth: true
                        Layout.preferredHeight: 46
                        radius: 23
                        color: controlPanelWindow.bgColor2

                        // Filled portion
                        Rectangle {
                            anchors {
                                left: parent.left
                                top: parent.top
                                bottom: parent.bottom
                            }
                            width: parent.width * Math.min(1.0, Math.max(0.0, controlPanelWindow.brightnessPercent))
                            radius: 23
                            color: controlPanelWindow.accentColor

                            Behavior on width { NumberAnimation { duration: 100 } }
                        }

                        // Content inside slider (Icon left, Percentage right)
                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: 16
                                rightMargin: 16
                            }

                            Item {
                                width: 24
                                height: 24

                                Text {
                                    anchors.centerIn: parent
                                    text: "\uf185" // sun
                                    font { family: "Font Awesome 6 Free"; weight: Font.Bold; pixelSize: 15 }
                                    color: (controlPanelWindow.brightnessPercent > 0.15) ? controlPanelWindow.bgColor : controlPanelWindow.fgColor
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: `${Math.round(controlPanelWindow.brightnessPercent * 100)}%`
                                font { family: "Inter"; pixelSize: 12; weight: Font.Bold }
                                color: (controlPanelWindow.brightnessPercent > 0.85) ? controlPanelWindow.bgColor : controlPanelWindow.fgColor
                            }
                        }

                        // Drag & click handler for brightness slider
                        MouseArea {
                            id: brightMouseArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor

                            onClicked: (mouse) => {
                                let ratio = Math.max(0.01, Math.min(1.0, mouse.x / width))
                                controlPanelWindow.setBrightness(ratio)
                            }

                            onPositionChanged: (mouse) => {
                                if (pressed) {
                                    let ratio = Math.max(0.01, Math.min(1.0, mouse.x / width))
                                    controlPanelWindow.setBrightness(ratio)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}