import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

PanelWindow {
    id: appLauncherWindow

    property bool isOpen: false
    signal closeRequested()
    signal openRequested()
    signal appLaunched(string appName)

    function toggle() {
        if (isOpen) closeRequested()
        else openRequested()
    }

    function open() {
        openRequested()
    }

    function close() {
        closeRequested()
    }

    // Theme properties matching Bar, ControlPanel, FullMediaPlayer, and NotificationPanel
    property color bgColor: "#121213"
    property color bgColor2: "#1E1E1E"
    property color bgColor3: "#262626"
    property color fgColor: "#B5B5B5"
    property color accentColor: "#F2E5BC"
    property color accentColorGlow: "#FFF7DA"
    property string mainFont: "Rowdies"
    property string iconFont: "JetBrains Mono"
    property int barHeight: 40

    // ─── Global Shortcut & IPC Handler ────────────────────────
    GlobalShortcut {
        name: "launcher"
        description: "Toggle Quickshell App Launcher"
        onPressed: appLauncherWindow.toggle()
    }

    IpcHandler {
        target: "launcher"
        function toggle() {
            appLauncherWindow.toggle()
        }
        function open() {
            appLauncherWindow.open()
        }
        function close() {
            appLauncherWindow.close()
        }
    }

    // ─── Applications Data & Search Model ─────────────────────
    property var allApps: []
    property string searchText: ""
    property int selectedIndex: 0

    function refreshApps() {
        let list = []
        try {
            let raw = DesktopEntries.applications.values
            for (let i = 0; i < raw.length; i++) {
                let entry = raw[i]
                if (!entry) continue
                if (entry.noDisplay) continue
                let name = entry.name ? entry.name.trim() : ""
                if (name === "") continue

                let iconStr = entry.icon ? entry.icon.trim() : ""
                let resolved = ""
                if (iconStr !== "") {
                    if (iconStr.startsWith("/")) {
                        resolved = iconStr
                    } else {
                        let path = Quickshell.iconPath(iconStr)
                        if (path && path !== "") {
                            resolved = path
                        }
                    }
                }

                list.push({
                    id: entry.id || name,
                    entry: entry,
                    name: name,
                    genericName: entry.genericName ? entry.genericName.trim() : "",
                    comment: entry.comment ? entry.comment.trim() : "",
                    icon: iconStr,
                    resolvedIcon: resolved !== "" ? (resolved.startsWith("/") ? ("file://" + resolved) : resolved) : "",
                    categories: entry.categories ? entry.categories.join(" ") : "",
                    keywords: entry.keywords ? entry.keywords.join(" ").toLowerCase() : ""
                })
            }
        } catch(e) {
            console.warn("Error refreshing DesktopEntries:", e)
        }

        list.sort((a, b) => a.name.localeCompare(b.name, undefined, { sensitivity: 'base' }))
        allApps = list
    }

    Component.onCompleted: refreshApps()

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            refreshApps()
        }
    }

    readonly property var filteredApps: {
        let q = searchText.trim().toLowerCase()
        if (q === "") return allApps
        return allApps.filter(item => {
            return item.name.toLowerCase().includes(q) ||
                   item.genericName.toLowerCase().includes(q) ||
                   item.comment.toLowerCase().includes(q) ||
                   item.keywords.includes(q)
        })
    }

    onSearchTextChanged: {
        selectedIndex = 0
        if (appList) appList.positionViewAtBeginning()
    }

    function launchItem(index) {
        if (index >= 0 && index < filteredApps.length) {
            let app = filteredApps[index]
            try {
                app.entry.execute()
            } catch(e) {
                console.error("Failed to execute app:", e)
            }
            appLaunched(app.name)
            closeRequested()
        }
    }

    onIsOpenChanged: {
        if (isOpen) {
            searchText = ""
            selectedIndex = 0
            if (searchInput) {
                searchInput.text = ""
                focusTimer.restart()
            }
        }
    }

    Timer {
        id: focusTimer
        interval: 50
        onTriggered: {
            if (searchInput) searchInput.forceActiveFocus()
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
        onClicked: appLauncherWindow.closeRequested()
    }

    // Escape key handling
    Item {
        focus: appLauncherWindow.isOpen
        Keys.onEscapePressed: appLauncherWindow.closeRequested()
    }

    // ─── THE PANEL ROOT ITEM ──────────────────────────────────
    Item {
        id: panelRootItem
        width: cardContainer.width
        height: cardContainer.height

        // Horizontally centered across the bottom bar
        x: Math.round((parent.width - width) / 2)

        // Docked seamlessly into the bottom bar, extending down to the screen edge
        y: appLauncherWindow.isOpen ? (parent.height - height) : parent.height
        opacity: appLauncherWindow.isOpen ? 1.0 : 0.0

        Behavior on y {
            NumberAnimation {
                id: slideAnim
                duration: appLauncherWindow.isOpen ? 38 : 25
                easing.type: appLauncherWindow.isOpen ? Easing.OutBack : Easing.InQuad
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: appLauncherWindow.isOpen ? 220 : 180
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
                fillColor: appLauncherWindow.bgColor
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
                fillColor: appLauncherWindow.bgColor
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
            width: 560
            height: 500 + appLauncherWindow.barHeight
            topLeftRadius: 24
            topRightRadius: 24
            bottomLeftRadius: 0
            bottomRightRadius: 0
            color: appLauncherWindow.bgColor
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
                color: appLauncherWindow.bgColor
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {} // Block clicks through to backdrop
            }

            ColumnLayout {
                anchors {
                    fill: parent
                    topMargin: 16
                    bottomMargin: 0
                    leftMargin: 16
                    rightMargin: 16
                }
                spacing: 12

                // ─── 1. Header Row (Title, Count Badge, Close) ────────
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    spacing: 8

                

                    Text {
                        text: "Applications"
                        font { family: appLauncherWindow.mainFont; pixelSize: 16 }
                        color: "#FFFFFF"
                    }

                    Rectangle {
                        implicitWidth: countText.implicitWidth + 14
                        implicitHeight: 20
                        radius: 10
                        color: appLauncherWindow.bgColor2

                        Text {
                            id: countText
                            anchors.centerIn: parent
                            text: appLauncherWindow.searchText.trim() === "" ? (appLauncherWindow.allApps.length + " apps") : (appLauncherWindow.filteredApps.length + " found")
                            font { family: "Inter"; pixelSize: 10; weight: Font.Bold }
                            color: appLauncherWindow.accentColor
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Close Button
                    Rectangle {
                        implicitWidth: 26
                        implicitHeight: 26
                        radius: 13
                        color: closeBtnArea.containsMouse ? Qt.lighter(appLauncherWindow.bgColor2, 1.4) : appLauncherWindow.bgColor2

                        Text {
                            anchors.centerIn: parent
                            text: "\uf00d" // times
                            font { family: "Font Awesome 6 Free"; weight: Font.Bold; pixelSize: 11 }
                            color: closeBtnArea.containsMouse ? "#FFFFFF" : appLauncherWindow.fgColor
                        }

                        MouseArea {
                            id: closeBtnArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: appLauncherWindow.closeRequested()
                        }
                    }
                }

                // ─── 2. Search Bar ────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46
                    radius: 14
                    color: appLauncherWindow.bgColor2
                    border.width: 1
                    border.color: searchInput.activeFocus ? appLauncherWindow.accentColor : "#2C2C30"

                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 14
                            rightMargin: 12
                        }
                        spacing: 10

                        // Magnifying glass
                        Text {
                            text: "\uf002"
                            font { family: "Font Awesome 6 Free"; weight: Font.Bold; pixelSize: 13 }
                            color: searchInput.activeFocus ? appLauncherWindow.accentColor : appLauncherWindow.fgColor
                        }

                        // Text Input
                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            font { family: "Inter"; pixelSize: 13; weight: Font.Medium }
                            color: "#FFFFFF"
                            selectionColor: appLauncherWindow.accentColor
                            selectedTextColor: appLauncherWindow.bgColor
                            clip: true
                            verticalAlignment: TextInput.AlignVCenter

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: "Type to search applications..."
                                font: parent.font
                                color: "#71717A"
                                visible: !parent.text && !parent.activeFocus
                            }

                            onTextChanged: appLauncherWindow.searchText = text

                            Keys.onDownPressed: (event) => {
                                event.accepted = true
                                if (appLauncherWindow.selectedIndex < appLauncherWindow.filteredApps.length - 1) {
                                    appLauncherWindow.selectedIndex++
                                    appList.positionViewAtIndex(appLauncherWindow.selectedIndex, ListView.Contain)
                                }
                            }

                            Keys.onUpPressed: (event) => {
                                event.accepted = true
                                if (appLauncherWindow.selectedIndex > 0) {
                                    appLauncherWindow.selectedIndex--
                                    appList.positionViewAtIndex(appLauncherWindow.selectedIndex, ListView.Contain)
                                }
                            }

                            Keys.onReturnPressed: (event) => {
                                event.accepted = true
                                appLauncherWindow.launchItem(appLauncherWindow.selectedIndex)
                            }

                            Keys.onEnterPressed: (event) => {
                                event.accepted = true
                                appLauncherWindow.launchItem(appLauncherWindow.selectedIndex)
                            }

                            Keys.onEscapePressed: (event) => {
                                event.accepted = true
                                appLauncherWindow.closeRequested()
                            }
                        }

                        // Clear Button
                        Rectangle {
                            visible: searchInput.text.length > 0
                            implicitWidth: 20
                            implicitHeight: 20
                            radius: 10
                            color: clearSearchArea.containsMouse ? Qt.lighter(appLauncherWindow.bgColor3, 1.4) : appLauncherWindow.bgColor3

                            Text {
                                anchors.centerIn: parent
                                text: "\uf00d"
                                font { family: "Font Awesome 6 Free"; weight: Font.Bold; pixelSize: 9 }
                                color: clearSearchArea.containsMouse ? "#FFFFFF" : appLauncherWindow.fgColor
                            }

                            MouseArea {
                                id: clearSearchArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    searchInput.text = ""
                                    searchInput.forceActiveFocus()
                                }
                            }
                        }
                    }
                }

                // ─── 3. Application List ──────────────────────────────
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // Empty State
                    ColumnLayout {
                        anchors.centerIn: parent
                        visible: appLauncherWindow.filteredApps.length === 0
                        spacing: 8

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "\uf002"
                            font { family: "Font Awesome 6 Free"; weight: Font.Bold; pixelSize: 34 }
                            color: Qt.rgba(1, 1, 1, 0.15)
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "No Applications Found"
                            font { family: appLauncherWindow.mainFont; pixelSize: 15 }
                            color: "#FFFFFF"
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Try a different search query"
                            font { family: "Inter"; pixelSize: 12 }
                            color: "#71717A"
                        }
                    }

                    // App ListView
                    ListView {
                        id: appList
                        anchors.fill: parent
                        clip: true
                        spacing: 4
                        visible: appLauncherWindow.filteredApps.length > 0
                        model: appLauncherWindow.filteredApps
                        currentIndex: appLauncherWindow.selectedIndex

                        delegate: Rectangle {
                            id: appItem
                            width: appList.width
                            height: 52
                            radius: 12
                            readonly property bool isSelected: index === appLauncherWindow.selectedIndex

                            color: isSelected ? appLauncherWindow.bgColor3 : (itemMouseArea.containsMouse ? Qt.lighter(appLauncherWindow.bgColor2, 1.25) : "transparent")
                            border.width: isSelected ? 1 : 0
                            border.color: isSelected ? Qt.rgba(242/255, 229/255, 188/255, 0.35) : "transparent"

                            Behavior on color { ColorAnimation { duration: 100 } }

                            RowLayout {
                                anchors {
                                    fill: parent
                                    leftMargin: 10
                                    rightMargin: 12
                                }
                                spacing: 12

                                // App Icon
                                Rectangle {
                                    width: 36
                                    height: 36
                                    radius: 10
                                    color: appLauncherWindow.bgColor2
                                    clip: true

                                    Image {
                                        id: appIconImg
                                        anchors.fill: parent
                                        anchors.margins: 4
                                        source: modelData.resolvedIcon
                                        fillMode: Image.PreserveAspectFit
                                        visible: status === Image.Ready && source !== ""
                                        mipmap: true
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        visible: !appIconImg.visible
                                        text: "\uf108" // generic desktop/app icon
                                        font { family: "Font Awesome 6 Free"; weight: Font.Bold; pixelSize: 15 }
                                        color: appLauncherWindow.accentColor
                                    }
                                }

                                // App Name & Description
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.name
                                        font {
                                            family: "Inter"
                                            pixelSize: 13
                                            weight: Font.Bold
                                        }
                                        color: isSelected ? appLauncherWindow.accentColor : "#FFFFFF"
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.genericName !== "" ? modelData.genericName : (modelData.comment !== "" ? modelData.comment : modelData.id)
                                        font { family: "Inter"; pixelSize: 11 }
                                        color: "#71717A"
                                        elide: Text.ElideRight
                                    }
                                }

                                // Action Hint (visible when selected)
                                Rectangle {
                                    visible: isSelected
                                    implicitWidth: launchHintText.implicitWidth + 12
                                    implicitHeight: 22
                                    radius: 6
                                    color: Qt.rgba(242/255, 229/255, 188/255, 0.15)

                                    Row {
                                        id: launchHintText
                                        anchors.centerIn: parent
                                        spacing: 4

                                        Text {
                                            text: "↵ Launch"
                                            font { family: "Inter"; pixelSize: 10; weight: Font.Bold }
                                            color: appLauncherWindow.accentColor
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: itemMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: appLauncherWindow.selectedIndex = index
                                onClicked: appLauncherWindow.launchItem(index)
                            }
                        }
                    }
                }

                // ─── 4. Footer Row ────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 20
                    spacing: 8

                    Text {
                        text: "↑↓ Navigate"
                        font { family: "Inter"; pixelSize: 10; weight: Font.Medium }
                        color: "#71717A"
                    }

                    Text {
                        text: "•"
                        font { family: "Inter"; pixelSize: 10 }
                        color: "#3F3F46"
                    }

                    Text {
                        text: "↵ Launch"
                        font { family: "Inter"; pixelSize: 10; weight: Font.Medium }
                        color: "#71717A"
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        implicitWidth: escText.implicitWidth + 8
                        implicitHeight: 16
                        radius: 4
                        color: appLauncherWindow.bgColor2

                        Text {
                            id: escText
                            anchors.centerIn: parent
                            text: "ESC"
                            font { family: "Inter"; pixelSize: 9; weight: Font.Bold }
                            color: "#71717A"
                        }
                    }

                    Text {
                        text: "Close"
                        font { family: "Inter"; pixelSize: 10; weight: Font.Medium }
                        color: "#71717A"
                    }
                }
            }
        }
    }
}
