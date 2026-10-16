import QtQuick
import Quickshell
import Quickshell.Wayland
import QtQuick.Effects

PanelWindow {
    id: backgroundClock

    // ─── Scale & Configuration ────────────────────────────────
    property real clockScale: 1.2
    property string mainFont: "Rowdies"
    property int dotSize: Math.round(8 * clockScale)

    // Position the clock widget on the screen
    anchors {
        top: true
        left: true
    }
    
    margins {
        top: 100
        left: 50
    }

    // Attach to the Wayland background layer
    WlrLayershell.layer: WlrLayer.Background

    color: "transparent"

    width: clockContainer.width
    height: clockContainer.height

    Rectangle {
        id: clockContainer
        width: Math.round(280 * backgroundClock.clockScale)
        height: Math.round(150 * backgroundClock.clockScale)
        color: "#121213" // Dark background matching the image
        radius: Math.round(40 * backgroundClock.clockScale) // Pill-shaped rounded corners
        border.color: "#F2E5BC" // Cream colored border
        border.width: Math.round(7 * backgroundClock.clockScale)

        // Top Left Diamond
        Rectangle {
            width: backgroundClock.dotSize
            height: backgroundClock.dotSize
            color: "#FFF7DA"
            rotation: 45
            anchors {
                top: parent.top
                left: parent.left
                topMargin: Math.round(30 * backgroundClock.clockScale)
                leftMargin: Math.round(40 * backgroundClock.clockScale)
            }
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#FFF7DA" 
                shadowBlur: 0.3
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 0
            }
        }
        
        // Top Right Diamond
        Rectangle {
            width: backgroundClock.dotSize
            height: backgroundClock.dotSize
            color: "#FFF7DA"
            rotation: 45
            anchors {
                top: parent.top
                right: parent.right
                topMargin: Math.round(30 * backgroundClock.clockScale)
                rightMargin: Math.round(40 * backgroundClock.clockScale)
            }
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#FFF7DA" 
                shadowBlur: 0.3
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 0
            }
        }
        
        // Bottom Left Diamond
        Rectangle {
            width: backgroundClock.dotSize
            height: backgroundClock.dotSize
            color: "#FFF7DA"
            rotation: 45
            anchors {
                bottom: parent.bottom
                left: parent.left
                bottomMargin: Math.round(30 * backgroundClock.clockScale)
                leftMargin: Math.round(40 * backgroundClock.clockScale)
            }
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#FFF7DA" 
                shadowBlur: 0.3
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 0
            }
        }
        
        // Bottom Right Diamond
        Rectangle {
            width: backgroundClock.dotSize
            height: backgroundClock.dotSize
            color: "#FFF7DA"
            rotation: 45
            anchors {
                bottom: parent.bottom
                right: parent.right
                bottomMargin: Math.round(30 * backgroundClock.clockScale)
                rightMargin: Math.round(40 * backgroundClock.clockScale)
            }
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#FFF7DA" 
                shadowBlur: 0.3
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 0
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: Math.round(8 * backgroundClock.clockScale)

            Text {
                id: timeText
                font.family: backgroundClock.mainFont
                topPadding: Math.round(10 * backgroundClock.clockScale)
                font.pixelSize: Math.round(60 * backgroundClock.clockScale)
                color: "#FFF7DA"
                anchors.horizontalCenter: parent.horizontalCenter

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: "#FFF7DA" 
                    shadowBlur: 0.2
                    shadowHorizontalOffset: 0
                    shadowVerticalOffset: 0
                }
            }

            Text {
                id: dateText
                font.pixelSize: Math.round(12 * backgroundClock.clockScale)
                color: "#FFF7DA"
                anchors.horizontalCenter: parent.horizontalCenter

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: "#FFF7DA" 
                    shadowBlur: 0.9
                    shadowHorizontalOffset: 0
                    shadowVerticalOffset: 0
                }
            }
        }

        Timer {
            interval: 1000 
            running: true
            repeat: true
            triggeredOnStart: true 
            onTriggered: {
                let now = new Date();
                
                // Formats time to 24-hour style (e.g., 23:49)
                timeText.text = Qt.formatTime(now, "HH:mm");
                
                // Formats date to day, month name, and year (e.g., 25 February 2026)
                dateText.text = Qt.formatDate(now, "dd MMMM dddd");
            }
        }
    }
}