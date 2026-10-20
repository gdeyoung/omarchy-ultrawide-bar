import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import qs.Ui
import "WorkspacesModel.js" as Model

// Per-monitor workspaces: each monitor owns a block of ten real workspaces
// (Omarchy per-monitor engine — default/hypr/monitor-workspaces.lua, backported
// on 4.0.4 by this plugin's hypr/ hook; the platform ships it from its next
// release). One bar per screen: every bar resolves the Hyprland monitor it
// lives on and shows that monitor's block as 1..9, 0. A workspace stranded on
// this monitor from another block (after an unplug) shows as (n). The active
// number lights only on the monitor that has focus, so SUPER+1..0 lands on the
// bar whose number is lit.
BarWidget {
  id: root
  moduleName: "gdeyoung.workspaces"

  readonly property var window: root.QsWindow.window
  // Re-resolved whenever Hyprland's monitor list changes: a bar that spawns
  // while its output is still being registered (dock hotplug) resolves
  // monitorFor() against a stale list and the binding would otherwise never
  // re-fire — window.screen does not change under it.
  property int monitorGeneration: 0
  readonly property var monitor: {
    root.monitorGeneration
    return root.window && root.window.screen ? Hyprland.monitorFor(root.window.screen) : null
  }
  readonly property string monitorName: monitor ? monitor.name : ""
  readonly property bool monitorFocused: monitor !== null && Hyprland.focusedMonitor === monitor
  readonly property int activeId: monitor && monitor.activeWorkspace ? monitor.activeWorkspace.id : -1

  // The engine's block assignment: ~/.local/state/omarchy/monitor-workspaces,
  // one "block<TAB>connector<TAB>identity" line per monitor it has seen. The
  // bar maps its own connector to a block from this, exactly as the engine
  // docs describe. Without it (engine absent), monitors ordered left to right
  // own the blocks — the engine's own fallback order.
  property var blocks: ({})

  FileView {
    path: Quickshell.env("HOME") + "/.local/state/omarchy/monitor-workspaces"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.blocks = Model.parseBlocks(text())
    onLoadFailed: root.blocks = ({})
  }

  readonly property bool engineBlocks: root.blocks[root.monitorName] !== undefined

  readonly property int first: {
    if (root.engineBlocks) return Model.builtinFirst(root.blocks, root.monitorName, root.activeId)
    var monitors = []
    var values = Hyprland.monitors.values
    for (var i = 0; i < values.length; i++) {
      var ipc = values[i].lastIpcObject || {}
      monitors.push({
        name: values[i].name,
        x: values[i].x,
        y: values[i].y,
        mirror: ipc.mirrorOf !== undefined && ipc.mirrorOf !== "none"
      })
    }
    return Model.firstWorkspace(monitors, root.monitorName)
  }

  readonly property var ids: {
    var existing = []
    var guests = []
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      existing.push(values[i].id)
      if (root.monitor && values[i].monitor === root.monitor) guests.push(values[i].id)
    }
    return Model.visibleIds(root.first, existing, guests)
  }

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }

    return null
  }

  function focusWorkspace(id) {
    if (!root.bar) return
    var slot = id - root.first + 1
    // The engine's focus action also pulls a workspace of this monitor's
    // block back from wherever it wandered. Guests fall back to a raw focus.
    var expression = root.engineBlocks && slot >= 1 && slot <= Model.BLOCK
      ? "o.workspaces.focus(" + slot + ", \"" + Model.plain(root.monitorName) + "\")"
      : "hl.dsp.focus({ workspace = \"" + id + "\" })"
    root.bar.run("hyprctl dispatch " + Util.shellQuote(expression))
  }

  // Monitor positions come from Hyprland's monitor list, which Quickshell only
  // refreshes on request; a layout change or hotplug asks for it again. The
  // engine renumbers workspaces on unplug, so those ask Hyprland too.
  Component.onCompleted: {
    Hyprland.refreshMonitors()
    root.monitorGeneration++
  }

  // Re-resolve shortly after the list settles, too: refreshMonitors() asks
  // Hyprland, and the answer can land after the immediate generation bump.
  Timer {
    id: resettler
    interval: 1000
    repeat: false
    running: false
    onTriggered: root.monitorGeneration++
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      var name = event ? String(event.name) : ""
      if (name === "configreloaded" || name === "monitoraddedv2" || name === "monitorremovedv2") {
        Hyprland.refreshMonitors()
        root.monitorGeneration++
        resettler.restart()
      } else if (name === "moveworkspacev2" || name === "changeworkspaceid") {
        Hyprland.refreshMonitors()
        Hyprland.refreshWorkspaces()
        root.monitorGeneration++
      }
    }
  }

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : root.ids.length
    columnSpacing: root.vertical ? 0 : Style.space(1)
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      model: root.ids

      WidgetButton {
        required property int modelData

        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.monitor === root.monitor
          && workspace.toplevels.values.length > 0
        readonly property bool shown: root.activeId === modelData

        bar: root.bar
        text: shown && root.monitorFocused ? "\uDB85\uDCFB" : Model.slotLabel(root.first, modelData)
        // Lit only while this monitor has focus, so SUPER + 1..0 lands on the
        // bar whose number is lit.
        active: shown && root.monitorFocused
        opacity: shown || occupied ? 1 : 0.5
        horizontalMargin: 6
        verticalPadding: 6
        fixedWidth: root.vertical ? root.barSize : Style.space(20)
        fixedHeight: root.barSize
        onPressed: function() { root.focusWorkspace(modelData) }
      }
    }
  }
}
