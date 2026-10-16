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
        implicitHeight: 100 // Taller to allow for the bounce "overshoot"
        color: "transparent"
        mask: Region {}

        Rectangle {
            id: osdBackground
            anchors.horizontalCenter: parent.horizontalCenter
            width: 400
            height: 54 // Slimmed down for a sleeker profile
            color: "#121213"
            radius: 16 

            // --- THE BOUNCE ANIMATION ---
            y: root.shouldShowOsd ? 0 : -height 
            opacity: root.shouldShowOsd ? 1.0 : 0.0

            Behavior on y { 
                NumberAnimation { 
                    duration: 450
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
                    leftMargin: 20
                    rightMargin: 20
                    topMargin: 4 // Compensate for the squared top
                }
                spacing: 16

                // Icon
                Text {
                    id: volIcon
                    font.pixelSize: 22
                    color: (Pipewire.defaultAudioSink?.audio.muted || currentVol <= 0) ? "#66ffffff" : "white"
                    readonly property real currentVol: Pipewire.defaultAudioSink?.audio.volume ?? 0
                    text: {
                        if (Pipewire.defaultAudioSink?.audio.muted || currentVol <= 0) return "󰝟";
                        if (currentVol < 0.33) return "󰕿";
                        if (currentVol < 0.66) return "󰖀";
                        return "󰕾";
                    }
                }

                // Elegant Slider
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 6
                    radius: 3
                    color: "#2A2A2E" // Darker, subtle background track

                    Rectangle {
                        anchors {
                            left: parent.left
                            top: parent.top
                            bottom: parent.bottom
                        }
                        radius: 3
                        color: (Pipewire.defaultAudioSink?.audio.muted) ? "#66ffffff" : "white"
                        width: parent.width * Math.min(1.0, Math.max(0.0, Pipewire.defaultAudioSink?.audio.volume ?? 0))

                        Behavior on width {
                            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                        }
                        
                        // Clean circular thumb
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.right
                            width: 12
                            height: 12
                            radius: 6
                            color: "white"
                            visible: !Pipewire.defaultAudioSink?.audio.muted && width > 0
                        }
                    }
                }

                // Percentage Text
                Text {
                    Layout.preferredWidth: 45 // Fixed width prevents the slider from jittering
                    horizontalAlignment: Text.AlignRight
                    font.family: "Inter" 
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    color: (Pipewire.defaultAudioSink?.audio.muted) ? "#66ffffff" : "white"
                    text: {
                        if (Pipewire.defaultAudioSink?.audio.muted) return "Muted";
                        return Math.round((Pipewire.defaultAudioSink?.audio.volume ?? 0) * 100) + "%";
                    }
                }
            }
        }
    }
}