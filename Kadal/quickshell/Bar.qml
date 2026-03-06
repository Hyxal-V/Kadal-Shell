import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import Quickshell.Io
import Quickshell.Services.SystemTray

PanelWindow {
    id: root

    anchors {
        bottom: true
        left: true
        right: true
    }
    implicitHeight: 40
    color: bgColor
signal toggleControlPanelRequested()
    PwObjectTracker {
        id: sinkTracker
        objects: [ Pipewire.defaultAudioSink ]
    }

    // ─── Theme ───────────────────────────────────────────────
    property color bgColor: "#121213"
    property color bgColor2: "#1E1E1E"
    property color fgColor: "#B5B5B5"
    property string mainFont: "Rowdies"
    property string iconFont: "JetBrains Mono"
    // ─── Media Player Logic ──────────────────────────────────
    property var activePlayer: findActivePlayer()

    function findActivePlayer() {
        let players = Mpris.players.values
        if (players.length === 0) return null

        // Prefer currently playing
        for (let p of players) {
            if (p.isPlaying) return p
        }
        // Fallback to first available
        return players[0]
    }

    // React to changes
    Connections {
        target: Mpris.players
        function onValuesChanged() { root.activePlayer = findActivePlayer() }
    }

    Connections {
        target: root.activePlayer
        ignoreUnknownSignals: true
        function onIsPlayingChanged() { root.activePlayer = findActivePlayer() }
        function onPlaybackStateChanged() { root.activePlayer = findActivePlayer() }
    }

    Item {
        anchors.fill: parent

        // ─── LEFT ─────────────────────────────────────────────
        Row {
            id: leftContent
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                leftMargin: 16
            }
            spacing: 8
            clip: true

            Rectangle {
                implicitWidth: 82
                implicitHeight: 26
                anchors.verticalCenter: parent.verticalCenter
                color: root.bgColor2
                radius: 30

                Text {
                    anchors.centerIn: parent
                    color: root.fgColor
                    font { family: root.mainFont; pixelSize: 13 }
                    text: Qt.formatDateTime(new Date(), "hh:mm A")

                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        onTriggered: parent.text = Qt.formatDateTime(new Date(), "hh:mm A")
                    }
                }
            }

            Rectangle {
                implicitWidth: (wsRow.implicitWidth ?? 0) + 24
                implicitHeight: 26
                anchors.verticalCenter: parent.verticalCenter
                color: root.bgColor2
                radius: 30
                
                Row {
                    id: wsRow
                    anchors.centerIn: parent
                    spacing: 6
                    
                    Repeater {
                        model: Hyprland.workspaces.values
                        delegate: Item {
                            width: 18
                            height: 18
                            readonly property bool isActive: modelData.id === Hyprland.focusedWorkspace?.id
                            
                            Rectangle {
                                anchors.fill: parent
                                radius: width
                                color: isActive ? root.fgColor : "transparent"
                                border { width: 1; color: root.fgColor }
                            }
                            
                            Text {
                                anchors.centerIn: parent
                                text: modelData.id
                                font { family: "Inter"; pixelSize: 10; weight: Font.DemiBold }
                                color: isActive ? root.bgColor : root.fgColor
                            }
                        }
                    }
                }
            }

           Rectangle {
                id: titlePill
                anchors.verticalCenter: parent.verticalCenter
                
                // 1. The Visibility Condition
                // Leave this as 'true' to always show the pill (and just animate width changes).
                // Change it to 'ToplevelManager.activeToplevel?.activated ?? false' to hide it on an empty desktop.
                property bool showPill: true 

                // 2. The Visibility Trick
                visible: opacity > 0
                opacity: showPill ? 1.0 : 0.0

                // 3. Animate the width (uses 'width' instead of 'implicitWidth' for animations)
                clip: true
                width: showPill ? ((titleRow.implicitWidth ?? 0) + 32) : 0
                height: 26
                color: root.bgColor2
                radius: 30
                
                // 4. The Animations
                Behavior on opacity {
                    NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
                }
                Behavior on width {
                    NumberAnimation { duration: 300; easing.type: Easing.OutBack } // Bouncy pop!
                }

                RowLayout {
                    id: titleRow
                    anchors.centerIn: parent
                    spacing: 8
                    
                    Text {
                        text: ToplevelManager.activeToplevel?.activated ?? false ? "\uf2d0" : "\uf015"
                        font { family: "Font Awesome 6 Free"; weight: Font.Bold; pixelSize: 12 }
                        color: root.fgColor
                    }
                    
                    Text {
                        text: {
                            let t = ToplevelManager.activeToplevel?.title ?? "Home"
                            if (!ToplevelManager.activeToplevel?.activated) t = "Home"
                            return t.length > 60 ? t.slice(0, 57) + "…" : t
                        }
                        color: root.fgColor
                        font { family: "Inter"; pixelSize: 12; weight: Font.DemiBold }
                        elide: Text.ElideRight
                        Layout.maximumWidth: 400
                    }
                }
            }
        }

        // ─── CENTER (Media) ───────────────────────────────────
  Rectangle {
    MouseArea {
                    id: btnMouseArea
                    anchors.fill: parent
                    hoverEnabled: true 
                    
                    // Make the pill lighter when hovered so it feels like a button
                    onEntered: parent.color = Qt.lighter(root.bgColor2, 1.5)
                    onExited: parent.color = root.bgColor2

                    onClicked: {
                       Quickshell.execDetached(["playerctl", "play-pause"])

                        
                    }
             
                        }
            id: centerPill
            anchors.centerIn: parent
            
            // 1. Define your visibility condition here
            property bool showPill: true

            // 2. The Visibility Trick: Only hide it when the opacity hits exactly 0
            visible: opacity > 0
            opacity: showPill ? 1.0 : 0.0

            // 3. Animate the width (expands from 0 to full size)
            // We use 'clip: true' so the text doesn't spill out while it's shrinking
            clip: true
            width: showPill ? Math.min(centerContentRow.implicitWidth + 32, maxAvailableWidth) : 0
            height: 26
            color: root.bgColor2
            radius: 30

            readonly property real maxAvailableWidth: parent.width * 0.4

            // 4. The Animations
            Behavior on opacity {
                NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
            }
            Behavior on width {
                NumberAnimation { duration: 300; easing.type: Easing.OutBack } // OutBack gives it a slight, bouncy pop!
            }

            Row {
                id: centerContentRow
                anchors.centerIn: parent
                spacing: 10

                // Fake visualizer
                Row {
                    id: vizRow
                    spacing: 3
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.activePlayer && root.activePlayer.isPlaying

                    Repeater {
                        model: 4
                        Rectangle {
                            width: 3
                            height: 6
                            radius: 2
                            color: root.fgColor
                            anchors.verticalCenter: parent.verticalCenter

                            SequentialAnimation on height {
                                loops: Animation.Infinite
                                running: root.activePlayer && root.activePlayer.isPlaying
                                NumberAnimation { to: [14, 10, 16, 12][index]; duration: [400, 600, 350, 500][index]; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 6; duration: [450, 550, 300, 600][index]; easing.type: Easing.InOutSine }
                            }
                        }
                    }
                }

                // Song text + debug fallback
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        id: centerText
                        width: Math.min(implicitWidth, centerPill.maxAvailableWidth - (vizRow.visible ? 70 : 40))
                        elide: Text.ElideMiddle
                        color: root.fgColor
                        font { family: root.mainFont; pixelSize: 12; weight: Font.Medium }
                        verticalAlignment: Text.AlignVCenter

                        text: {
                            if (!root.activePlayer) return "No Media Playing"

                            let meta = root.activePlayer.metadata || {}
                            let title = meta["xesam:title"] ?? meta["xesam:url"]?.split('/').pop() ?? "Unknown"
                            let artist = meta["xesam:artist"] ?? ""

                            let display = artist ? artist + " — " + title : title
                            return display.length > 65 ? display.substring(0, 62) + "…" : display
                        }
                    }

                    // Tiny debug (only shows when nothing playing)
                    Text {
                        // Note: If showPill hides the whole rectangle when there is no active player, 
                        // you won't actually see this debug text anymore.
                        visible: !root.activePlayer && Mpris.players.values.length > 0
                        text: "Paused / Stopped (" + Mpris.players.values.length + " players)"
                        font { pixelSize: 10 }
                        color: "#666"
                    }
                }
            }
        }

        // ─── RIGHT ────────────────────────────────────────────
        Row {
            id: rightContent
            anchors {
                right: parent.right
                top: parent.top
                bottom: parent.bottom
                rightMargin: 16
            }
            spacing: 10
            layoutDirection: Qt.RightToLeft
Rectangle {
                id: notifPill
                implicitWidth: 42
                implicitHeight: 26
                anchors.verticalCenter: parent.verticalCenter
                color: root.bgColor2
                radius: 30
                
                Text {
                    anchors.centerIn: parent
                    text: "\uf0f3" 
                    font { family: "Font Awesome 6 Free"; weight: Font.Bold; pixelSize: 13 }
                    color: root.fgColor
                }
Process {
    id: swayncProc
    command: ["swaync-client", "-op"]
}

MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onEntered: parent.color = Qt.lighter(root.bgColor2, 1.5)
    onExited: parent.color = root.bgColor2

    onClicked: {
        // Toggle the 'running' state to execute it
        swayncProc.running = true
        
        // Optional: keep your original signal
      
    }
}}
            // --- Combined Status Pill (Volume + Battery + WiFi) ---
            Rectangle {
                implicitWidth: (statusRow.implicitWidth ?? 0) + 32
                implicitHeight: 26
                anchors.verticalCenter: parent.verticalCenter
                color: root.bgColor2
                radius: 30
                
                Row {
                    
                    id: statusRow
                    anchors.centerIn: parent
                    spacing: 12

                    // WiFi Icon
                    Row {
                        spacing: 6
                        Text {
                            id: wifiIcon
                            text: "\ufaa9" // fallback disconnected
                            font { family: "Font Awesome 5 Free Solid"; weight: Font.Bold; pixelSize: 15 }
                            color: root.fgColor
                            topPadding: 1
                        }
                    }

                    // Volume
                    Row {
                        spacing: 2
                        Text {
                            readonly property var defaultSink: Pipewire.defaultAudioSink
                            readonly property var audio: defaultSink?.audio ?? null

                            text: {
                                if (!audio) return "" // unknown/muted
                                if (audio.muted) return "󰝟" // fa-volume-mute

                                let volPercent = Math.round(audio.volume * 100)

                                if (volPercent <= 0) return "\uf026" // fa-volume-off
                                if (volPercent <= 33) return "\uf027" // fa-volume-down
                                else return "" // fa-volume-up
                            }
                            font { family: root.iconFont; weight: Font.Bold; pixelSize: 15 }
                            topPadding: 1
                            color: root.fgColor
                        }
                    }

                    // Battery
                    Text {
                        topPadding: 3.4
                        text: {
                            let pct = Math.round(UPower.displayDevice.percentage * 100);
                            let icon = UPower.onBattery ? " " : " ";
                            return `${icon} ${pct}%`
                        }
                        color: root.fgColor
                          font { family: "Inter"; pixelSize: 12; weight: Font.Bold } 
                        leftPadding: -2
                    }
                }

                // WiFi updater
                Timer {
                    interval: 5000
                    running: true
                    repeat: true
                    triggeredOnStart: true
                    onTriggered: {
                        nmcliProcess.running = false
                        nmcliProcess.running = true
                    }
                }

                Process {
                    id: nmcliProcess
                    command: ["nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL", "device", "wifi", "list"]

                    stdout: StdioCollector {
                        onStreamFinished: {
                            let output = text.trim()
                            if (output === "") {
                                wifiIcon.text = "󰤭"
                                return
                            }

                            let lines = output.split("\n")
                            let connected = false
                            let ssid = ""
                            let signal = 0

                            for (let line of lines) {
                                let parts = line.split(":")
                                if (parts.length >= 3 && parts[0] === "yes") {
                                    connected = true
                                    ssid = parts[1] || "Unknown"
                                    signal = parseInt(parts[2]) || 0
                                    break
                                }
                            }

                            if (connected) {
                                let strength = signal
                                if (strength > 80) wifiIcon.text = "\uf1eb" // full
                                else if (strength > 55) wifiIcon.text = "\uf1eb" // good
                                else if (strength > 30) wifiIcon.text = "\uf1eb" // ok
                                else wifiIcon.text = "\uf1eb" // weak
                            } else {
                                wifiIcon.text = "󰤭" // disconnected
                            }
                        }
                    }
                }
                
      
            }

   Rectangle {
    // Widened slightly to accommodate the third item
    implicitWidth: sysRow.implicitWidth + 32
    implicitHeight: 26
    anchors.verticalCenter: parent.verticalCenter
    color: root.bgColor2
    radius: 30

    
    // 1. Timer to poll data every 2 seconds
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            ramProc.running = true
            cpuProc.running = true
            tempProc.running = true // Added temperature trigger
        }
    }

    // 2. Process to fetch RAM usage
    Process {
        id: ramProc
        command: ["sh", "-c", "free -h | awk '/^Mem:/ {print $3}'"]
        running: true 
        stdout: StdioCollector {
            onStreamFinished: ramText.text = this.text.trim() + "B" // This will output something like "4.2GiB"
        }
    }

    // 3. Process to fetch CPU usage
    Process {
        id: cpuProc
        command: ["sh", "-c", "top -bn1 | grep 'Cpu(s)' | awk '{print $2}'"]
        running: true 
        stdout: StdioCollector {
            onStreamFinished: cpuText.text = this.text.trim() + "%"
        }
    }

    // 4. Process to fetch CPU Temperature
    Process {
        id: tempProc
        // Reads raw thermal data, divides by 1000, and converts to integer
        command: ["sh", "-c", "awk '{print int($1/1000)}' /sys/class/thermal/thermal_zone0/temp"]
        running: true 
        stdout: StdioCollector {
            onStreamFinished: tempText.text = this.text.trim() + "°C"
        }
    }

    // 5. The UI Layout
    Row {
        id: sysRow
        anchors.centerIn: parent
        spacing: 12 
        
        // --- CPU Section ---
        Row {
            spacing: 6
            Text { 
                topPadding: 1.3
                text: "\uf2db" 
                font { family: "JetBrainsMono NF"; weight: Font.Solid; pixelSize: 12 } 
                color: root.fgColor 
            }
            Text { 
                topPadding: 1.3
                id: cpuText
                text: "..." 
                color: root.fgColor
                 font { family: "Inter"; pixelSize: 12; weight: Font.Bold } 
            }
        }

        // --- Temp Section ---
        Row {
            spacing: 6
            topPadding: 1.3
            Text { 
                text: "" // Thermometer icon (nf-fa-thermometer_half)
                font { family: "JetBrainsMono NF"; weight: Font.Solid; pixelSize: 12 } 
                color: root.fgColor 
            }
            Text { 
                id: tempText
                text: "..." 
                color: root.fgColor
                 font { family: "Inter"; pixelSize: 12; weight: Font.Bold } 
            }
        }

        // --- RAM Section ---
        Row {
            spacing: 6
            topPadding: 1.3
            Text { 
                text: "" 
                font { family: "JetBrainsMono NF"; weight: Font.Solid; pixelSize: 12 } 
                color: root.fgColor 
            }
            Text { 
                id: ramText
                text: "..." 
                color: root.fgColor
                font { family: "Inter"; pixelSize: 12; weight: Font.Bold } 
            }
        }
    }
}

            // ─── SYSTRAY PILL ──────────────────────────────────────
            Rectangle {
                id: trayPill
                visible: SystemTray.items.values.length > 0
                implicitWidth: trayRow.implicitWidth + 24
                implicitHeight: 26
                anchors.verticalCenter: parent.verticalCenter
                color: root.bgColor2
                radius: 30

                Row {
                    id: trayRow
                    anchors.centerIn: parent
                    spacing: 8

                    Repeater {
                        model: SystemTray.items.values
                        delegate: MouseArea {
                            width: 16
                            height: 16
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.LeftButton) {
                                    modelData.activate()
                                } else if (mouse.button === Qt.RightButton) {
                                    modelData.openMenu() 
                                }
                            }

                            Image {
                                anchors.fill: parent
                                source: modelData.icon
                                fillMode: Image.PreserveAspectFit
                                mipmap: true
                            }
                        }
                    }
                }
            }
        }
    }
}