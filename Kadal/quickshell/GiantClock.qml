import QtQuick
import Quickshell
import Quickshell.Wayland
import QtQuick.Effects
PanelWindow {
    id: backgroundClock
     property string mainFont: "Rowdies"
     property int dotSize:8
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
        width: 280
        height: 150
        color: "#121213" // Dark background matching the image
        radius: 40 // Pill-shaped rounded corners
        border.color: "#F2E5BC" // Cream colored border
        border.width: 7

        // Top Left Diamond
        Rectangle {
            width: backgroundClock.dotSize; height:backgroundClock.dotSize
            color: "#FFF7DA"
            rotation: 45
            anchors { top: parent.top; left: parent.left; topMargin: 30; leftMargin: 40 }
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
            width: backgroundClock.dotSize; height: backgroundClock.dotSize;
            color: "#FFF7DA"
            rotation: 45
            anchors { top: parent.top; right: parent.right; topMargin: 30; rightMargin: 40 }
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
            width: backgroundClock.dotSize; height: backgroundClock.dotSize;
            color: "#FFF7DA"
            rotation: 45
            anchors { bottom: parent.bottom; left: parent.left; bottomMargin: 30; leftMargin: 40 }
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
            width: backgroundClock.dotSize; height: backgroundClock.dotSize;
            color: "#FFF7DA"
            rotation: 45
            anchors { bottom: parent.bottom; right: parent.right; bottomMargin: 30; rightMargin: 40 }  
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
            spacing: 8
            

            Text {
                id: timeText
               font.family:backgroundClock.mainFont
               layer.enabled: true
                        layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: "#FFF7DA" 
                    shadowBlur: 0.2
                    shadowHorizontalOffset: 0
                    shadowVerticalOffset: 0
                }
               topPadding:10
               
               font.pixelSize: 60
                color: "#FFF7DA"
                anchors.horizontalCenter: parent.horizontalCenter
            
            }

            Text {
                id: dateText
                font.pixelSize: 12
                   layer.enabled: true
                        layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: "#FFF7DA" 
                    shadowBlur: 0.9
                    shadowHorizontalOffset: 0
                    shadowVerticalOffset: 0
                }
                color: "#FFF7DA"
           anchors.horizontalCenter: parent.horizontalCenter}
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