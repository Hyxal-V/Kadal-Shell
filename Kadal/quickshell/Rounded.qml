import Quickshell
import QtQuick
import QtQuick.Shapes

// qmllint disable uncreatable-type
Scope {
    id: border
    property real borderWidth: 2
    property real cornerRadius: 25
    property color borderColor: "#111418"

    PanelWindow {
        id: top
        anchors {
            top: true
            left: true
            right: true
        }
        implicitHeight: border.borderWidth
        color: border.borderColor
    }

   

 



    PanelWindow {
        id: bottomLeftCorner
        implicitHeight: border.cornerRadius
        implicitWidth: border.cornerRadius
        color: "transparent"
        anchors {
            bottom: true
            left: true
        }
        Rectangle {
            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeWidth: 0
                    fillColor: border.borderColor
                    startX: border.cornerRadius
                    startY: border.cornerRadius
                    PathArc {
                        x: 0
                        y: 0
                        radiusX: border.cornerRadius
                        radiusY: border.cornerRadius
                        direction: PathArc.Clockwise
                    }
                    PathLine {
                        x: 0
                        y: border.cornerRadius
                    }
                    PathLine {
                        x: border.cornerRadius
                        y: border.cornerRadius
                    }
                }
            }
        }
    }
    PanelWindow {
        id: bottomRightCorner
        implicitHeight: border.cornerRadius
        implicitWidth: border.cornerRadius
        color: "transparent"
        anchors {
            bottom: true
            right: true
        }
        Rectangle {
            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeWidth: 0
                    fillColor: border.borderColor
                    startX: 0
                    startY: border.cornerRadius
                    PathLine {
                        x: border.cornerRadius
                        y: border.cornerRadius
                    }
                    PathLine {
                        x: border.cornerRadius
                        y: 0
                    }
                    PathArc {
                        x: 0
                        y: border.cornerRadius
                        radiusX: border.cornerRadius
                        radiusY: border.cornerRadius
                        direction: PathArc.Clockwise
                    }
                }
            }
        }
    }
}
