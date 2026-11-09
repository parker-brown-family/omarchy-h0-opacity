import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Ui
import qs.Commons

// Bar icon + popup with two sliders driving Hyprland's
// decoration:active_opacity / decoration:inactive_opacity live.
//
// Persistence: the chosen values are written inline on this widget's
// shell.json entry ({"id": "parker.window-opacity", "activeOpacity": 0.95,
// "inactiveOpacity": 0.85}) and re-applied whenever the shell starts or
// Hyprland reloads its config (which would otherwise reset them to the
// values from the Lua config).
Panel {
  id: root
  moduleName: "parker.window-opacity"

  readonly property int minPercent: 20
  readonly property int maxPercent: 100

  // Slider state in whole percent.
  property int activePercent: 100
  property int inactivePercent: 100

  // Which row the keyboard cursor is on: 0 = focused, 1 = unfocused.
  property int selectedRow: 0
  property bool cursorActive: false

  // Apply coalescing: while hyprctl is running, remember only the latest values.
  property bool applyQueued: false
  property double lastApplyMs: 0

  function clampPercent(v) {
    var n = Math.round(Number(v))
    if (isNaN(n)) n = root.maxPercent
    return Math.max(root.minPercent, Math.min(root.maxPercent, n))
  }

  function storedPercent(key) {
    var v = root.setting(key, null)
    if (v === null || v === "" || isNaN(Number(v))) return -1
    return root.clampPercent(Number(v) * 100)
  }

  function hasStoredValues() {
    return storedPercent("activeOpacity") >= 0 || storedPercent("inactiveOpacity") >= 0
  }

  function fmt(percent) {
    return (root.clampPercent(percent) / 100).toFixed(2)
  }

  function apply() {
    if (applyProc.running) {
      root.applyQueued = true
      return
    }
    root.applyQueued = false
    var a = fmt(root.activePercent)
    var i = fmt(root.inactivePercent)
    var lua = "hl.config({ decoration = { active_opacity = " + a + ", inactive_opacity = " + i + " } })"
    root.lastApplyMs = Date.now()
    // hyprctl eval is the Lua-config path; keyword is the legacy fallback.
    applyProc.command = ["bash", "-c",
      "hyprctl eval \"$1\" >/dev/null 2>&1 || hyprctl --batch \"keyword decoration:active_opacity $2; keyword decoration:inactive_opacity $3\" >/dev/null",
      "opacity", lua, a, i]
    applyProc.running = true
  }

  function persist() {
    var entry = { id: root.moduleName }
    for (var k in root.settings) if (k !== "id") entry[k] = root.settings[k]
    entry.activeOpacity = Number(fmt(root.activePercent))
    entry.inactiveOpacity = Number(fmt(root.inactivePercent))
    root.settings = entry
    if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function")
      root.bar.shell.updateEntryInline(root.moduleName, entry)
  }

  function setActive(v, save) {
    root.activePercent = clampPercent(v)
    apply()
    if (save) persist()
  }

  function setInactive(v, save) {
    root.inactivePercent = clampPercent(v)
    apply()
    if (save) persist()
  }

  function adjustSelected(delta) {
    if (root.selectedRow === 0) setActive(root.activePercent + delta, true)
    else setInactive(root.inactivePercent + delta, true)
  }

  function reset() {
    root.activePercent = root.maxPercent
    root.inactivePercent = root.maxPercent
    apply()
    persist()
  }

  // Pull persisted values into the sliders and push them to Hyprland. With no
  // persisted values, mirror whatever Hyprland currently uses instead.
  function syncFromSettings() {
    if (!hasStoredValues()) {
      if (!readProc.running) readProc.running = true
      return
    }
    var a = storedPercent("activeOpacity")
    var i = storedPercent("inactiveOpacity")
    if (a >= 0) root.activePercent = a
    if (i >= 0) root.inactivePercent = i
    apply()
  }

  onSettingsChanged: syncFromSettings()
  Component.onCompleted: syncFromSettings()

  onOpenedChanged: if (opened) { selectedRow = 0; cursorActive = false }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  // A `hyprctl reload` (Omarchy toggles, saving a hypr/*.lua file) resets
  // decoration opacity to the Lua config; put the user's values back. The
  // time guard keeps our own change from re-triggering itself.
  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (!event || String(event.name) !== "configreloaded") return
      if (!root.hasStoredValues()) return
      if (Date.now() - root.lastApplyMs < 1000) return
      reapplyDelay.restart()
    }
  }

  Timer {
    id: reapplyDelay
    interval: 250
    repeat: false
    onTriggered: root.apply()
  }

  Process {
    id: applyProc
    stdout: StdioCollector { waitForEnd: true }
    onRunningChanged: if (!running && root.applyQueued) root.apply()
  }

  Process {
    id: readProc
    command: ["bash", "-c",
      "hyprctl -j getoption decoration:active_opacity 2>/dev/null | tr -d '\\n'; echo; hyprctl -j getoption decoration:inactive_opacity 2>/dev/null | tr -d '\\n'; echo"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var lines = String(text || "").split("\n")
        function parse(line) {
          try {
            var o = JSON.parse(line)
            var v = o.float !== undefined ? o.float : (o.value !== undefined ? o.value : o.data)
            v = Number(v)
            return isNaN(v) ? -1 : root.clampPercent(v * 100)
          } catch (e) {
            return -1
          }
        }
        var a = parse(lines[0] || "")
        var i = parse(lines[1] || "")
        if (a >= 0) root.activePercent = a
        if (i >= 0) root.inactivePercent = i
      }
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰗋"
    onPressed: function(b) { root.toggle() }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: Style.space(320)
    contentHeight: panelColumn.implicitHeight

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onMoveRequested: function(dx, dy) {
        if (!root.cursorActive) { root.cursorActive = true; return }
        if (dy !== 0) root.selectedRow = dy > 0 ? 1 : 0
        else if (dx !== 0) root.adjustSelected(dx * 5)
      }
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: panelColumn
        width: parent.width
        spacing: Style.space(14)

        Item {
          width: parent.width
          implicitHeight: Math.max(titleText.implicitHeight, resetButton.implicitHeight)

          Text {
            id: titleText
            text: "Window Opacity"
            color: root.bar ? root.bar.foreground : Color.foreground
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.title
            font.bold: true
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }

          Button {
            id: resetButton
            text: "Reset"
            fontSize: Style.font.caption
            foreground: root.bar ? root.bar.foreground : Color.foreground
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
            horizontalPadding: Style.spacing.sm
            verticalPadding: Style.spacing.controlPaddingY
            bordered: true
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            onClicked: root.reset()
          }
        }

        PanelSeparator {
          foreground: root.bar ? root.bar.foreground : Color.foreground
        }

        OpacityRow {
          width: parent.width
          label: "FOCUSED"
          rowIndex: 0
          percent: root.activePercent
          onMovedTo: function(v) { root.setActive(v, false) }
          onReleasedAt: function(v) { root.setActive(v, true) }
        }

        OpacityRow {
          width: parent.width
          label: "UNFOCUSED"
          rowIndex: 1
          percent: root.inactivePercent
          onMovedTo: function(v) { root.setInactive(v, false) }
          onReleasedAt: function(v) { root.setInactive(v, true) }
        }
      }
    }
  }

  component OpacityRow: Column {
    id: row
    required property string label
    required property int rowIndex
    required property int percent
    signal movedTo(real value)
    signal releasedAt(real value)

    spacing: Style.space(6)

    Item {
      width: parent.width
      implicitHeight: Math.max(header.implicitHeight, valueText.implicitHeight)

      PanelSectionHeader {
        id: header
        text: row.label
        foreground: root.bar ? root.bar.foreground : Color.foreground
        fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        id: valueText
        textFormat: Text.PlainText
        text: Math.round(slider.dragging ? slider.liveValue : row.percent) + "%"
        color: Qt.darker(root.bar ? root.bar.foreground : Color.foreground, 1.4)
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
        font.bold: true
        anchors.right: parent.right
        anchors.rightMargin: Style.space(6)
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    CursorSurface {
      width: parent.width
      height: slider.implicitHeight + Style.spacing.controlGap
      hasCursor: root.cursorActive && root.selectedRow === row.rowIndex
      foreground: root.bar ? root.bar.foreground : Color.foreground
      outline: true

      PanelSlider {
        id: slider
        bar: root.bar
        anchors.fill: parent
        anchors.leftMargin: Style.space(6)
        anchors.rightMargin: Style.space(6)
        minimum: root.minPercent
        maximum: root.maxPercent
        step: 5
        integer: true
        value: row.percent
        onMoved: function(v) { row.movedTo(v) }
        onReleased: function(v) { row.releasedAt(v) }
      }

      HoverHandler {
        onHoveredChanged: if (hovered) {
          root.cursorActive = true
          root.selectedRow = row.rowIndex
        }
      }
    }
  }
}
