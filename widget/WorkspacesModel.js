// Pure helpers for the per-monitor Workspaces widget, kept Qt-free so tests
// can run them under node (tests/workspaces-model-test.sh). Mirrors the block model of Omarchy's
// per-monitor workspaces engine (default/hypr/monitor-workspaces.lua): each
// monitor owns a block of ten real workspaces, and the bar shows its own
// monitor's block as 1..9, 0. Without the engine's state file, monitors
// ordered left to right own the blocks (the engine's own fallback order).
//
// Modeled on vladgabrielboca/omarchy-monitor-workspaces Model.js (MIT,
// @ 3ae76b2, 2026-10-18), adapted for gdeyoung.ultrawide-bar.

var BLOCK = 10
var ALWAYS_SHOWN = 5

// `monitors` is a list of { name, x, y, mirror }. Returns the first real
// workspace id of `name`'s block, or 1 when the monitor is unknown.
function firstWorkspace(monitors, name) {
  var real = []
  for (var i = 0; i < monitors.length; i++) {
    var m = monitors[i]
    if (m && !m.mirror) real.push(m)
  }
  real.sort(function(a, b) { return a.x !== b.x ? a.x - b.x : a.y - b.y })
  for (var j = 0; j < real.length; j++) {
    if (real[j].name === name) return j * BLOCK + 1
  }
  return 1
}

// The engine's state file: one "block<TAB>connector<TAB>identity" line per
// monitor it has seen. Returns { connector: block }; malformed lines skipped.
function parseBlocks(text) {
  var blocks = {}
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length && i < 256; i++) {
    var fields = lines[i].split("\t")
    if (fields.length < 3 || fields[1] === "" || !/^[0-9]{1,3}$/.test(fields[0])) continue
    blocks[fields[1]] = parseInt(fields[0], 10)
  }
  return blocks
}

// The first real workspace of `name`'s block under the engine. Until it has
// written the state file, the workspace the monitor shows is taken to be its own.
function builtinFirst(blocks, name, activeId) {
  var block = blocks ? blocks[name] : undefined
  if (block === undefined) block = activeId > 0 ? Math.floor((activeId - 1) / BLOCK) : 0
  return block * BLOCK + 1
}

// Ids to draw: the first ALWAYS_SHOWN slots of the block, plus any other
// existing workspace inside it, then any guest workspace (on this monitor but
// from another block, as after its monitor was unplugged).
function visibleIds(first, existingIds, guestIds) {
  var ids = []
  for (var slot = 0; slot < ALWAYS_SHOWN; slot++) ids.push(first + slot)
  for (var i = 0; i < existingIds.length; i++) {
    var id = existingIds[i]
    if (id >= first && id < first + BLOCK && ids.indexOf(id) === -1) ids.push(id)
  }
  ids.sort(function(a, b) { return a - b })

  var guests = []
  var others = guestIds || []
  for (var j = 0; j < others.length; j++) {
    var guest = others[j]
    if (guest > 0 && (guest < first || guest >= first + BLOCK) && guests.indexOf(guest) === -1) guests.push(guest)
  }
  guests.sort(function(a, b) { return a - b })
  return ids.concat(guests)
}

// The label for a real id within the block starting at `first`: 1..9, then 0.
// A workspace from another block shows its slot there in parentheses.
function slotLabel(first, id) {
  var slot = id - first + 1
  if (slot >= 1 && slot <= BLOCK) return slot === 10 ? "0" : String(slot)
  var home = ((id - 1) % BLOCK) + 1
  return "(" + (home === 10 ? "0" : String(home)) + ")"
}

// Strip markup-shaped characters before text reaches a shell expression.
function plain(value) {
  return String(value === undefined || value === null ? "" : value)
    .replace(/[<>&"']/g, "")
    .slice(0, 64)
}

if (typeof module !== "undefined") module.exports = {
  BLOCK: BLOCK,
  ALWAYS_SHOWN: ALWAYS_SHOWN,
  firstWorkspace: firstWorkspace,
  parseBlocks: parseBlocks,
  builtinFirst: builtinFirst,
  visibleIds: visibleIds,
  slotLabel: slotLabel,
  plain: plain
}
