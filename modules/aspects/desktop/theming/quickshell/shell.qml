// ~/.config/quickshell/theme-switcher/shell.qml
// =============================================================================
// QuickShell theme switcher UI.
//
import Quickshell
import Quickshell.Io
import QtQuick

FloatingWindow {
    id: root

    title: "Theme Switcher"

    implicitWidth: 900
    implicitHeight: 340

    // ── State ──
    property var palettes: []
    property int paletteIndex: 0
    property string mode: "dark"
    property int wallIndex: 0
    property bool initialLoad: true

    // Command queue: the latest request always wins
    property var cmdQueue: []

    Component.onCompleted: {
        loadPalettesProc.running = true
        keyHandler.forceActiveFocus()
    }

    // ── Process: list palettes ──
    Process {
        id: loadPalettesProc
        command: ["bash", "-lc", "$HOME/.config/quickshell/theme-switcher/get-palettes.sh"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.palettes = JSON.parse(this.text)
                    if (root.palettes.length > 0) {
                        getCurrentPaletteProc.running = true
                    }
                } catch (e) {
                    console.log("Failed to parse palettes:", e)
                }
            }
        }
    }

    // ── Reusable process: runs queued noctalia commands one at a time ──
    Process {
        id: getCurrentPaletteProc
        command: ["noctalia", "msg", "color-scheme-get"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var output = this.text.trim()
                // output is typically "custom <Name>"
                var name = output.startsWith("custom ") ? output.substring(7) : output
                var foundIndex = -1
                for (var i = 0; i < root.palettes.length; i++) {
                    if (root.palettes[i].name === name) {
                        foundIndex = i
                        break
                    }
                }
                root.paletteIndex = foundIndex !== -1 ? foundIndex : 0
                paletteList.positionViewAtIndex(root.paletteIndex, ListView.Center)
            }
        }
    }

    Process {
        id: cmdProc
        command: []
        running: false
        onExited: root.runNext()
    }

    function runNext() {
        if (root.cmdQueue.length === 0) return
        var next = root.cmdQueue[0]
        root.cmdQueue = root.cmdQueue.slice(1)
        cmdProc.command = next
        cmdProc.running = true
    }

    // Replace the pending queue; start immediately if idle,
    // otherwise it starts when the current command exits.
    function runCommands(cmds) {
        root.cmdQueue = cmds
        if (!cmdProc.running) root.runNext()
    }

    // ── Helpers ──
    function currentPalette() {
        return root.palettes.length > 0 ? root.palettes[root.paletteIndex] : null
    }

    function currentWallpapers() {
        var p = root.currentPalette()
        return (p && p.wallpapers) ? p.wallpapers : []
    }

    function currentWallpaperPath() {
        var walls = root.currentWallpapers()
        if (walls.length === 0) return ""
        return walls[root.wallIndex % walls.length]
    }

    function statusText() {
        var p = root.currentPalette()
        var walls = root.currentWallpapers()
        return (p ? p.name : "none") + "  ·  " + root.mode.toUpperCase()
            + "  ·  " + walls.length + " wallpaper" + (walls.length !== 1 ? "s" : "")
    }

    // ── Actions ──
    function applyTheme() {
        var p = root.currentPalette()
        if (!p) return

        var cmds = [
            ["noctalia", "msg", "color-scheme-set", "custom " + p.name],
            ["noctalia", "msg", "theme-mode-set", root.mode]
        ]

        var wp = root.currentWallpaperPath()
        if (wp) cmds.push(["noctalia", "msg", "wallpaper-set", wp])

        cmds.push(["noctalia", "msg", "templates-apply"])
        root.runCommands(cmds)
    }

    function setWallpaper() {
        var wp = root.currentWallpaperPath()
        if (!wp) return
        root.runCommands([["noctalia", "msg", "wallpaper-set", wp]])
    }

    function nextPalette() {
        if (root.palettes.length === 0) return
        root.paletteIndex = (root.paletteIndex + 1) % root.palettes.length
        root.wallIndex = 0
        root.applyTheme()
    }

    function prevPalette() {
        if (root.palettes.length === 0) return
        root.paletteIndex = (root.paletteIndex - 1 + root.palettes.length) % root.palettes.length
        root.wallIndex = 0
        root.applyTheme()
    }

    function toggleMode() {
        root.mode = root.mode === "dark" ? "light" : "dark"
        root.wallIndex = 0
        root.applyTheme()
    }

    function nextWallpaper() {
        var walls = root.currentWallpapers()
        if (walls.length === 0) return
        root.wallIndex = (root.wallIndex + 1) % walls.length
        root.setWallpaper()
    }

    function prevWallpaper() {
        var walls = root.currentWallpapers()
        if (walls.length === 0) return
        root.wallIndex = (root.wallIndex - 1 + walls.length) % walls.length
        root.setWallpaper()
    }

    // ── UI ──
    Rectangle {
        anchors.fill: parent
        color: "#1a1a26"
        border.color: "#45475a"
        border.width: 2
        radius: 16

        // Dedicated key-handling item so focus is reliable
        Item {
            id: keyHandler
            anchors.fill: parent
            focus: true

            Keys.onPressed: function(event) {
                switch (event.key) {
                case Qt.Key_Left:
                    root.prevPalette()
                    event.accepted = true
                    break
                case Qt.Key_Right:
                    root.nextPalette()
                    event.accepted = true
                    break
                case Qt.Key_Up:
                case Qt.Key_Down:
                    root.toggleMode()
                    event.accepted = true
                    break
                case Qt.Key_Tab:
                    root.nextWallpaper()
                    event.accepted = true
                    break
                case Qt.Key_Backtab:
                    root.prevWallpaper()
                    event.accepted = true
                    break
                case Qt.Key_Escape:
                    Qt.quit()
                    event.accepted = true
                    break
                }
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 20

            // Title
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Theme Switcher"
                font.pixelSize: 26
                font.bold: true
                color: "#cdd6f4"
            }

            // Palette tiles (horizontally scrollable)
            ListView {
                id: paletteList
                width: 840
                height: 150
                orientation: ListView.Horizontal
                spacing: 14
                clip: true
                interactive: true
                model: root.palettes
                currentIndex: root.paletteIndex

                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                delegate: Rectangle {
                    width: 200
                    height: 150
                    color: "transparent"
                    border.color: index === root.paletteIndex ? "#89b4fa" : "#45475a"
                    border.width: index === root.paletteIndex ? 3 : 1
                    radius: 12
                    clip: true

                    Image {
                        anchors.fill: parent
                        anchors.margins: parent.border.width
                        source: (modelData.wallpapers && modelData.wallpapers.length > 0)
                            ? modelData.wallpapers[(index === root.paletteIndex ? root.wallIndex : 0) % modelData.wallpapers.length]
                            : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        opacity: index === root.paletteIndex ? 1.0 : 0.5
                    }

                    Text {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottomMargin: 10
                        text: modelData.name
                        color: index === root.paletteIndex ? "#89b4fa" : "#cdd6f4"
                        font.pixelSize: 13
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.paletteIndex = index
                            root.wallIndex = 0
                            root.applyTheme()
                            keyHandler.forceActiveFocus()
                        }
                    }
                }
            }

            // Status bar
            Rectangle {
                width: paletteList.width
                height: 40
                color: "#2a2a3e"
                radius: 8

                Text {
                    anchors.centerIn: parent
                    text: root.statusText()
                    color: "#b4befe"
                    font.pixelSize: 13
                }
            }

            // Hint
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "←/→ palette   ↑/↓ mode   Tab/⇧Tab wallpaper   Esc to close"
                font.pixelSize: 12
                color: "#6c7086"
            }
        }
    }
}

