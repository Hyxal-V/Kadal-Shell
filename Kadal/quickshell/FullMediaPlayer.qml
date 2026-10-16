import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire

PanelWindow {
    id: popupWindow

    property bool isOpen: false
    signal closeRequested()

    property var player: null

    property color bgColor: "#121213"
    property color bgColor2: "#1E1E1E"
    property color fgColor: "#B5B5B5"
    property color accentColor: "#F2E5BC"
    property color accentColorGlow: "#FFF7DA"
    property string mainFont: "Rowdies"
    property string iconFont: "JetBrains Mono"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    
    WlrLayershell.layer: WlrLayer.Overlay
    
    // 1. Tell Wayland to route keyboard events to this window ONLY when it is open
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    visible: isOpen || slideAnim.running

    // 2. Catch ANY key press (including Escape) to close the popup
    Item {
        anchors.fill: parent
        focus: popupWindow.isOpen

        Keys.onPressed: (event) => {
            popupWindow.closeRequested()
            event.accepted = true
        }
    }

    // ─── THE PLAYER WRAPPER ──────
    Item {
        id: playerRootItem
        width: cardContainer.width
        height: cardContainer.height

        x: Math.round((parent.width - width) / 2)

        y: popupWindow.isOpen ? (parent.height - height) : parent.height
        opacity: popupWindow.isOpen ? 1.0 : 0.0

        Behavior on y {
            NumberAnimation {
                id: slideAnim
                duration: popupWindow.isOpen ? 38 : 25 // Note: Fixed the typo "38" back to 380 here
                easing.type: popupWindow.isOpen ? Easing.OutBack : Easing.InQuad
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: popupWindow.isOpen ? 220 : 180
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
                fillColor: popupWindow.bgColor
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
                fillColor: popupWindow.bgColor
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
            width: 440
            height: 215
            topLeftRadius: 24
            topRightRadius: 24
            bottomLeftRadius: 0
            bottomRightRadius: 0
            color: popupWindow.bgColor
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
                color: popupWindow.bgColor
            }

            // Absorbs clicks on the card itself so clicking empty space won't close it
            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            ColumnLayout {
                anchors {
                    fill: parent
                    topMargin: 14
                    bottomMargin: 14
                    leftMargin: 16
                    rightMargin: 16
                }
                spacing: 10

                // ─── Top Header Row ───────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24

                    // Source badge pill
                    Rectangle {
                        implicitWidth: badgeRow.implicitWidth + 18
                        implicitHeight: 24
                        radius: 12
                        color: popupWindow.bgColor2

                        Row {
                            id: badgeRow
                            anchors.centerIn: parent
                            spacing: 6

                            // Playing dot
                            Rectangle {
                                width: 6
                                height: 6
                                radius: 3
                                color: (popupWindow.player && popupWindow.player.isPlaying) ? popupWindow.accentColor : popupWindow.fgColor
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: {
                                    if (!popupWindow.player) return "Media Player"
                                    return popupWindow.player.identity || "Media Player"
                                }
                                font { family: "Inter"; pixelSize: 11; weight: Font.Bold }
                                color: popupWindow.fgColor
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Animated visualizer bars when playing
                    Row {
                        spacing: 3
                        anchors.verticalCenter: parent.verticalCenter
                        visible: popupWindow.player && popupWindow.player.isPlaying

                        Repeater {
                            model: 5
                            Rectangle {
                                width: 3
                                height: 6
                                radius: 1.5
                                color: popupWindow.accentColor
                                anchors.verticalCenter: parent.verticalCenter

                                SequentialAnimation on height {
                                    loops: Animation.Infinite
                                    running: popupWindow.player && popupWindow.player.isPlaying && popupWindow.isOpen
                                    NumberAnimation { to: [14, 18, 10, 16, 12][index]; duration: [380, 480, 320, 520, 420][index]; easing.type: Easing.InOutSine }
                                    NumberAnimation { to: 5; duration: [420, 520, 340, 460, 390][index]; easing.type: Easing.InOutSine }
                                }
                            }
                        }
                    }

                    Item { width: 10 }

                    // Volume Control in header
                    Row {
                        spacing: 6
                        anchors.verticalCenter: parent.verticalCenter

                        readonly property real currentVolume: {
                            if (popupWindow.player && popupWindow.player.volumeSupported) return popupWindow.player.volume
                            return Pipewire.defaultAudioSink?.audio?.volume ?? 1.0
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: (parent.currentVolume <= 0) ? "\uf026" : ((parent.currentVolume < 0.5) ? "\uf027" : "\uf028")
                            font { family: "Font Awesome 6 Free"; weight: Font.Bold; pixelSize: 12 }
                            color: popupWindow.fgColor

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (popupWindow.player && popupWindow.player.volumeSupported) {
                                        popupWindow.player.volume = popupWindow.player.volume > 0 ? 0.0 : 0.8
                                    } else if (Pipewire.defaultAudioSink?.audio) {
                                        Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted
                                    }
                                }
                            }
                        }

                        Rectangle {
                            id: volTrack
                            width: 54
                            height: 4
                            radius: 2
                            color: "#2C2C30"
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                anchors {
                                    left: parent.left
                                    top: parent.top
                                    bottom: parent.bottom
                                }
                                width: parent.width * Math.min(1.0, Math.max(0.0, parent.parent.currentVolume))
                                radius: 2
                                color: popupWindow.fgColor
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: (mouse) => {
                                    let val = Math.max(0.0, Math.min(1.0, mouse.x / width))
                                    if (popupWindow.player && popupWindow.player.volumeSupported) {
                                        popupWindow.player.volume = val
                                    } else if (Pipewire.defaultAudioSink?.audio) {
                                        Pipewire.defaultAudioSink.audio.volume = val
                                    }
                                }
                                onPositionChanged: (mouse) => {
                                    if (pressed) {
                                        let val = Math.max(0.0, Math.min(1.0, mouse.x / width))
                                        if (popupWindow.player && popupWindow.player.volumeSupported) {
                                            popupWindow.player.volume = val
                                        } else if (Pipewire.defaultAudioSink?.audio) {
                                            Pipewire.defaultAudioSink.audio.volume = val
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item { width: 8 }

                    // Close button
                    Rectangle {
                        width: 24
                        height: 24
                        radius: 12
                        color: closeArea.containsMouse ? Qt.lighter(popupWindow.bgColor2, 1.5) : popupWindow.bgColor2

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: "\uf00d" // fa-times
                            font { family: "Font Awesome 6 Free"; weight: Font.Bold; pixelSize: 11 }
                            color: closeArea.containsMouse ? "#FFFFFF" : popupWindow.fgColor
                        }

                        MouseArea {
                            id: closeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: popupWindow.closeRequested()
                        }
                    }
                }

                // ─── Middle Section (Cover Art + Info + Seekbar) ─
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 16

                    // Cover Art
                    Rectangle {
                        id: artContainer
                        Layout.preferredWidth: 86
                        Layout.preferredHeight: 86
                        radius: 16
                        color: popupWindow.bgColor2
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.08)

                        Image {
                            id: coverArtImage
                            anchors.fill: parent
                            anchors.margins: 1
                            source: (popupWindow.player && popupWindow.player.trackArtUrl) ? popupWindow.player.trackArtUrl : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            visible: status === Image.Ready && source !== ""

                            layer.enabled: true
                            layer.effect: MultiEffect {
                                maskEnabled: true
                                maskSource: artMask
                            }
                        }

                        Item {
                            id: artMask
                            anchors.fill: parent
                            layer.enabled: true
                            visible: false
                            Rectangle {
                                anchors.fill: parent
                                radius: 15
                                color: "black"
                            }
                        }

                        Item {
                            anchors.fill: parent
                            visible: !coverArtImage.visible

                            Text {
                                anchors.centerIn: parent
                                text: "\uf001" // fa-music
                                font { family: "Font Awesome 6 Free"; weight: Font.Bold; pixelSize: 30 }
                                color: Qt.rgba(1, 1, 1, 0.25)
                            }
                        }
                    }

                    // Info & Seekbar Column
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 3

                        // Track Title
                // Track Title (Scrolling Marquee)
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: titleText.implicitHeight
                            clip: true

                            Text {
                                id: titleText
                                text: {
                                    if (!popupWindow.player) return "No Media Playing"
                                    let meta = popupWindow.player.metadata || {}
                                    let t = popupWindow.player.trackTitle || meta["xesam:title"] || meta["xesam:url"]?.split('/').pop() || "Unknown Title"
                                    return t
                                }
                                font { family: popupWindow.mainFont; pixelSize: 15; weight: Font.Bold }
                                color: "#FFFFFF"
                                
                                // Notice we removed `elide: Text.ElideRight` so the text can expand to its full width
                                
                                // Reset position instantly when the song changes
                                onTextChanged: x = 0 

                                // The ping-pong scroll animation
                                SequentialAnimation on x {
                                    loops: Animation.Infinite
                                    // Only run if the text is wider than the container AND the popup is open
                                    running: titleText.implicitWidth > titleText.parent.width && popupWindow.isOpen

                                    // Wait 2 seconds before scrolling
                                    PauseAnimation { duration: 2000 }
                                    
                                    // Scroll left
                                    NumberAnimation {
                                        to: titleText.parent.width - titleText.implicitWidth
                                        // Speed is based on how much overflow there is (35ms per pixel)
                                        duration: Math.max(0, titleText.implicitWidth - titleText.parent.width) * 35
                                        easing.type: Easing.InOutQuad
                                    }
                                    
                                    // Wait 2 seconds at the end
                                    PauseAnimation { duration: 2000 }
                                    
                                    // Scroll back to the start
                                    NumberAnimation {
                                        to: 0
                                        duration: Math.max(0, titleText.implicitWidth - titleText.parent.width) * 35
                                        easing.type: Easing.InOutQuad
                                    }
                                }
                            }
                        }

                        // Artist Name
                        Text {
                            Layout.fillWidth: true
                            text: {
                                if (!popupWindow.player) return "Nothing is playing"
                                let meta = popupWindow.player.metadata || {}
                                return popupWindow.player.trackArtist || meta["xesam:artist"] || "Unknown Artist"
                            }
                            font { family: "Inter"; pixelSize: 12; weight: Font.DemiBold }
                            color: popupWindow.fgColor
                            elide: Text.ElideRight
                        }

                        // Album Name (optional)
                        Text {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: {
                                if (!popupWindow.player) return ""
                                let meta = popupWindow.player.metadata || {}
                                return popupWindow.player.trackAlbum || meta["xesam:album"] || ""
                            }
                            font { family: "Inter"; pixelSize: 10 }
                            color: "#71717A"
                            elide: Text.ElideRight
                        }

                        Item { height: 2 }

                        // Seekbar / Timeline
                        Item {
                            id: seekContainer
                            Layout.fillWidth: true
                            height: 14

                            property real trackLength: popupWindow.player?.length ?? 0
                            property real trackPos: popupWindow.player?.position ?? 0
                            property real progress: trackLength > 0 ? Math.min(1.0, Math.max(0.0, trackPos / trackLength)) : 0
                            property bool isSeeking: false
                            property real seekRatio: 0

                            Rectangle {
                                id: trackBg
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                }
                                height: (seekArea.containsMouse || seekContainer.isSeeking) ? 6 : 4
                                radius: 3
                                color: "#2C2C30"

                                Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

                                // Progress Fill
                                Rectangle {
                                    anchors {
                                        left: parent.left
                                        top: parent.top
                                        bottom: parent.bottom
                                    }
                                    width: parent.width * (seekContainer.isSeeking ? seekContainer.seekRatio : seekContainer.progress)
                                    radius: 3
                                    color: (seekArea.containsMouse || seekContainer.isSeeking) ? popupWindow.accentColor : popupWindow.fgColor

                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                // Handle thumb
                                Rectangle {
                                    visible: (seekArea.containsMouse || seekContainer.isSeeking) && seekContainer.trackLength > 0
                                    x: Math.max(0, Math.min(parent.width - width, (parent.width * (seekContainer.isSeeking ? seekContainer.seekRatio : seekContainer.progress)) - (width / 2)))
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 10
                                    height: 10
                                    radius: 5
                                    color: "#FFFFFF"
                                }
                            }

                            MouseArea {
                                id: seekArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: (seekContainer.trackLength > 0) ? Qt.PointingHandCursor : Qt.ArrowCursor

                                onPressed: (mouse) => {
                                    if (seekContainer.trackLength > 0 && popupWindow.player) {
                                        seekContainer.isSeeking = true
                                        seekContainer.seekRatio = Math.max(0.0, Math.min(1.0, mouse.x / width))
                                    }
                                }

                                onPositionChanged: (mouse) => {
                                    if (seekContainer.isSeeking && seekContainer.trackLength > 0) {
                                        seekContainer.seekRatio = Math.max(0.0, Math.min(1.0, mouse.x / width))
                                    }
                                }

                                onReleased: (mouse) => {
                                    if (seekContainer.isSeeking && seekContainer.trackLength > 0 && popupWindow.player) {
                                        let ratio = Math.max(0.0, Math.min(1.0, mouse.x / width))
                                        popupWindow.player.position = ratio * seekContainer.trackLength
                                        seekContainer.isSeeking = false
                                    }
                                }

                                onCanceled: {
                                    seekContainer.isSeeking = false
                                }
                            }
                        }

                        // Time labels (current / total)
                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: popupWindow.formatTime(seekContainer.isSeeking ? (seekContainer.seekRatio * seekContainer.trackLength) : (popupWindow.player?.position ?? 0))
                                font { family: "Inter"; pixelSize: 10; weight: Font.Medium }
                                color: "#71717A"
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: popupWindow.formatTime(popupWindow.player?.length ?? 0)
                                font { family: "Inter"; pixelSize: 10; weight: Font.Medium }
                                color: "#71717A"
                            }
                        }
                    }
                }

                // ─── Bottom Controls Row (PERFECTLY CENTERED) ─
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredHeight: 44
                    spacing: 16

                    // Shuffle Button
                    Rectangle {
                        width: 34
                        height: 34
                        radius: 17
                        color: shuffleArea.containsMouse ? Qt.lighter(popupWindow.bgColor2, 1.4) : "transparent"
                        opacity: (popupWindow.player && popupWindow.player.shuffleSupported) ? 1.0 : 0.35

                        Text {
                            anchors.centerIn: parent
                            text: "\uf074" // fa-random / shuffle
                            font { family: "Font Awesome 6 Free"; weight: Font.Bold; pixelSize: 13 }
                            color: (popupWindow.player && popupWindow.player.shuffle) ? popupWindow.accentColor : popupWindow.fgColor
                        }

                        MouseArea {
                            id: shuffleArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (popupWindow.player && popupWindow.player.shuffleSupported) {
                                    popupWindow.player.shuffle = !popupWindow.player.shuffle
                                }
                            }
                        }
                    }

                    // Previous Button
                    Rectangle {
                        width: 36
                        height: 36
                        radius: 18
                        color: prevArea.containsMouse ? Qt.lighter(popupWindow.bgColor2, 1.4) : popupWindow.bgColor2
                        opacity: (!popupWindow.player || popupWindow.player.canGoPrevious) ? 1.0 : 0.4

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: "\uf048" // fa-step-backward
                            font { family: "Font Awesome 6 Free"; weight: Font.Bold; pixelSize: 14 }
                            color: prevArea.containsMouse ? "#FFFFFF" : popupWindow.fgColor
                        }

                        MouseArea {
                            id: prevArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (popupWindow.player) popupWindow.player.previous()
                                else Quickshell.execDetached(["playerctl", "previous"])
                            }
                        }
                    }

                    // Play / Pause Button (Hero Accent)
                    Rectangle {
                        width: 44
                        height: 44
                        radius: 22
                        color: playArea.containsMouse ? Qt.lighter(popupWindow.accentColor, 1.1) : popupWindow.accentColor

                        Behavior on color { ColorAnimation { duration: 150 } }

                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: popupWindow.accentColorGlow
                            shadowBlur: 0.3
                            shadowOpacity: 0.35
                        }

                        Text {
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: (popupWindow.player && popupWindow.player.isPlaying) ? 0 : 1
                            text: (popupWindow.player && popupWindow.player.isPlaying) ? "\uf04c" : "\uf04b" // fa-pause / fa-play
                            font { family: "Font Awesome 6 Free"; weight: Font.Bold; pixelSize: 16 }
                            color: popupWindow.bgColor
                        }

                        MouseArea {
                            id: playArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (popupWindow.player) popupWindow.player.togglePlaying()
                                else Quickshell.execDetached(["playerctl", "play-pause"])
                            }
                        }
                    }

                    // Next Button
                    Rectangle {
                        width: 36
                        height: 36
                        radius: 18
                        color: nextArea.containsMouse ? Qt.lighter(popupWindow.bgColor2, 1.4) : popupWindow.bgColor2
                        opacity: (!popupWindow.player || popupWindow.player.canGoNext) ? 1.0 : 0.4

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: "\uf051" // fa-step-forward
                            font { family: "Font Awesome 6 Free"; weight: Font.Bold; pixelSize: 14 }
                            color: nextArea.containsMouse ? "#FFFFFF" : popupWindow.fgColor
                        }

                        MouseArea {
                            id: nextArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (popupWindow.player) popupWindow.player.next()
                                else Quickshell.execDetached(["playerctl", "next"])
                            }
                        }
                    }

                    // Repeat / Loop Button
                    Rectangle {
                        width: 34
                        height: 34
                        radius: 17
                        color: loopArea.containsMouse ? Qt.lighter(popupWindow.bgColor2, 1.4) : "transparent"
                        opacity: (popupWindow.player && popupWindow.player.loopSupported) ? 1.0 : 0.35

                        Text {
                            anchors.centerIn: parent
                            text: "\uf01e" // fa-repeat
                            font { family: "Font Awesome 6 Free"; weight: Font.Bold; pixelSize: 13 }
                            color: (popupWindow.player && popupWindow.player.loopState !== 0 && popupWindow.player.loopState !== MprisLoopState.None) ? popupWindow.accentColor : popupWindow.fgColor
                        }

                        MouseArea {
                            id: loopArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: popupWindow.cycleLoop()
                        }
                    }
                }
            }
        }
    }
}