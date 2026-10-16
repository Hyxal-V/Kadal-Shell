import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

PanelWindow {
    id: notificationPanelWindow

    property bool isOpen: false
    signal closeRequested()
    signal newNotification(var notif)

    // Theme properties matching Bar, ControlPanel, and FullMediaPlayer
    property color bgColor: "#121213"
    property color bgColor2: "#1E1E1E"
    property color bgColor3: "#262626"
    property color fgColor: "#B5B5B5"
    property color accentColor: "#F2E5BC"
    property color accentColorGlow: "#FFF7DA"
    property string mainFont: "Rowdies"
    property string iconFont: "JetBrains Mono"
    property int barHeight: 40

    // ─── Do Not Disturb State ─────────────────────────────────
    property bool dndEnabled: false

    function toggleDnd() {
        dndEnabled = !dndEnabled
    }

    // ─── Notification Storage & Management ────────────────────
    property var notificationList: []
    readonly property int unreadCount: notificationList.length

    function addNotification(item) {
        let copy = notificationList.slice()
        copy.unshift(item)
        notificationList = copy
    }

    function removeNotification(id) {
        let copy = []
        for (let i = 0; i < notificationList.length; i++) {
            if (notificationList[i].id === id) {
                if (notificationList[i].ref) {
                    try { notificationList[i].ref.dismiss() } catch(e) {}
                }
            } else {
                copy.push(notificationList[i])
            }
        }
        notificationList = copy
    }

    function clearAll() {
        for (let i = 0; i < notificationList.length; i++) {
            if (notificationList[i].ref) {
                try { notificationList[i].ref.dismiss() } catch(e) {}
            }
        }
        notificationList = []
    }

    // ─── Quickshell Notification Server ───────────────────────
    NotificationServer {
        id: notifServer
        keepOnReload: true
        actionsSupported: true
        imageSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        persistenceSupported: true

        onNotification: (notif) => {
            notif.tracked = true

            let actionsList = []
            if (notif.actions) {
                for (let i = 0; i < notif.actions.length; i++) {
                    let act = notif.actions[i]
                    actionsList.push({
                        identifier: act.identifier,
                        text: act.text,
                        invoke: function() { act.invoke() }
                    })
                }
            }

            let item = {
                id: notif.id,
                ref: notif,
                appName: notif.appName && notif.appName.trim() !== "" ? notif.appName : "Notification",
                appIcon: notif.appIcon || "",
                summary: notif.summary || "",
                body: notif.body || "",
                image: notif.image || "",
                timeStr: Qt.formatDateTime(new Date(), "hh:mm A"),
                timestamp: Date.now(),
                actions: actionsList
            }

            notificationPanelWindow.addNotification(item)

            if (!notificationPanelWindow.dndEnabled) {
                notificationPanelWindow.newNotification(item)
            }
        }
    }

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
        onClicked: notificationPanelWindow.closeRequested()
    }

    // Escape key handling
    Item {
        focus: notificationPanelWindow.isOpen
        Keys.onEscapePressed: notificationPanelWindow.closeRequested()
    }

    // ─── THE PANEL ROOT ITEM ──────────────────────────────────
    Item {
        id: panelRootItem
        width: cardContainer.width
        height: cardContainer.height

        // Aligned to the right side above the notification pill
        x: Math.round(notificationPanelWindow.width - width - 16)

        // Docked seamlessly into the bottom bar, extending down to the screen edge
        y: notificationPanelWindow.isOpen ? (notificationPanelWindow.height - height) : notificationPanelWindow.height
        opacity: notificationPanelWindow.isOpen ? 1.0 : 0.0

        Behavior on y {
            NumberAnimation {
                id: slideAnim
                duration: notificationPanelWindow.isOpen ? 38 : 25
                easing.type: notificationPanelWindow.isOpen ? Easing.OutBack : Easing.InQuad
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: notificationPanelWindow.isOpen ? 220 : 180
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

            ShapePath {
                strokeWidth: 0
                fillColor: notificationPanelWindow.bgColor
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

            ShapePath {
                strokeWidth: 0
                fillColor: notificationPanelWindow.bgColor
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
            width: 410
            height: 540 + notificationPanelWindow.barHeight
            topLeftRadius: 24
            topRightRadius: 24
            bottomLeftRadius: 0
            bottomRightRadius: 0
            color: notificationPanelWindow.bgColor
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

            // Cover the bottom line so the card blends completely into the bar
            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                height: 2
                color: notificationPanelWindow.bgColor
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            ColumnLayout {
                anchors {
                    fill: parent
                    topMargin: 16
                    bottomMargin: 16 + notificationPanelWindow.barHeight
                    leftMargin: 18
                    rightMargin: 18
                }
                spacing: 12

                // ─── 1. Header Row (Title, Count, DND, Clear All) ─────
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    spacing: 8

                    // Title
                    Text {
                        text: "Notifications"
                        font { family: notificationPanelWindow.mainFont; pixelSize: 17 }
                        color: "#FFFFFF"
                    }

                    // Count Badge
                    Rectangle {
                        visible: notificationPanelWindow.unreadCount > 0
                        implicitWidth: countText.implicitWidth + 14
                        implicitHeight: 20
                        radius: 10
                        color: notificationPanelWindow.bgColor2

                        Text {
                            id: countText
                            anchors.centerIn: parent
                            text: notificationPanelWindow.unreadCount
                            font { family: "Inter"; pixelSize: 11; weight: Font.Bold }
                            color: notificationPanelWindow.accentColor
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // DND Toggle Button
                    Rectangle {
                        implicitWidth: dndRow.implicitWidth + 16
                        implicitHeight: 28
                        radius: 14
                        color: notificationPanelWindow.dndEnabled ? notificationPanelWindow.accentColor : (dndMouseArea.containsMouse ? Qt.lighter(notificationPanelWindow.bgColor2, 1.4) : notificationPanelWindow.bgColor2)

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Row {
                            id: dndRow
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: notificationPanelWindow.dndEnabled ? "\uf1f6" : "\uf0f3" // bell-slash / bell
                                font { family: "Font Awesome 6 Free"; weight: Font.Bold; pixelSize: 11 }
                                color: notificationPanelWindow.dndEnabled ? notificationPanelWindow.bgColor : notificationPanelWindow.fgColor
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "DND"
                                font { family: "Inter"; pixelSize: 11; weight: Font.Bold }
                                color: notificationPanelWindow.dndEnabled ? notificationPanelWindow.bgColor : notificationPanelWindow.fgColor
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: dndMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: notificationPanelWindow.toggleDnd()
                        }
                    }

                    // Clear All Button
                    Rectangle {
                        visible: notificationPanelWindow.unreadCount > 0
                        implicitWidth: clearRow.implicitWidth + 14
                        implicitHeight: 28
                        radius: 14
                        color: clearMouseArea.containsMouse ? Qt.lighter(notificationPanelWindow.bgColor2, 1.5) : notificationPanelWindow.bgColor2

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Row {
                            id: clearRow
                            anchors.centerIn: parent
                            spacing: 5

                            Text {
                                text: "\uf1f8" // trash
                                font { family: "Font Awesome 6 Free"; weight: Font.Bold; pixelSize: 10 }
                                color: notificationPanelWindow.fgColor
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "Clear"
                                font { family: "Inter"; pixelSize: 11; weight: Font.Medium }
                                color: notificationPanelWindow.fgColor
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: clearMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: notificationPanelWindow.clearAll()
                        }
                    }
                }

                // ─── 2. GNOME-Style Date Header & Mini Calendar ───────
                Rectangle {
                    Layout.fillWidth: true
                   
                    radius: 14
                    color: notificationPanelWindow.bgColor2
                    clip: true

                    Behavior on Layout.preferredHeight {
                        NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
                    }

                    property bool calendarExpanded: false
                    property var currentDate: new Date()
                    property int viewYear: currentDate.getFullYear()
                    property int viewMonth: currentDate.getMonth()

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        // Date Header Strip
                    
                    }
                }

                // ─── 3. Notifications List ────────────────────────────
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // Empty State
                    ColumnLayout {
                        anchors.centerIn: parent
                        visible: notificationPanelWindow.unreadCount === 0
                        spacing: 8

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "\uf0f3" // bell
                            font { family: "Font Awesome 6 Free"; weight: Font.Bold; pixelSize: 38 }
                            color: Qt.rgba(1, 1, 1, 0.15)
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "No Notifications"
                            font { family: notificationPanelWindow.mainFont; pixelSize: 15 }
                            color: "#FFFFFF"
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "You're all caught up!"
                            font { family: "Inter"; pixelSize: 12 }
                            color: "#71717A"
                        }
                    }

                    // Notification List View
                    ListView {
                        id: notifListView
                        anchors.fill: parent
                        clip: true
                        spacing: 10
                        visible: notificationPanelWindow.unreadCount > 0
                        model: notificationPanelWindow.notificationList

                        delegate: Rectangle {
                            id: notifItem
                            readonly property var itemData: modelData
                            width: notifListView.width
                            height: itemContentLayout.implicitHeight + 22
                            radius: 14
                            color: notificationPanelWindow.bgColor2
                            border.width: 1
                            border.color: "#2C2C30"

                            ColumnLayout {
                                id: itemContentLayout
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top
                                    leftMargin: 12
                                    rightMargin: 12
                                    topMargin: 10
                                }
                                spacing: 5

                                // Top row: Icon, App Name, Time, Close
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    // App Icon
                                    Rectangle {
                                        width: 20
                                        height: 20
                                        radius: 6
                                        color: notificationPanelWindow.bgColor3
                                        clip: true

                                        Image {
                                            id: delegateIconImg
                                            anchors.fill: parent
                                            anchors.margins: 1
                                            source: modelData.appIcon ? modelData.appIcon : ""
                                            fillMode: Image.PreserveAspectFit
                                            visible: status === Image.Ready && source !== ""
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            visible: !delegateIconImg.visible
                                            text: "\uf0f3" // bell
                                            font { family: "Font Awesome 6 Free"; weight: Font.Bold; pixelSize: 10 }
                                            color: notificationPanelWindow.accentColor
                                        }
                                    }

                                    // App Name
                                    Text {
                                        text: modelData.appName
                                        font { family: "Inter"; pixelSize: 11; weight: Font.Bold }
                                        color: notificationPanelWindow.accentColor
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    // Time
                                    Text {
                                        text: modelData.timeStr
                                        font { family: "Inter"; pixelSize: 10 }
                                        color: "#71717A"
                                    }

                                    // Close button
                                    Rectangle {
                                        width: 18
                                        height: 18
                                        radius: 9
                                        color: delCloseArea.containsMouse ? Qt.lighter(notificationPanelWindow.bgColor3, 1.5) : "transparent"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "\uf00d" // times
                                            font { family: "Font Awesome 6 Free"; weight: Font.Bold; pixelSize: 9 }
                                            color: delCloseArea.containsMouse ? "#FFFFFF" : notificationPanelWindow.fgColor
                                        }

                                        MouseArea {
                                            id: delCloseArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: notificationPanelWindow.removeNotification(modelData.id)
                                        }
                                    }
                                }

                                // Summary / Title
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.summary
                                    font { family: "Inter"; pixelSize: 13; weight: Font.Bold }
                                    color: "#FFFFFF"
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                }

                                // Body
                                Text {
                                    Layout.fillWidth: true
                                    visible: modelData.body !== ""
                                    text: modelData.body
                                    font { family: "Inter"; pixelSize: 12 }
                                    color: notificationPanelWindow.fgColor
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 4
                                    elide: Text.ElideRight
                                }

                                // Image Attachment
                                Image {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 120
                                    visible: modelData.image !== "" && status === Image.Ready
                                    source: modelData.image
                                    fillMode: Image.PreserveAspectCrop
                                    clip: true
                                }

                                // Actions
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
                                            color: actArea.containsMouse ? Qt.lighter(notificationPanelWindow.bgColor3, 1.4) : notificationPanelWindow.bgColor3
                                            border.color: "#2C2C30"
                                            border.width: 1

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.text
                                                font { family: "Inter"; pixelSize: 11; weight: Font.DemiBold }
                                                color: actArea.containsMouse ? "#FFFFFF" : notificationPanelWindow.fgColor
                                                elide: Text.ElideRight
                                            }

                                            MouseArea {
                                                id: actArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    modelData.invoke()
                                                    notificationPanelWindow.removeNotification(notifItem.itemData.id)
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
    }
}
