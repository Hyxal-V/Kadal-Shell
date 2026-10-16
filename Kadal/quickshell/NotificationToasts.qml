import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: toastWindow

    property color bgColor: "#121213"
    property color bgColor2: "#1E1E1E"
    property color fgColor: "#B5B5B5"
    property color accentColor: "#F2E5BC"
    property color accentColorGlow: "#FFF7DA"
    property string mainFont: "Rowdies"
    property string iconFont: "JetBrains Mono"

    signal openPanelRequested()

    anchors {
        top: true
    }
    margins {
        top: 20
    }

    width: 410
    height: Math.max(1, toastColumn.implicitHeight + 20)
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay

    property var activeToasts: []

    function showToast(notif) {
        let toastObj = {
            id: notif.id,
            appName: notif.appName || "Notification",
            appIcon: notif.appIcon || "",
            summary: notif.summary || "",
            body: notif.body || "",
            image: notif.image || "",
            actions: notif.actions || [],
            timeStr: notif.timeStr || "Just now",
            ref: notif.ref
        }

        // Keep maximum of 3 concurrent toasts on screen
        let copy = activeToasts.slice(0, 2)
        copy.unshift(toastObj)
        activeToasts = copy
    }

    function removeToast(id) {
        let copy = []
        for (let i = 0; i < activeToasts.length; i++) {
            if (activeToasts[i].id !== id) {
                copy.push(activeToasts[i])
            }
        }
        activeToasts = copy
    }

    visible: activeToasts.length > 0

    Column {
        id: toastColumn
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: 390
        spacing: 10

        Repeater {
            model: toastWindow.activeToasts

            delegate: Item {
                id: toastDelegate
                width: 390
                height: toastCard.height

                // Slide down and fade in
                opacity: 0.0
                y: -30
                Component.onCompleted: {
                    appearAnim.start()
                }

                ParallelAnimation {
                    id: appearAnim
                    NumberAnimation { target: toastDelegate; property: "opacity"; to: 1.0; duration: 250; easing.type: Easing.OutCubic }
                    NumberAnimation { target: toastDelegate; property: "y"; to: 0; duration: 280; easing.type: Easing.OutBack }
                }

                Rectangle {
                    id: toastCard
                    width: parent.width
                    height: cardLayout.implicitHeight + 24
                    color: toastWindow.bgColor
                    radius: 16
                    border.width: 0
                    border.color: "#2C2C30"

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: "#000000"
                        shadowOpacity: 0.65
                        shadowBlur: 0.6
                        shadowVerticalOffset: 4
                    }

                    // Auto dismiss timer (5 seconds), pauses on mouse hover
                    Timer {
                        id: dismissTimer
                        interval: 5000
                        running: !cardMouseArea.containsMouse
                        onTriggered: toastWindow.removeToast(modelData.id)
                    }

                    // Progress bar indicator along the bottom
                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                            leftMargin: 16
                            rightMargin: 16
                            bottomMargin: 4
                        }
                        height: 2
                        color: Qt.rgba(1, 1, 1, 0.08)
                        radius: 1

                        Rectangle {
                            id: progressFill
                            height: parent.height
                            radius: 1
                            color: toastWindow.accentColor
                            width: parent.width

                            NumberAnimation on width {
                                from: progressFill.parent.width
                                to: 0
                                duration: 5000
                                running: dismissTimer.running
                            }
                        }
                    }

                    MouseArea {
                        id: cardMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            toastWindow.openPanelRequested()
                            toastWindow.removeToast(modelData.id)
                        }
                    }

                    ColumnLayout {
                        id: cardLayout
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            leftMargin: 14
                            rightMargin: 14
                            topMargin: 12
                        }
                        spacing: 6

                        // ─── Header: App Icon, App Name, Time, Close ────
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            // App Icon
                            Rectangle {
                                width: 22
                                height: 22
                                radius: 6
                                color: toastWindow.bgColor2
                                clip: true

                                Image {
                                    id: appIconImg
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    source: modelData.appIcon ? modelData.appIcon : ""
                                    fillMode: Image.PreserveAspectFit
                                    visible: status === Image.Ready && source !== ""
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: !appIconImg.visible
                                    text: "\uf0f3" // bell
                                    font { family: "Font Awesome 6 Free"; weight: Font.Bold; pixelSize: 11 }
                                    color: toastWindow.accentColor
                                }
                            }

                            // App Name
                            Text {
                                text: modelData.appName
                                font { family: "Inter"; pixelSize: 11; weight: Font.Bold }
                                color: toastWindow.accentColor
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            // Timestamp
                            Text {
                                text: modelData.timeStr
                                font { family: "Inter"; pixelSize: 10 }
                                color: "#71717A"
                            }

                            // Close Button
                            Rectangle {
                                width: 20
                                height: 20
                                radius: 10
                                color: closeMouseArea.containsMouse ? Qt.lighter(toastWindow.bgColor2, 1.5) : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "\uf00d" // times
                                    font { family: "Font Awesome 6 Free"; weight: Font.Bold; pixelSize: 10 }
                                    color: closeMouseArea.containsMouse ? "#FFFFFF" : toastWindow.fgColor
                                }

                                MouseArea {
                                    id: closeMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: toastWindow.removeToast(modelData.id)
                                }
                            }
                        }

                        // ─── Summary / Title ─────────────────────────
                        Text {
                            Layout.fillWidth: true
                            text: modelData.summary
                            font { family: "Inter"; pixelSize: 13; weight: Font.Bold }
                            color: "#FFFFFF"
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }

                        // ─── Body Text ───────────────────────────────
                        Text {
                            Layout.fillWidth: true
                            visible: modelData.body !== ""
                            text: modelData.body
                            font { family: "Inter"; pixelSize: 12 }
                            color: toastWindow.fgColor
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                        }

                        // ─── Attached Image Preview (if present) ─────
                        Image {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 120
                            visible: modelData.image !== "" && status === Image.Ready
                            source: modelData.image
                            fillMode: Image.PreserveAspectCrop
                            clip: true
                        }

                        // ─── Action Buttons ──────────────────────────
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            visible: modelData.actions && modelData.actions.length > 0

                            Repeater {
                                model: modelData.actions

                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 26
                                    radius: 13
                                    color: toastWindow.bgColor2
                                    border.color: "#2C2C30"
                                    border.width:0 

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.text
                                        font { family: "Inter"; pixelSize: 11; weight: Font.DemiBold }
                                        color: actionArea.containsMouse ? "#FFFFFF" : toastWindow.fgColor
                                        elide: Text.ElideRight
                                    }

                                    MouseArea {
                                        id: actionArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            modelData.invoke()
                                            toastWindow.removeToast(toastDelegate.modelData.id)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

