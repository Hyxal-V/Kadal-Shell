import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets

Scope {
    id: root

    PwObjectTracker {
        objects: [ Pipewire.defaultAudioSink ]
    }

    Connections {
        target: Pipewire.defaultAudioSink?.audio
        function onVolumeChanged() {
            root.shouldShowOsd = true;
            hideTimer.restart();
        }
    }

    property bool shouldShowOsd: false

    Timer {
        id: hideTimer
        interval: 1500 
        onTriggered: root.shouldShowOsd = false
    }

    PanelWindow {
        id: osdWindow
        anchors.top: true 
        exclusiveZone: 0
        implicitWidth: 400
        implicitHeight: 70 // Slightly taller to allow for the bounce "overshoot"
        color: "transparent"
        mask: Region {}

        Rectangle {
            id: osdBackground
            anchors.horizontalCenter: parent.horizontalCenter
            width: 400
            height: 60
            color: "#121213"
            radius: 20 
			

            // --- THE BOUNCE ANIMATION ---
            // Hidden: -height (completely off-screen)
            // Visible: 0 (at the very top)
            y: root.shouldShowOsd ? 0 : -height 
            
            // We keep a subtle opacity change so it doesn't look harsh if it clips
            opacity: root.shouldShowOsd ? 1.0 : 0.0

            Behavior on y { 
                NumberAnimation { 
                    duration: 450
                    // OutBack creates the "spring/bounce" effect
                    easing.type: root.shouldShowOsd ? Easing.OutBack : Easing.InCubic 
                } 
            }
            
            Behavior on opacity { NumberAnimation { duration: 200 } }

            // Squaring off the TOP corners
            Rectangle {
                color: parent.color
                height: parent.radius
                anchors { left: parent.left; right: parent.right; top: parent.top }
            }

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 25
                    rightMargin: 25
                    topMargin: 5 
                }
                spacing: 15

                Text {
                    id: volIcon
                    font.pixelSize: 26
                    color: (Pipewire.defaultAudioSink?.audio.muted || currentVol <= 0) ? "#66ffffff" : "white"
                    readonly property real currentVol: Pipewire.defaultAudioSink?.audio.volume ?? 0
                    text: {
                        if (Pipewire.defaultAudioSink?.audio.muted || currentVol <= 0) return "󰝟";
                        if (currentVol < 0.33) return "󰕿";
                        if (currentVol < 0.66) return "󰖀";
                        return "󰕾";
                    }
                    
                    // Subtle scale bounce when the icon changes
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }

                // Modern Slider
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 4
                    radius: 2
                    color: "#33ffffff"

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        height: 10
                        radius: 5
                        color: (Pipewire.defaultAudioSink?.audio.muted) ? "#66ffffff" : "white"
                        width: parent.width * (Pipewire.defaultAudioSink?.audio.volume ?? 0)

                        Behavior on width {
                            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                        }
                        
                        Rectangle {
                            anchors.right: parent.right
                            width: 4; height: 10; radius: 5
                            color: "#66ffffff"
                        }
                    }
                }
            }
        }
    }
}